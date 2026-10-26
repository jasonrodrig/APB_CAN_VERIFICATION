`ifndef CAN_PASSIVE_PACKAGES_INCLUDED_
`define CAN_PASSIVE_PACKAGES_INCLUDED_

//--------------------------------------------------------------------------------------------
// Package : can_passive_packages
//  Includes all the files related to the CAN passive agent
//--------------------------------------------------------------------------------------------
package can_passive_packages;

  //-------------------------------------------------------
  // Import uvm package
  //-------------------------------------------------------
  `include "uvm_macros.svh"
  import uvm_pkg::*;

  //-------------------------------------------------------
  // Import CAN packages
  //-------------------------------------------------------
  import typedef_enum_packages::*;
  import can_sequence_item_packages::*;

  //-------------------------------------------------------
  // Include all other files
  //-------------------------------------------------------
  `include "can_passive_monitor.sv"
  `include "can_passive_agent.sv"

endpackage : can_passive_packages

`endif
