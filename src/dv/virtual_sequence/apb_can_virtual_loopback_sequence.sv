`ifndef APB_CAN_VIRTUAL_LOOPBACK_SEQUENCE_INCLUDED_
`define APB_CAN_VIRTUAL_LOOPBACK_SEQUENCE_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: apb_can_virtual_loopback_sequence
//  Programs the BRP of every node (apb_can_reg_access_sequence), then puts node
//  loopback_node in loopback mode (apb_can_loopback_sequence). Both are started on this
//  virtual sequencer (p_sequencer).
//--------------------------------------------------------------------------------------------
class apb_can_virtual_loopback_sequence extends apb_can_virtual_base_sequence;
  `uvm_object_utils(apb_can_virtual_loopback_sequence)

  //Variable: loopback_node
  //Index of the node to put in loopback mode, assigned by the test
  int loopback_node;

  //Variable: apb_can_reg_access_seq_h
  //Handle of the register access sequence
  apb_can_reg_access_sequence apb_can_reg_access_seq_h;

  //Variable: apb_can_loopback_seq_h
  //Handle of the loopback sequence
  apb_can_loopback_sequence apb_can_loopback_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "apb_can_virtual_loopback_sequence");
  extern virtual task body();

endclass : apb_can_virtual_loopback_sequence

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - apb_can_virtual_loopback_sequence
//--------------------------------------------------------------------------------------------
function apb_can_virtual_loopback_sequence::new(string name = "apb_can_virtual_loopback_sequence");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
//  Starts the register access sequence and then the loopback sequence
//--------------------------------------------------------------------------------------------
task apb_can_virtual_loopback_sequence::body();
  super.body();

  apb_can_reg_access_seq_h = apb_can_reg_access_sequence::type_id::create("apb_can_reg_access_seq_h");
  apb_can_reg_access_seq_h.start(p_sequencer, this);

  apb_can_loopback_seq_h = apb_can_loopback_sequence::type_id::create("apb_can_loopback_seq_h");
  apb_can_loopback_seq_h.loopback_node = loopback_node;
  apb_can_loopback_seq_h.start(p_sequencer, this);
endtask : body

`endif
