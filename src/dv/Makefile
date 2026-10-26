# APB CAN bridge verification - Questa makefile
#
# make compile nodes=<number of CAN nodes> stub=<0|1>
# make simulate test=<test_name> uvm_verbosity=<VERBOSITY_LEVEL>
# make all

test          ?= apb_can_loopback_test
uvm_verbosity ?= UVM_MEDIUM
nodes         ?= 3
# stub=1 : compile stub/stub_can_controller_top.sv instead of the RTL (simulation stand-in only)
stub          ?= 1

# Paths (relative to src/dv)
DV_DIR   := .
AVIP_DIR := ./apb_avip
RTL_DIR  := ../rtl
RAL_DIR  := ./ral

RTL_FILES := $(wildcard $(RTL_DIR)/*.sv) $(wildcard $(RTL_DIR)/*.v)

# DUT source: real RTL by default, stub when stub=1
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

# Compile order: defines -> AVIP packages -> RAL -> CAN packages -> env -> sequences
#                -> virtual sequences -> tests -> interfaces/BFMs -> assertions -> RTL -> top
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
	$(DV_DIR)/apb_can_top.sv

.PHONY: usage all compile simulate clean

usage:
	@echo "make compile nodes=<number of CAN nodes, default 3> stub=<1 to use the simulation stub DUT, default 0>"
	@echo "make simulate test=<test_name> uvm_verbosity=<VERBOSITY_LEVEL>"
	@echo "make all"
	@echo "make clean"

all: clean compile simulate

compile:
	vlib work
	vlog -sv +acc -mfcu \
	+define+NO_OF_NODES=$(nodes) \
	-l $(test)_compile.log \
	$(INCDIRS) \
	$(SRC_FILES)

simulate:
	-mkdir $(test)
	vsim -vopt work.apb_can_top \
	-voptargs=+acc=npr \
	-assertdebug \
	+UVM_TESTNAME=$(test) \
	+UVM_VERBOSITY=$(uvm_verbosity) \
	-l $(test)/$(test).log \
	-c -do "run -all; exit"

# Deletion is done in Questa's Tcl so that clean works whether make runs its recipes through
# cmd.exe (PowerShell / Command Prompt) or sh (Git Bash). Removes the given test folder.
clean:
	vsim -c -do "transcript file {}; file delete -force {*}[glob -nocomplain work transcript $(test) *.log *.wlf *.vcd *.vstf]; quit -f"
