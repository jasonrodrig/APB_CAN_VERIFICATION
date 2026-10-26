#!/usr/bin/env python3
"""
gen_ral.py - generate UVM RAL code (uvm_reg classes + uvm_reg_block) from the
CAN 2.0B register workbook (CAN_2.0B_Register_Map.xlsx).

Reads
    sheet "Register Map"  : Offset, Register, Access, Group, Description
    sheet "Fields"        : Offset, Register, Field, MSB, LSB, Access, Reset,
                            Reset value (decimal), Reserved?, Description

Writes (into --out, default ./ral)
    <prefix>_reg_<name>.sv  one uvm_reg subclass per register, one file each (include-guarded)
    <prefix>_reg_block.sv   uvm_reg_block holding every register and the address map
    <prefix>_reg_pkg.sv     package: offset constants, then the register files, then the block
  With --single-file the register classes go into one <prefix>_regs.sv instead.
  The extension is .sv by default (--ext .svh to change it). Only <prefix>_reg_pkg.sv belongs in
  the compile file list; the other files are pulled in by the package's `include (+incdir the folder).

Usage
    python3 gen_ral.py                              # defaults
    python3 gen_ral.py --xlsx map.xlsx --out ral --prefix can --verify
    python3 gen_ral.py --no-reserved --style upper
    python3 gen_ral.py --single-file                # all register classes in one file

Generation rules (all stated again in the header of every generated file)
    * Field access strings come straight from the workbook: RW, RO, WO.
    * volatile = 1 for hardware-updated RO fields (status, counters, RX head
      registers) and for self-clearing write-only command bits; 0 for VERSION,
      reserved fields and RW configuration fields.
    * is_rand = 1 for RW fields only (WO command bits are never randomized, so
      randomize()+update() cannot fire TX_START / RX_POP by accident).
    * the `rand` keyword is written only on handles that can be randomized: RW fields, and
      registers that contain at least one. RO / WO / reserved fields and RO / WO registers get
      plain handles. --rand-all writes `rand` on every handle (ralgen style); behaviour is the
      same either way because configure() already disables randomization when is_rand = 0.
    * individually_accessible = 1 only when every byte lane the field touches
      holds no other field of that register.
    * Reserved fields are emitted as RO fields named "reserved" (reads-as-0 is
      then checked by the built-in register tests); use --no-reserved to omit.
    * Bits that the spec table does not list at all get no field.
"""
import argparse
import os
import re
import sys

try:
    from openpyxl import load_workbook
except ImportError:                                            # pragma: no cover
    sys.exit('openpyxl is required: pip install openpyxl')

# --------------------------------------------------------------------------------------
# identifiers that must not be used as field / register handle names inside a uvm_reg or
# uvm_reg_block subclass (they would shadow or clash with inherited methods / keywords)
CLASH = {
    'get', 'set', 'read', 'write', 'mirror', 'update', 'reset', 'predict', 'poke', 'peek',
    'configure', 'build', 'print', 'copy', 'clone', 'compare', 'pack', 'unpack', 'record',
    'new', 'randomize', 'lock_model', 'sample', 'default_map',
    # a few SystemVerilog keywords a spec might plausibly use as a name
    'bit', 'byte', 'int', 'input', 'output', 'reg', 'wire', 'logic', 'class', 'type', 'end',
    'begin', 'task', 'function', 'module', 'string', 'event', 'rand', 'static', 'local',
}
ACCESS_OK = {'RW', 'RO', 'WO' , 'W1C'}
EXT = '.sv'            # extension of the generated register / block files (set from --ext)
RAND_ALL = False       # --rand-all: put `rand` on every handle instead of only the randomizable ones


def block_file_name(prefix):
    return f'{prefix}_reg_block{EXT}'


def regs_file_name(prefix):
    return f'{prefix}_regs{EXT}'


def guard_name(cname):
    return f'{cname.upper()}_{EXT.lstrip(".").upper()}'


class GenError(Exception):
    pass


