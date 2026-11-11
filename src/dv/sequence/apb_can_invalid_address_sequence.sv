`ifndef APB_CAN_INVALID_ADDR_SEQUENCE_INCLUDED_
`define APB_CAN_INVALID_ADDR_SEQUENCE_INCLUDED_

class apb_can_invalid_address_sequence extends uvm_sequence #(apb_master_tx);
  `uvm_object_utils(apb_can_invalid_address_sequence)
  
  int node_id ;

  //Variable: paddress
  //Random invalid APB addressess
  rand bit [`CAN_APB_ADDR_WIDTH-1:0] paddr;

  //Variable: no_of_txns
  //Number of invalid addressesses accessed
  int no_of_txns = 3;

  //Constraint: paddress_c
  //Unaligned addressess, so no register is accessed
  constraint paddress_c { paddr[1:0] != 0; }

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "apb_can_invalid_address_sequence");
  extern virtual task body();
  extern virtual task apb_transfer(tx_type_e pwrite);

endclass : apb_can_invalid_address_sequence

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - apb_can_invalid_address_sequence
//--------------------------------------------------------------------------------------------
function apb_can_invalid_address_sequence::new(string name = "apb_can_invalid_address_sequence");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
//  Writes and reads no_of_txns random invalid addressesses
//--------------------------------------------------------------------------------------------
task apb_can_invalid_address_sequence::body();
  repeat(no_of_txns) begin
    if(!this.randomize()) begin
      `uvm_fatal(get_type_name(), "Randomization of paddress failed")
    end
    apb_transfer(WRITE);
    apb_transfer(READ);
  end
endtask : body

//--------------------------------------------------------------------------------------------
// Task: apb_transfer
//  Sends one 32-bit APB transfer to paddress and checks PSLVERR = 0 (and PRDATA = 0 for a read)
//
// Parameters:
//  pwrite - WRITE or READ
//--------------------------------------------------------------------------------------------
task apb_can_invalid_address_sequence::apb_transfer(tx_type_e pwrite);
  req = apb_master_tx::type_id::create("req");

  start_item(req);
  req.pselx         = SLAVE_0;
  req.paddr         = paddr;
  req.pwrite        = pwrite;
  req.pprot         = NORMAL_SECURE_DATA;
  req.transfer_size = BIT_32;
  req.pwdata        = (pwrite == WRITE) ? $urandom() : '0;
  req.pstrb         = (pwrite == WRITE) ? 4'b1111 : 4'b0000;
  finish_item(req);

endtask : apb_transfer

`endif

