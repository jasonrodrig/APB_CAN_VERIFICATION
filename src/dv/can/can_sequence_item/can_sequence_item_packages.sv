`ifndef CAN_SEQUENCE_ITEM_PACKAGES_INCLUDED_
`define CAN_SEQUENCE_ITEM_PACKAGES_INCLUDED_

//--------------------------------------------------------------------------------------------
// Package : can_sequence_item_packages
//  Includes the CAN sequence item
//--------------------------------------------------------------------------------------------
package can_sequence_item_packages;

  //-------------------------------------------------------
  // Import uvm package
  //-------------------------------------------------------
  `include "uvm_macros.svh"
  import uvm_pkg::*;

  //-------------------------------------------------------
  // Import CAN enums and typedefs
  //-------------------------------------------------------
  import typedef_enum_packages::*;

  //-------------------------------------------------------
  // Include all other files
  //-------------------------------------------------------
  `include "can_sequence_item.sv"

endpackage : can_sequence_item_packages

`endif