# --------------------------------------------------------------------------------------
# model
class Field:
    def __init__(self, name, msb, lsb, access, reset_txt, reset_val, reserved, desc):
        self.name, self.msb, self.lsb, self.access = name, msb, lsb, access
        self.reset_txt, self.reset_val, self.reserved, self.desc = reset_txt, reset_val, reserved, desc

    @property
    def size(self):
        return self.msb - self.lsb + 1

    @property
    def has_reset(self):
        return self.reset_txt.strip() not in ('-', '', 'None')


class Reg:
    def __init__(self, offset, name, access, group, desc):
        self.offset, self.name, self.access, self.group, self.desc = offset, name, access, group, desc
        self.fields = []


def _hdr_index(ws, row, wanted):
    """Map wanted header names (several accepted spellings each) to column numbers."""
    cells = {str(c.value).strip(): c.column for c in ws[row] if c.value is not None}
    out = {}
    for key, spellings in wanted.items():
        for s in spellings:
            if s in cells:
                out[key] = cells[s]
                break
        else:
            raise GenError(f"sheet '{ws.title}': missing column {spellings[0]!r} (found: {sorted(cells)})")
    return out


def _to_int(v, what):
    if v is None or str(v).strip() == '':
        raise GenError(f'{what}: empty value')
    s = str(v).strip().replace('_', '')
    try:
        return int(s, 16) if s.lower().startswith('0x') else int(float(s))
    except ValueError:
        raise GenError(f'{what}: cannot read {v!r} as a number')


def load_model(path):
    # data_only so formula cells (Width etc.) give their cached values; we only need constants
    wb = load_workbook(path, data_only=True)
    for need in ('Register Map', 'Fields'):
        if need not in wb.sheetnames:
            raise GenError(f"workbook has no sheet named {need!r} (sheets: {wb.sheetnames})")
    # ---- Register Map: find header row
    wm = wb['Register Map']
    hrow = next((r for r in range(1, 30) if str(wm.cell(r, 1).value).strip() == 'Offset'), None)
    if hrow is None:
        raise GenError("sheet 'Register Map': header row (first cell 'Offset') not found")
    cm = _hdr_index(wm, hrow, {'offset': ['Offset'], 'name': ['Register'], 'access': ['Access'],
                               'group': ['Group'], 'desc': ['Description']})
    regs, by_off = [], {}
    r = hrow + 1
    while wm.cell(r, cm['offset']).value not in (None, ''):
        off = _to_int(wm.cell(r, cm['offset']).value, f"Register Map row {r} offset")
        name = str(wm.cell(r, cm['name']).value).strip()
        acc = str(wm.cell(r, cm['access']).value).strip()
        if acc not in ACCESS_OK:
            raise GenError(f"register {name}: access {acc!r} not one of {sorted(ACCESS_OK)}")
        if off in by_off:
            raise GenError(f"duplicate offset 0x{off:03X} ({by_off[off].name} and {name})")
        if off % 4:
            raise GenError(f"register {name}: offset 0x{off:X} is not word aligned")
        reg = Reg(off, name, acc, str(wm.cell(r, cm['group']).value or '').strip(), str(wm.cell(r, cm['desc']).value or '').strip())
        regs.append(reg); by_off[off] = reg
        r += 1
    if not regs:
        raise GenError("sheet 'Register Map': no registers found")
    # ---- Fields
    wf = wb['Fields']
    cf = _hdr_index(wf, 1, {'offset': ['Offset'], 'reg': ['Register'], 'name': ['Field'], 'msb': ['MSB'], 'lsb': ['LSB'],
                            'access': ['Access'], 'reset_txt': ['Reset'],
                            'reset_val': ['Reset value (decimal)', 'Reset value'], 'resv': ['Reserved?'],
                            'desc': ['Description']})
    r = 2
    while wf.cell(r, cf['offset']).value not in (None, ''):
        off = _to_int(wf.cell(r, cf['offset']).value, f'Fields row {r} offset')
        if off not in by_off:
            raise GenError(f"Fields row {r}: offset 0x{off:03X} is not in the Register Map sheet")
        reg = by_off[off]
        if str(wf.cell(r, cf['reg']).value).strip() != reg.name:
            raise GenError(f"Fields row {r}: register name {wf.cell(r, cf['reg']).value!r} does not match Register Map ({reg.name})")
        msb, lsb = _to_int(wf.cell(r, cf['msb']).value, f'Fields row {r} MSB'), _to_int(wf.cell(r, cf['lsb']).value, f'Fields row {r} LSB')
        acc = str(wf.cell(r, cf['access']).value).strip()
        if acc not in ACCESS_OK:
            raise GenError(f"Fields row {r} ({reg.name}): access {acc!r} not one of {sorted(ACCESS_OK)}")
        rtxt = str(wf.cell(r, cf['reset_txt']).value).strip()
        rval = _to_int(wf.cell(r, cf['reset_val']).value, f'Fields row {r} reset value')
        resv = str(wf.cell(r, cf['resv']).value).strip().lower() == 'yes'
        reg.fields.append(Field(str(wf.cell(r, cf['name']).value).strip(), msb, lsb, acc, rtxt, rval, resv,
                                str(wf.cell(r, cf['desc']).value or '').strip()))
        r += 1
    validate(regs)
    return regs


