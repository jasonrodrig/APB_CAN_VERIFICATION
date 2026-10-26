`ifndef APB_CAN_BASE_TEST_INCLUDED_
`define APB_CAN_BASE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: apb_can_base_test
//  Base test; creates the environment, configures the APB master agent of every node and
//  installs the custom report server
//--------------------------------------------------------------------------------------------
class apb_can_base_test extends uvm_test;
  `uvm_component_utils(apb_can_base_test)

  //Variable: apb_can_env_h
  //Handle of the APB CAN environment
  apb_can_environment apb_can_env_h;

  //Variable: apb_master_agent_cfg_h
  //APB master agent configuration of each node
  apb_master_agent_config apb_master_agent_cfg_h[];

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "apb_can_base_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void setup_apb_master_agent_config();
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : apb_can_base_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - apb_can_base_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function apb_can_base_test::new(string name = "apb_can_base_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//  Installs the report server, sets agent configurations and creates the environment
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void apb_can_base_test::build_phase(uvm_phase phase);
  apb_can_report_server      apb_can_report_server_h;
  apb_can_ral_report_catcher apb_can_ral_report_catcher_h;

  super.build_phase(phase);

  apb_can_report_server_h = new();
  uvm_report_server::set_server(apb_can_report_server_h);

  // Must be installed before the register model is built in the environment
  apb_can_ral_report_catcher_h = apb_can_ral_report_catcher::type_id::create("apb_can_ral_report_catcher_h");
  uvm_report_cb::add(null, apb_can_ral_report_catcher_h);

  setup_apb_master_agent_config();

  apb_can_env_h = apb_can_environment::type_id::create("apb_can_env_h", this);
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: setup_apb_master_agent_config
//  Creates the APB master agent configuration of each node and stores it in config_db
//--------------------------------------------------------------------------------------------
function void apb_can_base_test::setup_apb_master_agent_config();
  apb_master_agent_cfg_h = new[`NO_OF_NODES];

  foreach(apb_master_agent_cfg_h[i]) begin
    apb_master_agent_cfg_h[i] = apb_master_agent_config::type_id::create($sformatf("apb_master_agent_config[%0d]", i));
    apb_master_agent_cfg_h[i].is_active    = MASTER_AGENT_ACTIVE ? UVM_ACTIVE : UVM_PASSIVE;
    apb_master_agent_cfg_h[i].no_of_slaves = NO_OF_SLAVES;
    apb_master_agent_cfg_h[i].has_coverage = 1;

    // DUT register space: PADDR[11:0]
    apb_master_agent_cfg_h[i].master_min_addr_range(0, 0);
    apb_master_agent_cfg_h[i].master_max_addr_range(0, (2**`CAN_APB_ADDR_WIDTH) - 1);

    uvm_config_db #(apb_master_agent_config)::set(this, $sformatf("*apb_master_agent_h[%0d]*", i),
                                                  "apb_master_agent_config", apb_master_agent_cfg_h[i]);
  end
endfunction : setup_apb_master_agent_config

//--------------------------------------------------------------------------------------------
// Function: end_of_elaboration_phase
//  Prints the testbench topology
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void apb_can_base_test::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  uvm_top.print_topology();
endfunction : end_of_elaboration_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
//  Starts the virtual base sequence
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task apb_can_base_test::run_phase(uvm_phase phase);
  apb_can_virtual_base_sequence apb_can_virtual_base_seq_h;

  apb_can_virtual_base_seq_h = apb_can_virtual_base_sequence::type_id::create("apb_can_virtual_base_seq_h");

  phase.raise_objection(this);
  apb_can_virtual_base_seq_h.start(apb_can_env_h.apb_can_virtual_seqr_h);
  phase.drop_objection(this);
endtask : run_phase

`endif
