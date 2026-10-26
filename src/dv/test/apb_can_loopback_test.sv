`ifndef APB_CAN_LOOPBACK_TEST_INCLUDED_
`define APB_CAN_LOOPBACK_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: apb_can_loopback_test
//  Runs apb_can_virtual_loopback_sequence: programs BRP on every node, then puts node
//  loopback_node in loopback mode so that it is disconnected from the CAN bus
//--------------------------------------------------------------------------------------------
class apb_can_loopback_test extends apb_can_base_test;
  `uvm_component_utils(apb_can_loopback_test)

  //Variable: loopback_node
  //Index of the node to put in loopback mode
  int loopback_node = 1;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "apb_can_loopback_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);

endclass : apb_can_loopback_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - apb_can_loopback_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function apb_can_loopback_test::new(string name = "apb_can_loopback_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: run_phase
//  Starts the loopback virtual sequence
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task apb_can_loopback_test::run_phase(uvm_phase phase);
  apb_can_virtual_loopback_sequence apb_can_virtual_loopback_seq_h;

  apb_can_virtual_loopback_seq_h = apb_can_virtual_loopback_sequence::type_id::create("apb_can_virtual_loopback_seq_h");
  apb_can_virtual_loopback_seq_h.loopback_node = loopback_node;

  phase.raise_objection(this);
  apb_can_virtual_loopback_seq_h.start(apb_can_env_h.apb_can_virtual_seqr_h);
  phase.drop_objection(this);
endtask : run_phase

`endif