def validate(regs):
    for reg in regs:
        if not reg.fields:
            raise GenError(f'register {reg.name}: no fields in the Fields sheet')
        used = {}
        for f in reg.fields:
            if not (0 <= f.lsb <= f.msb <= 31):
                raise GenError(f'{reg.name}.{f.name}: bad bit range [{f.msb}:{f.lsb}]')
            if f.reset_val >> f.size:
                raise GenError(f'{reg.name}.{f.name}: reset value 0x{f.reset_val:X} does not fit in {f.size} bit(s)')
            for b in range(f.lsb, f.msb + 1):
                if b in used:
                    raise GenError(f'{reg.name}: bit {b} is in both {used[b]} and {f.name}')
                used[b] = f.name
        names = [f.name for f in reg.fields if not f.reserved]
        if len(names) != len(set(names)):
            raise GenError(f'{reg.name}: duplicate field names {sorted(n for n in names if names.count(n) > 1)}')
    if len({r.name for r in regs}) != len(regs):
        raise GenError('duplicate register names in the Register Map sheet')


# --------------------------------------------------------------------------------------
# naming
class Namer:
    def __init__(self, style):
        self.style, self.renames = style, []

    def ident(self, raw, where=''):
        s = re.sub(r'[^0-9A-Za-z_]+', '_', raw).strip('_')
        s = re.sub(r'_+', '_', s) or 'x'
        if s[0].isdigit():
            s = 'f_' + s
        s = s.lower() if self.style == 'lower' else s.upper() if self.style == 'upper' else s
        if s.lower() in CLASH:
            new = s + '_'
            self.renames.append(f'{where}{raw!r}: handle {s!r} clashes with an inherited name/keyword, emitted as {new!r}')
            s = new
        return s


def first_sentence(text, limit=110):
    """First sentence of a description (split on '. ' only, so ':' and ';' stay inside), shortened to `limit`."""
    t = re.sub(r'\s+', ' ', text).strip()
    m = re.match(r'(.+?\.)(\s|$)', t)
    t = m.group(1) if m else t
    return t if len(t) <= limit else t[:limit - 3].rstrip() + '...'


def sv_hex(width, val):
    return f"{width}'h{val:0{(width + 3) // 4}X}"


# --------------------------------------------------------------------------------------
# per-field attribute rules
def is_volatile(reg, f):
    if f.reserved:
        return 0
    if reg.name == 'VERSION':
        return 0
    return 1 if f.access in ('RO', 'WO') else 0     # RO: hardware updated; WO: self-clearing command bit


def is_rand(reg, f):
    return 1 if (f.access == 'RW' and not f.reserved) else 0


