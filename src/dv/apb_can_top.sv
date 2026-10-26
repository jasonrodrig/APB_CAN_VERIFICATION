`ifndef APB_CAN_TOP_INCLUDED_
`define APB_CAN_TOP_INCLUDED_

//--------------------------------------------------------------------------------------------
// Module      : apb_can_top
// Description : Testbench top. Generates clocks/resets and, per node, instantiates the APB
//               interface + APB master agent BFM (APB_HDL_AVIP), the CAN interface, the DUT
//               (can_controller_top) and the assertion module. All nodes share one wired-AND
//               CAN bus. Starts the UVM test.
//--------------------------------------------------------------------------------------------
module apb_can_top;

  //-------------------------------------------------------
  // Importing uvm package and Including uvm macros file
  //-------------------------------------------------------
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  //-------------------------------------------------------
  // Importing packages
  //-------------------------------------------------------
  import apb_global_pkg::*;
  import apb_can_test_packages::*;

  //Variable : pclk
  //APB clock
  bit pclk;

  //Variable : p_rst_n
  //APB domain active-low reset
  bit p_rst_n;

  //Variable : can_clk
  //CAN protocol-engine clock
  bit can_clk;

  //Variable : can_rst_n
  //CAN domain active-low reset
  bit can_rst_n;

  //Variable : can_tx_bus
  //can_tx of every node
  logic [`NO_OF_NODES-1:0] can_tx_bus;

  //Variable : can_loopback_bus
  //CONTROL.loopback of every node; a node with loopback = 1 is disconnected from the CAN bus
  logic [`NO_OF_NODES-1:0] can_loopback_bus;

  //Variable : can_rx_bus
  //can_rx of every node (bus level, or its own can_tx when in loopback)
  logic [`NO_OF_NODES-1:0] can_rx_bus;

  //Variable : can_bus_line
  //Resolved CAN bus level (wired-AND, dominant = 0)
  wire can_bus_line;

  //-------------------------------------------------------
  // Clock generation
  //-------------------------------------------------------
  initial begin
    pclk = 1'b0;
    forever #(`PCLK_PERIOD/2) pclk = !pclk;
  end

  initial begin
    can_clk = 1'b0;
    forever #(`CAN_CLK_PERIOD/2) can_clk = !can_clk;
  end

  //-------------------------------------------------------
  // Reset generation
  //  Both domains are reset together (spec Section 4).
  //  Resets start de-asserted and are then asserted, because the APB AVIP BFMs
  //  (wait_for_preset_n) wait for a negedge followed by a posedge of preset_n.
  //-------------------------------------------------------
  initial begin
    p_rst_n   = 1'b1;
    can_rst_n = 1'b1;
    #15;
    p_rst_n   = 1'b0;
    can_rst_n = 1'b0;
    repeat(5) @(posedge pclk);
    p_rst_n   = 1'b1;
    @(posedge can_clk);
    can_rst_n = 1'b1;
  end

  //-------------------------------------------------------
  // CAN bus resolution (wired-AND, see can_bus.sv)
  //-------------------------------------------------------
  can_bus #(
    .NO_OF_NODES (`NO_OF_NODES)
  ) can_bus_h (
    .can_tx        (can_tx_bus),
    .node_loopback (can_loopback_bus),
    .can_rx        (can_rx_bus),
    .can_bus       (can_bus_line)
  );

  //-------------------------------------------------------
  // Per node instantiation
  //-------------------------------------------------------
  genvar i;
  generate
    for(i = 0; i < `NO_OF_NODES; i++) begin : node

      //-------------------------------------------------------
      // APB Interface and APB Master Agent BFM (APB AVIP)
      //-------------------------------------------------------
      apb_if apb_intf(pclk, p_rst_n);
      // NODE_ID scopes this node's BFMs in config_db to apb_master_agent_h[i] only
      apb_master_agent_bfm #(.NODE_ID(i)) apb_master_agent_bfm_h(apb_intf);

      //-------------------------------------------------------
      // CAN Interface
      //-------------------------------------------------------
      can_interface can_intf(can_clk, can_rst_n);

      assign can_tx_bus[i]   = can_intf.can_tx;
      assign can_intf.can_rx = can_rx_bus[i];

      initial begin
        uvm_config_db #(virtual can_interface)::set(null, "*", $sformatf("can_vif[%0d]", i), can_intf);
      end

      //-------------------------------------------------------
      // Loopback detection
      //  Snoops the APB writes of this node to CONTROL (0x004) and keeps a copy of the
      //  loopback bit [1]. It is decoded from the APB pins, so it works with the RTL and
      //  the stub. The can_bus uses it to disconnect this node from the bus and loop its
      //  can_tx back to its own can_rx.
      //-------------------------------------------------------
      localparam int CONTROL_LOOPBACK_BIT = 1;

      //Variable : loopback_en
      //1 = this node is in loopback mode
      logic loopback_en;

      always_ff @(posedge pclk or negedge p_rst_n) begin
        if(!p_rst_n) begin
          loopback_en <= 1'b0;
        end
        else if(apb_intf.pselx[0] && apb_intf.penable && apb_intf.pready && apb_intf.pwrite &&
                apb_intf.pstrb[0] &&
                apb_intf.paddr[`CAN_APB_ADDR_WIDTH-1:0] == can_reg_pkg::CAN_ADDR_CONTROL) begin
          loopback_en <= apb_intf.pwdata[CONTROL_LOOPBACK_BIT];
        end
      end

      assign can_loopback_bus[i] = loopback_en;

      always @(loopback_en) begin
        if(p_rst_n) begin
          $display("[TB] %t : node[%0d] loopback = %0b : node %s", $time, i, loopback_en,
                   loopback_en ? "disconnected from the CAN bus, can_tx looped back to can_rx" : "connected to the CAN bus");
        end
      end

      //-------------------------------------------------------
      // DUT : CAN 2.0B controller (RTL in src/rtl)
      //-------------------------------------------------------
      can_controller_top #(
        .FIFO_DEPTH (`CAN_FIFO_DEPTH)
      ) dut (
        .pclk      (pclk),
        .p_rst_n   (p_rst_n),
        .can_clk   (can_clk),
        .can_rst_n (can_rst_n),
        .PADDR     (apb_intf.paddr[`CAN_APB_ADDR_WIDTH-1:0]),
        .PSEL      (apb_intf.pselx[0]),
        .PENABLE   (apb_intf.penable),
        .PWRITE    (apb_intf.pwrite),
        .PWDATA    (apb_intf.pwdata),
        .PSTRB     (apb_intf.pstrb),
        .PRDATA    (apb_intf.prdata),
        .PREADY    (apb_intf.pready),
        .PSLVERR   (apb_intf.pslverr),
        .can_rx    (can_intf.can_rx),
        .can_tx    (can_intf.can_tx)
      );

      //-------------------------------------------------------
      // Assertions
      //-------------------------------------------------------
      apb_can_assertion apb_can_assertion_h (
        .pclk      (pclk),
        .p_rst_n   (p_rst_n),
        .psel      (apb_intf.pselx[0]),
        .penable   (apb_intf.penable),
        .pwrite    (apb_intf.pwrite),
        .paddr     (apb_intf.paddr[`CAN_APB_ADDR_WIDTH-1:0]),
        .pwdata    (apb_intf.pwdata),
        .pstrb     (apb_intf.pstrb),
        .prdata    (apb_intf.prdata),
        .pready    (apb_intf.pready),
        .pslverr   (apb_intf.pslverr),
        .can_clk   (can_clk),
        .can_rst_n (can_rst_n),
        .can_tx    (can_intf.can_tx),
        .can_rx    (can_intf.can_rx)
      );

    end : node
  endgenerate

  //-------------------------------------------------------
  // Start the UVM test
  //-------------------------------------------------------
  initial begin
    run_test("apb_can_base_test");
  end

endmodule : apb_can_top

`endif
