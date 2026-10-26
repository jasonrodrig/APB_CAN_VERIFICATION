`ifndef APB_CAN_PACKAGES_INCLUDED_
`define APB_CAN_PACKAGES_INCLUDED_

//--------------------------------------------------------------------------------------------
// Package : apb_can_packages
//  Includes all the files related to the APB CAN environment
//--------------------------------------------------------------------------------------------
package apb_can_packages;

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
  import apb_environment_pkg::*;
  import can_reg_pkg::*;
  import typedef_enum_packages::*;
  import can_sequence_item_packages::*;
  import can_passive_packages::*;

  //-------------------------------------------------------
  // Include all other files
  //-------------------------------------------------------
  `include "define.sv"
  `include "apb_can_report_server.sv"
  `include "apb_can_virtual_sequencer.sv"
  `include "apb_can_scoreboard.sv"
  `include "apb_can_subscriber.sv"
  `include "apb_can_environment.sv"

endpackage : apb_can_packages

`endif
