`ifndef APB_CAN_VIRTUAL_BASE_SEQUENCE_INCLUDED_
`define APB_CAN_VIRTUAL_BASE_SEQUENCE_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: apb_can_virtual_base_sequence
//  Base virtual sequence; runs on apb_can_virtual_sequencer and starts APB CAN sequences
//--------------------------------------------------------------------------------------------
class apb_can_virtual_base_sequence extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(apb_can_virtual_base_sequence)

  `uvm_declare_p_sequencer(apb_can_virtual_sequencer)

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "apb_can_virtual_base_sequence");
  extern virtual task body();

endclass : apb_can_virtual_base_sequence

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - apb_can_virtual_base_sequence
//--------------------------------------------------------------------------------------------
function apb_can_virtual_base_sequence::new(string name = "apb_can_virtual_base_sequence");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
//  Casts the p_sequencer
//--------------------------------------------------------------------------------------------
task apb_can_virtual_base_sequence::body();
  if(!$cast(p_sequencer, m_sequencer)) begin
    `uvm_error(get_full_name(), "Virtual sequencer pointer cast failed")
  end
endtask : body

`endif
