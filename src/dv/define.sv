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

`define CAN_ADDR_VERSION 0  // RO
`define CAN_ADDR_CONTROL 4  // RW
`define CAN_ADDR_STATUS  8  // RO
`define CAN_ADDR_ERROR_STATUS 12  // RO
`define CAN_ADDR_BRP 16  // RW
`define CAN_ADDR_SEGMENTS 20  // RW
`define CAN_ADDR_SJW_CONTROL 24  // RW
`define CAN_ADDR_TX_ID 28  // RW
`define CAN_ADDR_TX_CTRL 32  // RW
`define CAN_ADDR_TX_DATA_LO 36  // RW
`define CAN_ADDR_TX_DATA_HI 40  // RW
`define CAN_ADDR_TX_COMMAND 44  // WO
`define CAN_ADDR_TX_STATUS  48  // RO
`define CAN_ADDR_RX_STATUS  52  // RO
`define CAN_ADDR_RX_ID  56  // RO
`define CAN_ADDR_RX_CTRL 60  // RO
`define CAN_ADDR_RX_DATA_LO 64 // RO
`define CAN_ADDR_RX_DATA_HI 68  // RO
`define CAN_ADDR_RX_COMMAND 72  // WO
`define CAN_ADDR_FILTER0_ID 76  // RW
`define CAN_ADDR_FILTER0_MASK 80  // RW
`define CAN_ADDR_FILTER0_CTRL 84  // RW
`define CAN_ADDR_FILTER1_ID 88  // RW
`define CAN_ADDR_FILTER1_MASK 92  // RW
`define CAN_ADDR_FILTER1_CTRL 96  // RW
`define CAN_ADDR_TEC 100  // RO
`define CAN_ADDR_REC 104  // RO

`endif
