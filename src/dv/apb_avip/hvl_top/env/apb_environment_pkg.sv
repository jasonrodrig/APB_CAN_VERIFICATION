`ifndef APB_ENVIRONMENT_PKG_INCLUDED_
`define APB_ENVIRONMENT_PKG_INCLUDED_

//--------------------------------------------------------------------------------------------
// Package: apb_environment_pkg
//  Includes the APB environment (APB_ENVIRONMENT inside APB_HVL_AVIP)
//--------------------------------------------------------------------------------------------
package apb_environment_pkg;

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

  //-------------------------------------------------------
  // Include all other files
  //-------------------------------------------------------
  `include "apb_environment.sv"

endpackage : apb_environment_pkg

`endif
