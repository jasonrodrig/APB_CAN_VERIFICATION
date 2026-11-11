`ifndef APB_CAN_REGISTER_ACCESS_SEQUENCE_INCLUDED_
`define APB_CAN_REGISTER_ACCESS_SEQUENCE_INCLUDED_

class apb_can_register_access_sequence extends apb_can_base_sequence;
  `uvm_object_utils(apb_can_register_access_sequence)

  //Variable: result_q
  //One line per comparison, printed as a table at the end
  string result_q[$];

  //Variable: skipped_q
  //One line per skipped register / skipped field, printed after the results
  string skipped_q[$];

  //Variable: pass_count
  //Number of comparisons that matched
  int pass_count;

  //Variable: fail_count
  //Number of comparisons that did not match
  int fail_count;

  //Variable: skip_count
  //Number of registers with no HDL path
  int skip_count;

  //Variable: skip_field_count
  //Number of fields mapped on a wire or a reloaded reg (not poked)
  int skip_field_count;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "apb_can_register_access_sequence");
  extern virtual task body();
  extern virtual task check_register(int node, uvm_reg reg_h);
  extern function uvm_reg_data_t get_write_data(uvm_reg reg_h, uvm_reg_data_t base = 0);
  extern function void compare(int node, uvm_reg reg_h, string check, uvm_reg_data_t expected, uvm_reg_data_t actual);
  extern function void add_row(int node, uvm_reg reg_h, string check, string values, string result);
  extern function void add_skipped_row(int node, uvm_reg reg_h, string field, string reason);
  extern function void print_results();

endclass : apb_can_register_access_sequence

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - apb_can_register_access_sequence
//--------------------------------------------------------------------------------------------
function apb_can_register_access_sequence::new(string name = "apb_can_register_access_sequence");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
//  Checks every register of every node and prints the comparison table
//--------------------------------------------------------------------------------------------
task apb_can_register_access_sequence::body();
  uvm_reg      reg_q[$];
  uvm_status_e status;

  super.body();

  for(int i = 0; i < `NO_OF_NODES; i++) begin
    reg_q.delete();
    p_sequencer.apb_can_reg_model_h[i].get_registers(reg_q);

    foreach(reg_q[j]) begin
      if(reg_q[j] != p_sequencer.apb_can_reg_model_h[i].control) begin
        check_register(i, reg_q[j]);
      end
    end

    // CONTROL last, then disable the core again
    check_register(i, p_sequencer.apb_can_reg_model_h[i].control);
    p_sequencer.apb_can_reg_model_h[i].control.write(status, 'h0, .parent(this));
  end

  print_results();
endtask : body

//--------------------------------------------------------------------------------------------
// Task: check_register
//  Performs the frontdoor / register accesses of one register and compares them
//
// Parameters:
//  node  - index of the CAN node
//  reg_h - register to check
//--------------------------------------------------------------------------------------------
task apb_can_register_access_sequence::check_register(int node, uvm_reg reg_h);
  uvm_status_e   status;
  uvm_reg_data_t wdata;
  uvm_reg_data_t fd_data;
  uvm_reg_data_t bd_data;
  uvm_reg_data_t rd_data;
  string         rights;
  uvm_reg_field  fields[$];

  if(!reg_h.has_hdl_path()) begin
    skip_count++;
    add_skipped_row(node, reg_h, "(whole register)", apb_can_reg_hdl_paths::missing_fields.exists(reg_h) ? apb_can_reg_hdl_paths::missing_fields[reg_h] : "no HDL path");
    return;
  end

  // Fields mapped on a wire or a reloaded reg: listed as skipped fields
  reg_h.get_fields(fields);
  foreach(fields[i]) begin
    if(apb_can_reg_hdl_paths::skipped_field.exists(fields[i])) begin
      skip_field_count++;
      add_skipped_row(node, reg_h, fields[i].get_name(), apb_can_reg_hdl_paths::skipped_field[fields[i]]);
    end
  end

  rights = reg_h.get_rights(p_sequencer.apb_can_reg_model_h[node].default_map);

  case(rights)
    "RW": begin
      // Frontdoor write -> register read
      wdata = get_write_data(reg_h);
      reg_h.write(status, wdata, UVM_FRONTDOOR, .parent(this));
      // The write returns in the time step where the RTL samples it; its non-blocking update
      // happens later in that step, so wait for it before the peek (and before the poke)
      uvm_wait_for_nba_region();
      reg_h.peek(status, bd_data, .parent(this));
      compare(node, reg_h, "FD write -> BD read", wdata, bd_data);

      // Backdoor write -> frontdoor read
      wdata = get_write_data(reg_h);
      reg_h.poke(status, wdata, .parent(this));
      reg_h.read(status, fd_data, UVM_FRONTDOOR, .parent(this));
      compare(node, reg_h, "BD write -> FD read", wdata, fd_data);
    end

    "RO": begin
      // 1. Frontdoor read, 2. peek: both must give the same value
      reg_h.read(status, fd_data, UVM_FRONTDOOR, .parent(this));
      reg_h.peek(status, bd_data, .parent(this));
      compare(node, reg_h, "FD read  == BD read", fd_data, bd_data);

      // 3. Frontdoor write of some data: a read-only register must ignore it
      wdata = get_write_data(reg_h, fd_data);
      reg_h.write(status, wdata, UVM_FRONTDOOR, .parent(this));
      uvm_wait_for_nba_region();
      reg_h.peek(status, bd_data, .parent(this));
      compare(node, reg_h, "FD write ignored", fd_data, bd_data);

      // 4. Poke different data, frontdoor read must return it
      wdata = get_write_data(reg_h, fd_data);
      reg_h.poke(status, wdata, .parent(this));
      reg_h.read(status, rd_data, UVM_FRONTDOOR, .parent(this));
      compare(node, reg_h, "BD write -> FD read", wdata, rd_data);

      // 5. Poke the frontdoor read data back, frontdoor read must match the first read.
      //    The read returns on a PCLK edge where the RTL's self-holding flops (x <= x) have
      //    already scheduled their current value, so wait for that update before the poke
      uvm_wait_for_nba_region();
      reg_h.poke(status, fd_data, .parent(this));
      reg_h.read(status, rd_data, UVM_FRONTDOOR, .parent(this));
      compare(node, reg_h, "BD restore == FD read", fd_data, rd_data);
    end

    default: begin
      skip_count++;
      add_row(node, reg_h, "-", $sformatf("%s register", rights), "SKIPPED");
    end
  endcase

endtask : check_register

//--------------------------------------------------------------------------------------------
// Function: get_write_data
//  Returns a random write value made only of the register's fields: the RAL register is
//  randomized and its value read back, so bits with no field stay 0. RO fields are not
//  randomizable in the RAL, so they are filled here, bit by bit:
//   - storage_field : random
//   - skipped_field : the bit of base (the frontdoor read), since a poke there is not kept
//   - other RO fields (reserved) : 0
//  For CONTROL, loopback and listen_only are never both 1 (the RTL rejects that write with
//  PSLVERR).
//
// Parameters:
//  reg_h - register
//  base  - value kept in the skipped fields
//--------------------------------------------------------------------------------------------
function uvm_reg_data_t apb_can_register_access_sequence::get_write_data(uvm_reg reg_h, uvm_reg_data_t base = 0);
  uvm_reg_field fields[$];
  int           lsb;

  void'(reg_h.randomize());
  get_write_data = reg_h.get();

  reg_h.get_fields(fields);
  foreach(fields[i]) begin
    lsb = fields[i].get_lsb_pos();
    for(int b = lsb; b < lsb + fields[i].get_n_bits(); b++) begin
      if(apb_can_reg_hdl_paths::storage_field.exists(fields[i])) begin
        get_write_data[b] = $urandom_range(0, 1);
      end
      else if(apb_can_reg_hdl_paths::skipped_field.exists(fields[i])) begin
        get_write_data[b] = base[b];
      end
    end
  end

  if(reg_h.get_name() == "control" && get_write_data[1] && get_write_data[2]) begin
    get_write_data[2] = 1'b0;
  end

endfunction : get_write_data

//--------------------------------------------------------------------------------------------
// Function: compare
//  Compares the expected and actual values, reports a mismatch and records the result
//
// Parameters:
//  node     - index of the CAN node
//  reg_h    - register
//  check    - name of the check
//  expected - expected value
//  actual   - value read
//--------------------------------------------------------------------------------------------
function void apb_can_register_access_sequence::compare(int node, uvm_reg reg_h, string check, uvm_reg_data_t expected, uvm_reg_data_t actual);
  string values;

  values = $sformatf("exp = 'h%08h  act = 'h%08h", expected, actual);

  if(expected === actual) begin
    pass_count++;
    add_row(node, reg_h, check, values, "PASS");
  end

  else begin
    fail_count++;
    add_row(node, reg_h, check, values, "FAIL");
    `uvm_error(get_type_name(), $sformatf("Node[%0d] %s %s : %s", node, reg_h.get_name(), check, values))
  end

endfunction : compare

//--------------------------------------------------------------------------------------------
// Function: add_row
//  Adds one line to the result table
//
// Parameters:
//  node   - index of the CAN node
//  reg_h  - register
//  check  - name of the check
//  values - compared values
//  result - PASS / FAIL / SKIPPED
//--------------------------------------------------------------------------------------------
function void apb_can_register_access_sequence::add_row(int node, uvm_reg reg_h, string check, string values, string result);
  result_q.push_back($sformatf("  %-4d %-13s 'h%03h  %-20s %-48s %s", node, reg_h.get_name(), reg_h.get_address(p_sequencer.apb_can_reg_model_h[node].default_map), check, values, result));
endfunction : add_row

//--------------------------------------------------------------------------------------------
// Function: add_skipped_row
//  Adds one line to the skipped registers / fields table
//
// Parameters:
//  node   - index of the CAN node
//  reg_h  - register
//  field  - skipped field, or "(whole register)"
//  reason - why it is skipped
//--------------------------------------------------------------------------------------------
function void apb_can_register_access_sequence::add_skipped_row(int node, uvm_reg reg_h, string field, string reason);
  skipped_q.push_back($sformatf("  %-4d %-13s 'h%03h  %-20s %s", node, reg_h.get_name(), reg_h.get_address(p_sequencer.apb_can_reg_model_h[node].default_map), field, reason));
endfunction : add_skipped_row

//--------------------------------------------------------------------------------------------
// Function: print_results
//  Prints the comparison table, the summary and the skipped registers
//--------------------------------------------------------------------------------------------
function void apb_can_register_access_sequence::print_results();
  string result_table;
  string line;

  line  = {"  ", {130{"-"}}, "\n"};
  result_table = {"\n", line, $sformatf("  %-4s %-13s %-6s %-20s %-48s %s\n", "Node", "Register", "Addr", "Check", "Values", "Result"), line};

  foreach(result_q[i]) begin
    result_table = {result_table, result_q[i], "\n"};
  end

  result_table = {result_table, line, $sformatf("  PASS = %0d   FAIL = %0d   SKIPPED registers = %0d   SKIPPED fields = %0d\n", pass_count, fail_count, skip_count, skip_field_count), line};

  result_table = {result_table, "\n  Skipped registers / fields (no holding reg in the RTL, not poked)\n", line, $sformatf("  %-4s %-13s %-6s %-20s %s\n", "Node", "Register", "Addr", "Field", "Reason"), line};
  
  foreach(skipped_q[i]) begin
    result_table = {result_table, skipped_q[i], "\n"};
  end
  
  result_table = {result_table, line};

  `uvm_info(get_type_name(), {"Backdoor access comparison results", result_table}, UVM_NONE)
endfunction : print_results

`endif

