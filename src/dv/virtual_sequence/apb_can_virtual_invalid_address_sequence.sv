`ifndef APB_CAN_VIRTUAL_INVALID_ADDR_SEQUENCE_INCLUDED_
`define APB_CAN_VIRTUAL_INVALID_ADDR_SEQUENCE_INCLUDED_

class apb_can_virtual_invalid_address_sequence extends apb_can_virtual_base_sequence;
  `uvm_object_utils(apb_can_virtual_invalid_address_sequence)

  //Variable: apb_can_invalid_address_seq_h
  //Handle of the invalid addressess sequence
  apb_can_invalid_address_sequence apb_can_invalid_address_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "apb_can_virtual_invalid_address_sequence");
  extern virtual task body();

endclass : apb_can_virtual_invalid_address_sequence

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - apb_can_virtual_invalid_address_sequence
//--------------------------------------------------------------------------------------------
function apb_can_virtual_invalid_address_sequence::new(string name = "apb_can_virtual_invalid_address_sequence");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
//  Starts the invalid addressess sequence on the virtual sequencer
//--------------------------------------------------------------------------------------------
task apb_can_virtual_invalid_address_sequence::body();
  super.body();

  for(int i = 0; i < `NO_OF_NODES; i++) begin
    apb_can_invalid_address_seq_h = apb_can_invalid_address_sequence::type_id::create($sformatf("apb_can_invalid_address_seq_h[%0d]", i));
    apb_can_invalid_address_seq_h.node_id = i;
    apb_can_invalid_address_seq_h.start(p_sequencer.apb_master_seqr_h[i], this);
  end
endtask : body


`endif