def field_rand_kw(reg, f):
    return 'rand ' if (RAND_ALL or is_rand(reg, f)) else ''


def reg_rand_kw(reg):
    return 'rand ' if (RAND_ALL or any(is_rand(reg, f) for f in reg.fields)) else ''


def individually_accessible(reg, f):
    lanes = set(range(f.lsb // 8, f.msb // 8 + 1))
    for g in reg.fields:                            # all spec fields count, reserved ones included
        if g is f:
            continue
        if lanes & set(range(g.lsb // 8, g.msb // 8 + 1)):
            return 0
    return 1


# --------------------------------------------------------------------------------------
# emit
BANNER = """\
//------------------------------------------------------------------------------
// {title}
// AUTO-GENERATED by gen_ral.py from {src}  --  DO NOT EDIT BY HAND.
// Regenerate after changing the workbook.
//------------------------------------------------------------------------------"""

RULES = """\
// Generation rules:
//   volatile : 1 for hardware-updated RO fields and self-clearing WO command bits
//              (0 for VERSION, reserved fields and RW configuration fields)
//   is_rand  : 1 for RW fields only (WO command bits are never randomized)
//   rand     : keyword only on RW field handles / registers that contain one (--rand-all: everywhere)
//   indiv.   : 1 only if no other field of the register shares a byte lane
//   reserved : emitted as RO field "reserved" (reads as 0) unless --no-reserved
"""


def class_name(prefix, reg, namer):
    return namer.ident(f'{prefix}_reg_{reg.name}')


def gen_reg_class(prefix, reg, namer, include_reserved):
    cname = class_name(prefix, reg, namer)
    flds = [f for f in reg.fields if include_reserved or not f.reserved]
    flds_sorted = sorted(flds, key=lambda f: f.lsb)
    hand = {}
    for f in flds_sorted:
        hand[id(f)] = 'reserved' if f.reserved else namer.ident(f.name, f'{reg.name}.')
    lines = []
    lines.append('//------------------------------------------------------------------------------')
    lines.append(f'// {reg.name}   offset 0x{reg.offset:03X}   access {reg.access}')
    if reg.desc:
        lines.append(f'// {reg.desc}')
    lines.append('//------------------------------------------------------------------------------')
    lines.append(f'class {cname} extends uvm_reg;')
    lines.append(f'  `uvm_object_utils({cname})')
    lines.append('')
    for f in flds_sorted:
        rng = f'[{f.msb}:{f.lsb}]' if f.msb != f.lsb else f'[{f.lsb}]'
        note = first_sentence(f.desc) if f.desc else ''
        lines.append(f'  {field_rand_kw(reg, f)}uvm_reg_field {hand[id(f)]};  // {rng} {f.access}' + (f': {note}' if note else ''))
    lines.append('')
    lines.append(f'  function new(string name = "{cname}");')
    lines.append('    super.new(name, 32, UVM_NO_COVERAGE);')
    lines.append('  endfunction')
    lines.append('')
    lines.append('  virtual function void build();')
    for f in flds_sorted:
        h = hand[id(f)]
        rv = sv_hex(f.size, f.reset_val if f.has_reset else 0)
        lines.append(f'    {h} = uvm_reg_field::type_id::create("{h}");')
        lines.append(f'    {h}.configure(this, {f.size}, {f.lsb}, "{f.access}", {is_volatile(reg, f)}, {rv}, '
                     f'{1 if f.has_reset else 0}, {is_rand(reg, f)}, {individually_accessible(reg, f)});')
    lines.append('  endfunction')
    lines.append('endclass')
    return '\n'.join(lines), cname


def gen_regs_single_file(prefix, regs, namer, include_reserved, src):
    out = [BANNER.format(title=f'{prefix.upper()} register classes (one uvm_reg per register)', src=src), RULES.rstrip('\n'), '']
    names = {}
    for reg in regs:
        txt, cname = gen_reg_class(prefix, reg, namer, include_reserved)
        names[reg.name] = cname
        out.append(txt)
        out.append('')
    return '\n'.join(out), names


def reg_file_name(prefix, reg, namer):
    return class_name(prefix, reg, namer) + EXT


def gen_reg_files(prefix, regs, namer, include_reserved, src):
    """One include-guarded file per register class: [(file name, text, class name)]."""
    out = []
    for reg in regs:
        txt, cname = gen_reg_class(prefix, reg, namer, include_reserved)
        guard = guard_name(cname)
        head = BANNER.format(title=f'{reg.name} register class ({cname})', src=src)
        text = '\n'.join([head, f'// Field attribute rules are listed in {prefix}_reg_pkg.sv.', f'`ifndef {guard}', f'`define {guard}', '',
                          txt, '', f'`endif  // {guard}', ''])
        out.append((reg_file_name(prefix, reg, namer), text, cname))
    return out


def addr_const(prefix, reg, namer):
    """Name of the offset constant for a register, defined in <prefix>_reg_pkg."""
    return f'{prefix.upper()}_ADDR_{namer.ident(reg.name).upper()}'


def gen_block_file(prefix, block, regs, cnames, namer, bus_bytes, src):
    handles = {reg.name: namer.ident(reg.name, 'block: ') for reg in regs}
    out = [BANNER.format(title=f'{block}: register block and address map', src=src),
           f'// Register offsets come from {prefix}_reg_pkg ({prefix.upper()}_ADDR_*); this file is included by that package.', '']
    out.append(f'class {block} extends uvm_reg_block;')
    out.append(f'  `uvm_object_utils({block})')
    out.append('')
    group = None
    for reg in regs:
        if reg.group != group:
            group = reg.group
            out.append(f'  // ---- {group}')
        out.append(f'  {reg_rand_kw(reg)}{cnames[reg.name]} {handles[reg.name]};  // 0x{reg.offset:03X} {reg.access}')
    out.append('')
    out.append(f'  function new(string name = "{block}");')
    out.append('    super.new(name, UVM_NO_COVERAGE);')
    out.append('  endfunction')
    out.append('')
    out.append('  virtual function void build();')
    out.append(f'    // PADDR is a byte address; registers are {bus_bytes * 8}-bit, word aligned (byte_addressing = 1).')
    out.append(f'    default_map = create_map("default_map", \'h0, {bus_bytes}, UVM_LITTLE_ENDIAN);')
    group = None
    for reg in regs:
        h = handles[reg.name]
        out.append('')
        if reg.group != group:
            group = reg.group
            out.append(f'    // ---- {group}')
        out.append(f'    {h} = {cnames[reg.name]}::type_id::create("{h}");')
        out.append(f'    {h}.configure(this, null, "");')
        out.append(f'    {h}.build();')
        out.append(f'    default_map.add_reg({h}, {addr_const(prefix, reg, namer)}, "{reg.access}");  // 0x{reg.offset:03X}')
    out.append('')
    out.append('    lock_model();')
    out.append('  endfunction')
    out.append('endclass')
    return '\n'.join(out) + '\n', handles


def gen_pkg_file(prefix, block, regs, namer, addr_width, src, reg_includes):
    out = [BANNER.format(title=f'{prefix}_reg_pkg: RAL package', src=src), RULES.rstrip('\n'), '']
    out.append(f'package {prefix}_reg_pkg;')
    out.append('  import uvm_pkg::*;')
    out.append('  `include "uvm_macros.svh"')
    out.append('')
    out.append(f'  localparam int unsigned {prefix.upper()}_REG_ADDR_WIDTH = {addr_width};')
    out.append('')
    out.append('  // register byte offsets')
    for reg in regs:
        out.append(f"  localparam bit [{addr_width - 1}:0] {addr_const(prefix, reg, namer)} = {addr_width}'h{reg.offset:03X};  // {reg.access}")
    out.append('')
    out.append('  // register classes')
    for fn in reg_includes:
        out.append(f'  `include "{fn}"')
    out.append('')
    out.append('  // register block (uses the offset constants above)')
    out.append(f'  `include "{block_file_name(prefix)}"')
    out.append('endpackage')
    return '\n'.join(out) + '\n'


# --------------------------------------------------------------------------------------
# verification: re-parse what was written and compare with the workbook model
def verify(outdir, prefix, block, regs, namer, include_reserved, per_file=True):
    errs = []
    btxt = open(os.path.join(outdir, block_file_name(prefix))).read()
    classes = {}
    if per_file:
        for reg in regs:
            fn = reg_file_name(prefix, reg, namer)
            path = os.path.join(outdir, fn)
            if not os.path.exists(path):
                errs.append(f'{fn} missing'); continue
            t = open(path).read()
            found = re.findall(r'class (\w+) extends uvm_reg;(.*?)endclass', t, re.S)
            if len(found) != 1:
                errs.append(f'{fn}: {len(found)} register classes, expected exactly 1'); continue
            if found[0][0] != class_name(prefix, reg, namer):
                errs.append(f'{fn}: contains class {found[0][0]}, expected {class_name(prefix, reg, namer)}')
            guard = guard_name(class_name(prefix, reg, namer))
            if f'`ifndef {guard}' not in t or f'`define {guard}' not in t or '`endif' not in t:
                errs.append(f'{fn}: include guard {guard} missing')
            classes[found[0][0]] = found[0][1]
    else:
        rtxt = open(os.path.join(outdir, regs_file_name(prefix))).read()
        classes = {m[0]: m[1] for m in re.findall(r'class (\w+) extends uvm_reg;(.*?)endclass', rtxt, re.S)}
    if len(classes) != len(regs):
        errs.append(f'{len(classes)} register classes found, expected {len(regs)}')
    ptxt = open(os.path.join(outdir, f'{prefix}_reg_pkg.sv')).read()
    expect_inc = ['uvm_macros.svh'] + ([reg_file_name(prefix, r, namer) for r in regs] if per_file else [regs_file_name(prefix)]) + [block_file_name(prefix)]
    got_inc = re.findall(r'`include "([^"]+)"', ptxt)
    if got_inc != expect_inc:
        errs.append(f'package includes {got_inc} != expected {expect_inc}')
    consts = {m[0]: int(m[1], 16) for m in re.findall(r"localparam bit \[\d+:0\] (\w+) = \d+'h([0-9A-Fa-f]+);", ptxt)}
    adds = re.findall(r"(\w+)\.configure\(this, null, \"\"\);\s+\w+\.build\(\);\s+default_map\.add_reg\(\1, (\w+), \"(\w+)\"\);", btxt)
    addmap = {a[0]: (a[1], a[2]) for a in adds}
    if re.search(r"add_reg\(\w+, 'h", btxt):
        errs.append("block still contains a literal offset in add_reg()")
    for reg in regs:
        cn = class_name(prefix, reg, namer)
        body = classes.get(cn)
        if body is None:
            errs.append(f'class {cn} missing'); continue
        cfg = re.findall(r'(\w+)\.configure\(this, (\d+), (\d+), "(\w+)", (\d), (\d+)\'h([0-9A-F]+), (\d), (\d), (\d)\);', body)
        want = sorted([f for f in reg.fields if include_reserved or not f.reserved], key=lambda f: f.lsb)
        if len(cfg) != len(want):
            errs.append(f'{reg.name}: {len(cfg)} configure() calls, expected {len(want)}'); continue
        if 'super.new(name, 32, UVM_NO_COVERAGE);' not in body:
            errs.append(f'{reg.name}: constructor not 32-bit')
        for c, f in zip(cfg, want):
            _, size, lsb, acc, vol, rw, rv, hasr, rnd, ind = c
            exp = (f.size, f.lsb, f.access, is_volatile(reg, f), int(rw), f.reset_val if f.has_reset else 0,
                   1 if f.has_reset else 0, is_rand(reg, f), individually_accessible(reg, f))
            got = (int(size), int(lsb), acc, int(vol), int(rw), int(rv, 16), int(hasr), int(rnd), int(ind))
            if got != exp:
                errs.append(f'{reg.name}.{f.name}: generated {got} != workbook {exp}')
        decl = {m[1]: bool(m[0]) for m in re.findall(r'^\s*(rand\s+)?uvm_reg_field\s+(\w+);', body, re.M)}
        for c, f in zip(cfg, want):
            exp_rand = bool(RAND_ALL or is_rand(reg, f))
            if decl.get(c[0]) != exp_rand:
                errs.append(f'{reg.name}.{f.name}: handle {c[0]} declared {"with" if decl.get(c[0]) else "without"} rand, expected {"with" if exp_rand else "without"}')
        bd = {m[2]: bool(m[0]) for m in re.findall(r'^\s*(rand\s+)?(\w+)\s+(\w+);\s+// 0x[0-9A-F]+', btxt, re.M)}
        if bd.get(namer.ident(reg.name)) != bool(RAND_ALL or any(is_rand(reg, f) for f in reg.fields)):
            errs.append(f'{reg.name}: block handle rand keyword does not follow the rule')
        h = namer.ident(reg.name)
        if h not in addmap:
            errs.append(f'{reg.name}: add_reg missing in block')
        else:
            cname, rights = addmap[h]
            if cname != addr_const(prefix, reg, namer):
                errs.append(f'{reg.name}: add_reg uses {cname}, expected {addr_const(prefix, reg, namer)}')
            if consts.get(cname) != reg.offset:
                errs.append(f'{reg.name}: package constant {cname} = {consts.get(cname)} != workbook 0x{reg.offset:03X}')
            if rights != reg.access:
                errs.append(f'{reg.name}: add_reg rights {rights} != workbook {reg.access}')
    if f'class {block} extends uvm_reg_block;' not in btxt:
        errs.append('block class missing')
    if 'lock_model();' not in btxt:
        errs.append('lock_model() missing')
    if len(addmap) != len(regs):
        errs.append(f'{len(addmap)} add_reg calls, expected {len(regs)}')
    return errs


# --------------------------------------------------------------------------------------
def main(argv=None):
    ap = argparse.ArgumentParser(description='Generate UVM RAL register and register-block classes from the CAN register workbook.')
    ap.add_argument('--xlsx', default='CAN_2.0B_Register_Map.xlsx', help='register workbook (default: %(default)s)')
    ap.add_argument('--out', default='ral', help='output directory (default: %(default)s)')
    ap.add_argument('--prefix', default='can', help='prefix for classes and files (default: %(default)s)')
    ap.add_argument('--block-name', default=None, help='register block class name (default: <prefix>_reg_block)')
    ap.add_argument('--style', choices=['lower', 'upper', 'asis'], default='lower', help='case of generated identifiers (default: %(default)s)')
    ap.add_argument('--no-reserved', action='store_true', help='do not emit reserved fields')
    ap.add_argument('--bus-bytes', type=int, default=4, help='bus width in bytes for the address map (default: %(default)s)')
    ap.add_argument('--addr-width', type=int, default=12, help='PADDR width used for the address constants (default: %(default)s)')
    ap.add_argument('--single-file', action='store_true', help='write all register classes into one <prefix>_regs<ext> instead of one file per register')
    ap.add_argument('--rand-all', action='store_true', help='write the rand keyword on every field and register handle (ralgen style) instead of only the randomizable ones')
    ap.add_argument('--ext', default='.sv', help="extension of the generated register and block files (default: %(default)s)")
    ap.add_argument('--verify', action='store_true', help='re-parse the generated files and compare with the workbook; exit 1 on mismatch')
    ap.add_argument('--dry-run', action='store_true', help='read and validate the workbook, print a summary, write nothing')
    a = ap.parse_args(argv)
    global EXT, RAND_ALL
    RAND_ALL = a.rand_all
    if not re.fullmatch(r'\.[A-Za-z0-9]+', a.ext):
        print(f'ERROR: --ext must look like .sv or .svh, got {a.ext!r}', file=sys.stderr)
        return 2
    EXT = a.ext
    src = os.path.basename(a.xlsx)
    try:
        regs = load_model(a.xlsx)
    except (GenError, OSError) as e:
        print(f'ERROR: {e}', file=sys.stderr)
        return 2
    nf = sum(len([f for f in r.fields if not (a.no_reserved and f.reserved)]) for r in regs)
    print(f'read {len(regs)} registers, {nf} fields from {src}')
    if a.dry_run:
        for r in regs:
            print(f'  0x{r.offset:03X} {r.name:<14} {r.access}  {len(r.fields)} field row(s)')
        return 0
    namer = Namer(a.style)
    block = a.block_name or namer.ident(f'{a.prefix}_reg_block')
    per_file = not a.single_file
    os.makedirs(a.out, exist_ok=True)
    if per_file:
        rfiles = gen_reg_files(a.prefix, regs, namer, not a.no_reserved, src)
        cnames = {reg.name: rf[2] for reg, rf in zip(regs, rfiles)}
        reg_includes = [rf[0] for rf in rfiles]
        out_files = {rf[0]: rf[1] for rf in rfiles}
    else:
        regs_txt, cnames = gen_regs_single_file(a.prefix, regs, namer, not a.no_reserved, src)
        reg_includes = [regs_file_name(a.prefix)]
        out_files = {regs_file_name(a.prefix): regs_txt}
    blk_txt, handles = gen_block_file(a.prefix, block, regs, cnames, namer, a.bus_bytes, src)
    pkg_txt = gen_pkg_file(a.prefix, block, regs, namer, a.addr_width, src, reg_includes)
    if block_file_name(a.prefix) in out_files:
        print(f'ERROR: generated file name {block_file_name(a.prefix)} is used twice (a register is named like the block)', file=sys.stderr)
        return 2
    out_files[block_file_name(a.prefix)] = blk_txt
    pkg_name = f'{a.prefix}_reg_pkg.sv'
    if pkg_name in out_files:
        print(f'ERROR: generated file name {pkg_name} is used twice (a register and the package map to the same name)', file=sys.stderr)
        return 2
    out_files[pkg_name] = pkg_txt
    for fn, txt in out_files.items():
        with open(os.path.join(a.out, fn), 'w') as fh:
            fh.write(txt)
    print(f'wrote {len(out_files)} files to {a.out}/: ' + (f'{len(regs)} register class files ({reg_includes[0]} ... {reg_includes[-1]}), ' if per_file else f'{reg_includes[0]}, ')
          + f'{block_file_name(a.prefix)}, {a.prefix}_reg_pkg.sv')
    # leftovers from an earlier run (other layout or other extension) would confuse an include path:
    # report them, never delete them
    used = set(out_files)
    cand = set()
    for ext in ('.sv', '.svh'):
        saved, EXT = EXT, ext
        cand |= {reg_file_name(a.prefix, r, namer) for r in regs} | {block_file_name(a.prefix), regs_file_name(a.prefix)}
        EXT = saved
    stale = sorted(x for x in cand - used if os.path.exists(os.path.join(a.out, x)))
    if stale:
        print(f'note: {len(stale)} file(s) from an earlier layout / extension are still in {a.out}/ and are not used: {stale[0]}' + (' ...' if len(stale) > 1 else ''))
    for msg in namer.renames:
        print('note:', msg)
    if a.verify:
        errs = verify(a.out, a.prefix, block, regs, namer, not a.no_reserved, per_file)
        if errs:
            print('VERIFY FAILED:', *errs, sep='\n  ', file=sys.stderr)
            return 1
        print(f'verify OK: {len(regs)} classes, {nf} configure() calls, {len(regs)} add_reg() calls and {len(regs)} package offset constants match the workbook')
    return 0


if __name__ == '__main__':
    sys.exit(main())
