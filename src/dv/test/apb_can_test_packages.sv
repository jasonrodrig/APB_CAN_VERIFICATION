`ifndef APB_CAN_TEST_PACKAGES_INCLUDED_
`define APB_CAN_TEST_PACKAGES_INCLUDED_

//--------------------------------------------------------------------------------------------
// Package : apb_can_test_packages
//  Includes all the APB CAN tests
//--------------------------------------------------------------------------------------------
package apb_can_test_packages;

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
  import apb_can_sequence_packages::*;
  import apb_can_packages::*;
  import apb_can_virtual_sequence_packages::*;

  //-------------------------------------------------------
  // Include all other files
  //-------------------------------------------------------
  `include "define.sv"
  `include "apb_can_ral_report_catcher.sv"
  `include "apb_can_base_test.sv"
  `include "apb_can_reg_access_test.sv"
  `include "apb_can_loopback_test.sv"

endpackage : apb_can_test_packages

`endif
