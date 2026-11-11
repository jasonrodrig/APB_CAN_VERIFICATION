# ================================================================
# APB CAN bridge verification - Makefile for Questa and Synopsys VCS
# ================================================================

# make compile  sim=<questa|vcs> nodes=<number of CAN nodes> stub=<0|1>
# make simulate sim=<questa|vcs> test=<test_name> uvm_verbosity=<VERBOSITY_LEVEL>
# make all      sim=<questa|vcs> test=<test_name>
# make cov      sim=vcs test=<test_name>     (VCS only: coverage report)
# make wave     sim=<questa|vcs> test=<test_name>
# make clean    sim=<questa|vcs>

# Questa recipes work from cmd.exe, PowerShell or sh (Git Bash).
# VCS recipes and the report targets need a Linux/sh shell.

.DEFAULT_GOAL := usage

# ------------------------------------------------
# User variables
# ------------------------------------------------
sim           ?= vcs
test          ?= apb_can_reg_access_test
uvm_verbosity ?= UVM_MEDIUM
nodes         ?= 3

# stub=1 : compile stub/stub_can_controller_top.sv instead of the RTL
# (simulation stand-in only)
stub          ?= 1

# waves=1 : Questa only - log all signals to $(test)/$(test).wlf
# VCS always dumps FSDB
waves         ?= 0

# UVM library version used by VCS (-ntb_opts)
vcs_uvm       ?= uvm-1.1

ifeq ($(filter $(sim),questa vcs),)
$(error sim must be questa or vcs (got "$(sim)"))
endif

# ------------------------------------------------
# Paths (relative to src/dv)
# ------------------------------------------------
DV_DIR   := .
AVIP_DIR := ./apb_avip
RTL_DIR  := ../rtl
RAL_DIR  := ./ral
TOP      := apb_can_top

COMPILE_LOG := compile.log
SIM_LOG     := $(test)/$(test).log

