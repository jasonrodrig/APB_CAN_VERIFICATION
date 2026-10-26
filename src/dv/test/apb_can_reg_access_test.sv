`ifndef APB_CAN_REG_ACCESS_TEST_INCLUDED_
`define APB_CAN_REG_ACCESS_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: apb_can_reg_access_test
//  Runs apb_can_virtual_reg_access_sequence (RAL front-door accesses over APB)
//--------------------------------------------------------------------------------------------
class apb_can_reg_access_test extends apb_can_base_test;
  `uvm_component_utils(apb_can_reg_access_test)

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "apb_can_reg_access_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);

endclass : apb_can_reg_access_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - apb_can_reg_access_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function apb_can_reg_access_test::new(string name = "apb_can_reg_access_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: run_phase
//  Starts the register access virtual sequence
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task apb_can_reg_access_test::run_phase(uvm_phase phase);
  apb_can_virtual_reg_access_sequence apb_can_virtual_reg_access_seq_h;

  apb_can_virtual_reg_access_seq_h = apb_can_virtual_reg_access_sequence::type_id::create("apb_can_virtual_reg_access_seq_h");

  phase.raise_objection(this);
  apb_can_virtual_reg_access_seq_h.start(apb_can_env_h.apb_can_virtual_seqr_h);
  phase.drop_objection(this);
endtask : run_phase

`endif
