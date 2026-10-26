`ifndef TYPEDEF_ENUM_PACKAGES_INCLUDED_
`define TYPEDEF_ENUM_PACKAGES_INCLUDED_

//--------------------------------------------------------------------------------------------
// Package : typedef_enum_packages
//  Used for storing CAN related enums and typedefs
//--------------------------------------------------------------------------------------------
package typedef_enum_packages;

  //-------------------------------------------------------
  // Enum : can_frame_format_e
  //  Standard (11-bit ID) or extended (29-bit ID) frame
  //-------------------------------------------------------
  typedef enum bit {
    STANDARD_FRAME = 1'b0,
    EXTENDED_FRAME = 1'b1
  } can_frame_format_e;

  //-------------------------------------------------------
  // Enum : can_frame_type_e
  //  Data frame or remote frame (RTR)
  //-------------------------------------------------------
  typedef enum bit {
    DATA_FRAME   = 1'b0,
    REMOTE_FRAME = 1'b1
  } can_frame_type_e;

  //-------------------------------------------------------
  // Enum : can_error_type_e
  //  Error detected on the CAN bus
  //-------------------------------------------------------
  typedef enum bit [2:0] {
    NO_CAN_ERROR = 3'd0,
    BIT_ERROR    = 3'd1,
    STUFF_ERROR  = 3'd2,
    CRC_ERROR    = 3'd3,
    FORM_ERROR   = 3'd4,
    ACK_ERROR    = 3'd5
  } can_error_type_e;

  //-------------------------------------------------------
  // Enum : can_fault_state_e
  //  Fault confinement state of a node
  //-------------------------------------------------------
  typedef enum bit [1:0] {
    ERROR_ACTIVE  = 2'd0,
    ERROR_PASSIVE = 2'd1,
    BUS_OFF       = 2'd2
  } can_fault_state_e;

endpackage : typedef_enum_packages

`endif
