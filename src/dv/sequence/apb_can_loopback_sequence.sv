`ifndef APB_CAN_LOOPBACK_SEQUENCE_INCLUDED_
`define APB_CAN_LOOPBACK_SEQUENCE_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: apb_can_loopback_sequence
//  Programs CONTROL.loopback = 1 on node loopback_node, which disconnects that node from the
//  CAN bus (see can_bus.sv). Accesses go through p_sequencer.apb_can_reg_model_h[loopback_node].
//--------------------------------------------------------------------------------------------
class apb_can_loopback_sequence extends apb_can_base_sequence;
  `uvm_object_utils(apb_can_loopback_sequence)

  //Variable: loopback_node
  //Index of the node to put in loopback mode
  int loopback_node;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "apb_can_loopback_sequence");
  extern virtual task body();

endclass : apb_can_loopback_sequence

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - apb_can_loopback_sequence
//--------------------------------------------------------------------------------------------
function apb_can_loopback_sequence::new(string name = "apb_can_loopback_sequence");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
//  Sets the loopback field and writes CONTROL, then reads it back
//--------------------------------------------------------------------------------------------
task apb_can_loopback_sequence::body();
  uvm_status_e   status;
  uvm_reg_data_t rdata;

  super.body();

  // Only the loopback field is changed; the other CONTROL fields keep their value
  p_sequencer.apb_can_reg_model_h[loopback_node].control.loopback.set(1'b1);
  p_sequencer.apb_can_reg_model_h[loopback_node].control.update(status, .parent(this));
  `uvm_info(get_type_name(), $sformatf("Node[%0d] CONTROL.loopback = 1 : status = %s", loopback_node, status.name()), UVM_LOW)

  p_sequencer.apb_can_reg_model_h[loopback_node].control.read(status, rdata, .parent(this));
  `uvm_info(get_type_name(), $sformatf("Node[%0d] CONTROL read : status = %s, data = 'h%0h", loopback_node, status.name(), rdata), UVM_LOW)
endtask : body

`endif
