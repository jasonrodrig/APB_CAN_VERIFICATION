`ifndef APB_CAN_VIRTUAL_SEQUENCER_INCLUDED_
`define APB_CAN_VIRTUAL_SEQUENCER_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: apb_can_virtual_sequencer
//  Holds the handles of the APB master sequencers and register models of every node
//--------------------------------------------------------------------------------------------
class apb_can_virtual_sequencer extends uvm_sequencer #(uvm_sequence_item);
  `uvm_component_utils(apb_can_virtual_sequencer)

  //Variable: apb_master_seqr_h
  //Handles of the APB master sequencers, one per node
  apb_master_sequencer apb_master_seqr_h[];

  //Variable: apb_can_reg_model_h
  //Handles of the CAN register models (APB_CAN_REG_MODEL[]), one per node
  can_reg_block apb_can_reg_model_h[];

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "apb_can_virtual_sequencer", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);

endclass : apb_can_virtual_sequencer

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - apb_can_virtual_sequencer
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function apb_can_virtual_sequencer::new(string name = "apb_can_virtual_sequencer", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//  Allocates the handle arrays
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void apb_can_virtual_sequencer::build_phase(uvm_phase phase);
  super.build_phase(phase);
  apb_master_seqr_h   = new[`NO_OF_NODES];
  apb_can_reg_model_h = new[`NO_OF_NODES];
endfunction : build_phase

`endif
