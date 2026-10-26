`ifndef APB_CAN_SEQUENCE_PACKAGES_INCLUDED_
`define APB_CAN_SEQUENCE_PACKAGES_INCLUDED_

//--------------------------------------------------------------------------------------------
// Package : apb_can_sequence_packages
//  Includes all the APB CAN register sequences
//--------------------------------------------------------------------------------------------
package apb_can_sequence_packages;

  //-------------------------------------------------------
  // Import uvm package
  //-------------------------------------------------------
  `include "uvm_macros.svh"
  import uvm_pkg::*;

  //-------------------------------------------------------
  // Import required packages
  //-------------------------------------------------------
  import apb_global_pkg::*;
  import apb_master_pkg::*;
  import can_reg_pkg::*;
  import apb_can_packages::*;

  //-------------------------------------------------------
  // Include all other files
  //-------------------------------------------------------
  `include "apb_can_base_sequence.sv"
  `include "apb_can_reg_access_sequence.sv"
  `include "apb_can_loopback_sequence.sv"

endpackage : apb_can_sequence_packages

`endif