RTL_FILES := $(wildcard $(RTL_DIR)/*.sv) $(wildcard $(RTL_DIR)/*.v)

# DUT source: real RTL when stub=0, stub when stub=1
ifeq ($(stub),1)
ifneq ($(strip $(RTL_FILES)),)
$(error stub=1 cannot be used while $(RTL_DIR) contains RTL; both define can_controller_top)
endif
DUT_FILES := $(DV_DIR)/stub/stub_can_controller_top.sv
else
DUT_FILES := $(RTL_FILES)
endif

INCDIRS := \
    +incdir+$(DV_DIR) \
    +incdir+$(AVIP_DIR)/globals \
    +incdir+$(AVIP_DIR)/hvl_top/master \
    +incdir+$(AVIP_DIR)/hvl_top/env \
    +incdir+$(RAL_DIR) \
    +incdir+$(DV_DIR)/can/can_sequence_item \
    +incdir+$(DV_DIR)/can/can_passive_agent \
    +incdir+$(DV_DIR)/sequence \
    +incdir+$(DV_DIR)/env \
    +incdir+$(DV_DIR)/virtual_sequence \
    +incdir+$(DV_DIR)/test

# Compile order: defines -> AVIP packages -> RAL -> CAN packages -> env
#                -> sequences -> virtual sequences -> tests
#                -> interfaces/BFMs -> assertions -> RTL -> top
SRC_FILES := \
    $(DV_DIR)/define.sv \
    $(AVIP_DIR)/globals/apb_global_pkg.sv \
    $(AVIP_DIR)/hvl_top/master/apb_master_pkg.sv \
    $(AVIP_DIR)/hvl_top/env/apb_environment_pkg.sv \
    $(RAL_DIR)/can_reg_pkg.sv \
    $(DV_DIR)/can/can_sequence_item/typedef_enum_packages.sv \
    $(DV_DIR)/can/can_sequence_item/can_sequence_item_packages.sv \
    $(DV_DIR)/can/can_passive_agent/can_passive_packages.sv \
    $(DV_DIR)/env/apb_can_packages.sv \
    $(DV_DIR)/sequence/apb_can_sequence_packages.sv \
    $(DV_DIR)/virtual_sequence/apb_can_virtual_sequence_packages.sv \
    $(DV_DIR)/test/apb_can_test_packages.sv \
    $(AVIP_DIR)/hdl_top/apb_if/apb_if.sv \
    $(AVIP_DIR)/hdl_top/master_agent_bfm/apb_master_driver_bfm.sv \
    $(AVIP_DIR)/hdl_top/master_agent_bfm/apb_master_monitor_bfm.sv \
    $(AVIP_DIR)/hdl_top/master_agent_bfm/apb_master_agent_bfm.sv \
    $(DV_DIR)/interface/can_interface.sv \
    $(DV_DIR)/interface/can_bus.sv \
    $(DV_DIR)/assertions/apb_can_assertion.sv \
    $(DUT_FILES) \
    $(DV_DIR)/$(TOP).sv

DEFINES := +define+NO_OF_NODES=$(nodes)

# ------------------------------------------------
# Questa commands
# ------------------------------------------------
QUESTA_COMPILE = vlog -sv +acc -mfcu \
    $(DEFINES) \
    -l $(COMPILE_LOG) \
    $(INCDIRS) \
    $(SRC_FILES)

ifeq ($(waves),1)
QUESTA_WAVE_ARGS := -wlf $(test)/$(test).wlf
QUESTA_DO        := log -r /*; run -all; exit
else
QUESTA_WAVE_ARGS :=
QUESTA_DO        := run -all; exit
endif

QUESTA_SIMULATE = vsim -vopt work.$(TOP) \
    -voptargs=+acc=npr \
    -assertdebug \
    +UVM_TESTNAME=$(test) \
    +UVM_VERBOSITY=$(uvm_verbosity) \
    $(QUESTA_WAVE_ARGS) \
    -l $(SIM_LOG) \
    -c -do "$(QUESTA_DO)"

# ------------------------------------------------
# VCS commands
# ------------------------------------------------
VCS_COMPILE = vcs -full64 -sverilog +v2k \
    -v2k_generate \
    +warn=noOBSV2G \
    -debug_access+all +error+100 \
    -debug_acc+pp+dmptf \
    -ntb_opts $(vcs_uvm) \
    +plusarg_save \
    +ntb_random_seed_automatic \
    +memcbk \
    +vcs+fsdbon+all \
    -override_timescale=1ns/1ps \
    -top $(TOP) \
    $(DEFINES) \
    -l $(COMPILE_LOG) \
    $(INCDIRS) \
    $(SRC_FILES)

VCS_SIMULATE = cd $(test) && ../simv \
    +UVM_TESTNAME=$(test) \
    +UVM_VERBOSITY=$(uvm_verbosity) \
    -l $(test).log

# Log patterns used by the reports
ifeq ($(sim),vcs)
COMPILE_ERR_PAT  := ^Error
COMPILE_WARN_PAT := ^Warning
else
COMPILE_ERR_PAT  := ^\*\* Error
COMPILE_WARN_PAT := ^\*\* Warning
endif

.PHONY: usage all compile simulate cov wave clean compile_report simulate_report

# ================================================================
# ALL
# ================================================================
all: clean compile simulate

# ================================================================
# COMPILE
# ================================================================
compile:
ifeq ($(sim),questa)
	@vlib work
	$(QUESTA_COMPILE)
else
	@echo ""
	@echo "================================================================"
	@echo "                    COMPILATION (VCS)"
	@echo "================================================================"
	$(VCS_COMPILE)
	@$(MAKE) --no-print-directory compile_report sim=vcs
endif

# ================================================================
# SIMULATE
# ================================================================
simulate:
ifeq ($(sim),questa)
	@mkdir -p $(test)
	$(QUESTA_SIMULATE)
else
	@echo ""
	@echo "================================================================"
	@echo "                    SIMULATION (VCS)"
	@echo "================================================================"
	@echo "Test Name   : $(test)"
	@echo "Verbosity   : $(uvm_verbosity)"
	@echo ""
	@mkdir -p $(test)
	$(VCS_SIMULATE)
	@$(MAKE) --no-print-directory cov sim=vcs test=$(test)
	@$(MAKE) --no-print-directory simulate_report sim=vcs test=$(test) uvm_verbosity=$(uvm_verbosity)
endif

# ================================================================
# COVERAGE (VCS)
# ================================================================
cov:
ifeq ($(sim),vcs)
	@mkdir -p $(test)/urgReport
	urg -report $(test)/urgReport -dir simv.vdb
	@echo "Coverage report: $(test)/urgReport/dashboard.html"
else
	@echo "Coverage reporting is set up for VCS only (sim=vcs)."
endif

# ================================================================
# WAVEFORM
# ================================================================
wave:
ifeq ($(sim),vcs)
	verdi -ssf $(test)/novas.fsdb &
else
	vsim -view $(test)/$(test).wlf
endif

# ================================================================
# REPORTS (need sh: Linux or Git Bash)
# ================================================================
compile_report:
	@echo ""
	@echo "----------------------------------------------------------------"
	@echo "                 Compilation Report"
	@echo "----------------------------------------------------------------"
	@echo "Errors:"
	@grep -E "$(COMPILE_ERR_PAT)" $(COMPILE_LOG) || echo "  none"
	@echo ""
	@echo "Warnings:"
	@grep -E "$(COMPILE_WARN_PAT)" $(COMPILE_LOG) || echo "  none"
	@echo ""
	@echo "Log file: $(COMPILE_LOG)"
	@echo "----------------------------------------------------------------"

simulate_report:
	@echo ""
	@echo "----------------------------------------------------------------"
	@echo "                  Simulation Report"
	@echo "----------------------------------------------------------------"
	@echo "Test Name     : $(test)"
	@echo "UVM Verbosity : $(uvm_verbosity)"
	@echo ""
	@echo "UVM summary:"
	@grep -E "(FATAL|ERROR|WARN) *:" $(SIM_LOG) || echo "  no UVM report summary found"
	@echo ""
	@echo "UVM_FATAL:"
	@grep FATAL $(SIM_LOG) || echo "None"
	@echo ""
	@echo "UVM_ERROR:"
	@grep ERROR $(SIM_LOG) || echo "None"
	@echo ""
	@echo "UVM_WARNING:"
	@grep WARNING $(SIM_LOG) || echo "None"
	@echo ""
	@echo "Log file : less -R $(SIM_LOG)"

ifeq ($(sim),vcs)
	@echo "Waveform : make wave sim=vcs test=$(test)"
	@echo "Coverage : firefox $(test)/urgReport/dashboard.html &"
else
	@echo "Waveform : make wave test=$(test)   (run simulate with waves=1 first)"
endif

	@echo "----------------------------------------------------------------"

# ================================================================
# CLEAN
# ================================================================
clean:
ifeq ($(sim),questa)
	# Deletion is done in Questa's Tcl so that clean works whether make
	# runs its recipes through cmd.exe (PowerShell / Command Prompt) or
	# sh (Git Bash). Removes the given test folder.
	vsim -c -do "transcript file {}; file delete -force {*}[glob -nocomplain work transcript $(test) *.log *.wlf *.vcd *.vstf]; quit -f"
else
	rm -rf csrc simv simv.daidir simv.vdb ucli.key vc_hdrs.h  apb_can_* \
	    verdiLog novas.* nWaveLog vfastLog *.fsdb *.vpd *.vcd \
	    urgReport .restart* *.so *.log $(test)
	@echo "Clean completed."
endif

# ================================================================
# USAGE
# ================================================================
usage:
	@echo ""
	@echo "================================================================"
	@echo "            APB CAN Bridge Verification (Questa / VCS)"
	@echo "================================================================"
	@echo ""
	@echo "  make compile  sim=<questa|vcs> nodes=<CAN nodes, default $(nodes)> stub=<0|1, default $(stub)>"
	@echo "  make simulate sim=<questa|vcs> test=<test, default $(test)> uvm_verbosity=<default $(uvm_verbosity)>"
	@echo "  make all      sim=<questa|vcs> test=<test>      clean + compile + simulate"
	@echo "  make cov      sim=vcs test=<test>               coverage report (VCS)"
	@echo "  make wave     sim=<questa|vcs> test=<test>      open waveform"
	@echo "  make clean    sim=<questa|vcs>"
	@echo ""
	@echo "  Default simulator: $(sim)    Questa waves: waves=1"
	@echo "================================================================"
	@echo ""

