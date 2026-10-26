`ifndef CAN_SEQUENCE_ITEM_INCLUDED_
`define CAN_SEQUENCE_ITEM_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: can_sequence_item
//  CAN 2.0B frame observed on the CAN bus by the passive monitor
//--------------------------------------------------------------------------------------------
class can_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(can_sequence_item)

  //Variable: node_id
  //Index of the CAN node on which the frame was observed
  int node_id;

  //Variable: ide
  //Frame format: standard or extended identifier
  rand can_frame_format_e ide;

  //Variable: rtr
  //Frame type: data or remote frame
  rand can_frame_type_e rtr;

  //Variable: id
  //Frame identifier (11-bit used when ide == STANDARD_FRAME)
  rand bit [28:0] id;

  //Variable: dlc
  //Data length code
  rand bit [3:0] dlc;

  //Variable: data
  //Data bytes (up to 8)
  rand bit [7:0] data[8];

  //Variable: crc
  //Observed CRC-15
  bit [14:0] crc;

  //Variable: ack
  //Acknowledge slot was dominant
  bit ack;

  //Variable: error_type
  //Error detected while observing this frame
  can_error_type_e error_type;

  //-------------------------------------------------------
  // Constraints
  //-------------------------------------------------------
  constraint dlc_c { dlc inside {[0:8]}; }
  constraint std_id_c { (ide == STANDARD_FRAME) -> id[28:11] == 0; }

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "can_sequence_item");
 
endclass : can_sequence_item

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - can_sequence_item
//--------------------------------------------------------------------------------------------
function can_sequence_item::new(string name = "can_sequence_item");
  super.new(name);
endfunction : new

`endif
