`ifndef APB_CAN_VIRTUAL_REG_ACCESS_SEQUENCE_INCLUDED_
`define APB_CAN_VIRTUAL_REG_ACCESS_SEQUENCE_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: apb_can_virtual_reg_access_sequence
//  Starts apb_can_reg_access_sequence on this virtual sequencer (p_sequencer). The register
//  sequence loops over the nodes itself.
//--------------------------------------------------------------------------------------------
class apb_can_virtual_reg_access_sequence extends apb_can_virtual_base_sequence;
  `uvm_object_utils(apb_can_virtual_reg_access_sequence)

  //Variable: apb_can_reg_access_seq_h
  //Handle of the register access sequence
  apb_can_reg_access_sequence apb_can_reg_access_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "apb_can_virtual_reg_access_sequence");
  extern virtual task body();

endclass : apb_can_virtual_reg_access_sequence

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - apb_can_virtual_reg_access_sequence
//--------------------------------------------------------------------------------------------
function apb_can_virtual_reg_access_sequence::new(string name = "apb_can_virtual_reg_access_sequence");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
//  Starts the register access sequence on the virtual sequencer
//--------------------------------------------------------------------------------------------
task apb_can_virtual_reg_access_sequence::body();
  super.body();

  apb_can_reg_access_seq_h = apb_can_reg_access_sequence::type_id::create("apb_can_reg_access_seq_h");
  apb_can_reg_access_seq_h.start(p_sequencer, this);
endtask : body

`endif
