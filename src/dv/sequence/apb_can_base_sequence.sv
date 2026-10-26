`ifndef APB_CAN_BASE_SEQUENCE_INCLUDED_
`define APB_CAN_BASE_SEQUENCE_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: apb_can_base_sequence
//  Base register sequence. It is started on apb_can_virtual_sequencer, so p_sequencer gives
//  access to the register model of every node:
//    p_sequencer.apb_can_reg_model_h[i]  (= uvm_test_top.apb_can_env_h.apb_can_reg_model_h[i])
//  Register accesses made on that model are converted by its map (apb_reg2bus_adapter_h) and
//  sent to the APB master sequencer of node i, set in apb_can_environment.
//--------------------------------------------------------------------------------------------
class apb_can_base_sequence extends uvm_reg_sequence #(uvm_sequence #(uvm_reg_item));
  `uvm_object_utils(apb_can_base_sequence)

  `uvm_declare_p_sequencer(apb_can_virtual_sequencer)

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "apb_can_base_sequence");
  extern virtual task body();

endclass : apb_can_base_sequence

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - apb_can_base_sequence
//--------------------------------------------------------------------------------------------
function apb_can_base_sequence::new(string name = "apb_can_base_sequence");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
//  Casts the p_sequencer
//--------------------------------------------------------------------------------------------
task apb_can_base_sequence::body();
  if(!$cast(p_sequencer, m_sequencer)) begin
    `uvm_fatal(get_type_name(), "Sequence must be started on apb_can_virtual_sequencer")
  end
endtask : body

`endif
