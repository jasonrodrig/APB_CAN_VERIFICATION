`ifndef STUB_CAN_CONTROLLER_TOP_INCLUDED_
`define STUB_CAN_CONTROLLER_TOP_INCLUDED_

//--------------------------------------------------------------------------------------------
// Module      : can_controller_top  (SIMULATION STUB - NOT THE REAL RTL)
// Description : Stand-in for the CAN 2.0B controller, used only to run the testbench while
//               src/rtl/ is empty. Compiled only with: make compile stub=1
//               - Same ports and parameters as can_controller_top (spec Section 3)
//               - 27 plain 32-bit registers at 0x000..0x068, word aligned
//               - Writes are stored and reads return the stored value; VERSION (0x000) is
//                 read-only and resets to STUB_VERSION
//               - PREADY = 1, PSLVERR = 0, can_tx always recessive (no CAN protocol logic)
//               - Every APB write prints the receiving instance path, so per-node
//                 traffic can be checked in the simulation log
//--------------------------------------------------------------------------------------------
module can_controller_top #(
  parameter int CAN_CLK_FREQ = 100000000,
  parameter int CAN_BIT_RATE = 1000000,
  parameter int FIFO_DEPTH   = 8
) (
  input  logic        pclk,
  input  logic        p_rst_n,
  input  logic        can_clk,
  input  logic        can_rst_n,
  input  logic [11:0] PADDR,
  input  logic        PSEL,
  input  logic        PENABLE,
  input  logic        PWRITE,
  input  logic [31:0] PWDATA,
  input  logic [3:0]  PSTRB,
  output logic [31:0] PRDATA,
  output logic        PREADY,
  output logic        PSLVERR,
  input  logic        can_rx,
  output logic        can_tx
);

  //Parameter : NO_OF_REGS
  //Number of registers in the CAN register map (0x000..0x068)
  localparam int NO_OF_REGS = 27;

  //Parameter : STUB_VERSION
  //Reset value returned by the VERSION register
  localparam logic [31:0] STUB_VERSION = 32'h0002_0000;

  //Variable : regs
  //Register storage, indexed by PADDR[11:2]
  logic [31:0] regs [NO_OF_REGS];

  //Variable : reg_index
  //Word index of the addressed register
  logic [9:0] reg_index;

  assign reg_index = PADDR[11:2];

  //-------------------------------------------------------
  // Register write
  //-------------------------------------------------------
  always_ff @(posedge pclk or negedge p_rst_n) begin
    if(!p_rst_n) begin
      foreach(regs[i]) regs[i] <= (i == 0) ? STUB_VERSION : 32'h0;
    end
    else if(PSEL && PENABLE && PWRITE && reg_index != 0 && reg_index < NO_OF_REGS) begin
      regs[reg_index] <= PWDATA;
      $display("[STUB] %t : %m : APB write addr = 'h%03h data = 'h%0h", $time, PADDR, PWDATA);
    end
  end

  //-------------------------------------------------------
  // Register read and APB responses
  //-------------------------------------------------------
  assign PRDATA  = (reg_index < NO_OF_REGS) ? regs[reg_index] : 32'h0;
  assign PREADY  = 1'b1;
  assign PSLVERR = 1'b0;

  //-------------------------------------------------------
  // CAN side: always recessive
  //-------------------------------------------------------
  assign can_tx = 1'b1;

endmodule : can_controller_top

`endif
