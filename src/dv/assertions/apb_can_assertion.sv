`ifndef APB_CAN_ASSERTION_INCLUDED_
`define APB_CAN_ASSERTION_INCLUDED_

//--------------------------------------------------------------------------------------------
// Module : apb_can_assertion
//  Protocol and spec assertions on the APB and CAN pins of one DUT node
//--------------------------------------------------------------------------------------------
module apb_can_assertion (
  // APB side (pclk domain)
  input logic        pclk,
  input logic        p_rst_n,
  input logic        psel,
  input logic        penable,
  input logic        pwrite,
  input logic [11:0] paddr,
  input logic [31:0] pwdata,
  input logic [3:0]  pstrb,
  input logic [31:0] prdata,
  input logic        pready,
  input logic        pslverr,
  // CAN side (can_clk domain)
  input logic        can_clk,
  input logic        can_rst_n,
  input logic        can_tx,
  input logic        can_rx
);

  //-------------------------------------------------------
  // Importing uvm package and Including uvm macros file
  //-------------------------------------------------------
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  //-------------------------------------------------------
  // Property : penable_after_psel_p
  //  PENABLE is asserted one cycle after PSEL (setup -> access)
  //-------------------------------------------------------
  property penable_after_psel_p;
    @(posedge pclk) disable iff (!p_rst_n)
      (psel && !penable) |=> (psel && penable);
  endproperty : penable_after_psel_p

  PENABLE_AFTER_PSEL_A : assert property (penable_after_psel_p)
    else `uvm_error("APB_CAN_ASSERTION", "PENABLE not asserted in the cycle after setup phase")

  //-------------------------------------------------------
  // Property : pready_always_high_p
  //  Spec Section 3: PREADY is always driven 1'b1 (no wait states)
  //-------------------------------------------------------
  property pready_always_high_p;
    @(posedge pclk) disable iff (!p_rst_n)
      (psel && penable) |-> pready;
  endproperty : pready_always_high_p

  PREADY_ALWAYS_HIGH_A : assert property (pready_always_high_p)
    else `uvm_error("APB_CAN_ASSERTION", "PREADY deasserted during access phase")

  //-------------------------------------------------------
  // Property : can_tx_recessive_in_reset_p
  //  Spec Section 3: can_tx is recessive (1) while the CAN domain is in reset
  //-------------------------------------------------------
  property can_tx_recessive_in_reset_p;
    @(posedge can_clk) (!can_rst_n) |-> can_tx;
  endproperty : can_tx_recessive_in_reset_p

  CAN_TX_RECESSIVE_IN_RESET_A : assert property (can_tx_recessive_in_reset_p)
    else `uvm_error("APB_CAN_ASSERTION", "can_tx not recessive during reset")

  // TODO: add PSLVERR, address-stability, LISTEN_ONLY and bus-off assertions

endmodule : apb_can_assertion

`endif
