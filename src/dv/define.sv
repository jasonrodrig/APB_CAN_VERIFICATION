`ifndef DEFINE_INCLUDED_
`define DEFINE_INCLUDED_

//--------------------------------------------------------------------------------------------
// File : define.sv
//  Global testbench defines for the APB CAN bridge verification environment
//--------------------------------------------------------------------------------------------

//Define : NO_OF_NODES
//Number of CAN nodes (DUT instances) connected on the CAN bus
//Can be overridden at compile time: +define+NO_OF_NODES=<n>  (Makefile: nodes=<n>)
`ifndef NO_OF_NODES
`define NO_OF_NODES 3
`endif

//Define : PCLK_PERIOD
//APB clock period in ns (50 MHz typical, spec Section 4)
`define PCLK_PERIOD 20

//Define : CAN_CLK_PERIOD
//CAN protocol-engine clock period in ns (100 MHz nominal, spec Section 9)
`define CAN_CLK_PERIOD 10

//Define : CAN_APB_ADDR_WIDTH
//Width of the DUT APB address bus (PADDR[11:0])
`define CAN_APB_ADDR_WIDTH 12

//Define : CAN_APB_DATA_WIDTH
//Width of the DUT APB data bus (PWDATA/PRDATA[31:0])
`define CAN_APB_DATA_WIDTH 32

//Define : CAN_FIFO_DEPTH
//Depth of the DUT RX FIFO (DUT parameter FIFO_DEPTH)
`define CAN_FIFO_DEPTH 8

`endif
