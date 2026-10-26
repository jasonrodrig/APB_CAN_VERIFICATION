`ifndef CAN_INTERFACE_INCLUDED_
`define CAN_INTERFACE_INCLUDED_

//--------------------------------------------------------------------------------------------
// Interface : can_interface
//  Declaration of pin level signals on the CAN side of one DUT node
//--------------------------------------------------------------------------------------------
interface can_interface (input bit can_clk, input bit can_rst_n);

  //Variable : can_tx
  //Serial CAN transmit line driven by the DUT (recessive = 1)
  logic can_tx;

  //Variable : can_rx
  //Serial CAN receive line seen by the DUT (resolved CAN bus value)
  logic can_rx;

  //-------------------------------------------------------
  // Clocking block : mon_cb
  //  Sampling of CAN lines by the passive monitor
  //-------------------------------------------------------
  clocking mon_cb @(posedge can_clk);
    default input #1step;
    input can_tx;
    input can_rx;
  endclocking : mon_cb

  //-------------------------------------------------------
  // Modport : MON_MP
  //  Monitor modport used by can_passive_monitor
  //-------------------------------------------------------
  modport MON_MP (clocking mon_cb, input can_clk, input can_rst_n);

endinterface : can_interface

`endif
