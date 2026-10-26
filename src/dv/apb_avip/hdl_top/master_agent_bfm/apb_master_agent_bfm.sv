`ifndef APB_MASTER_AGENT_BFM_INCLUDED_
`define APB_MASTER_AGENT_BFM_INCLUDED_

//--------------------------------------------------------------------------------------------
// Module      : APB Master Agent BFM
// Description : Instantiates driver and monitor
//
// Parameters:
//  NODE_ID - Index of the APB master agent that uses these BFMs. -1 (default) publishes the
//            BFMs with scope "*" (single agent). NODE_ID >= 0 publishes them only to
//            "*apb_master_agent_h[NODE_ID]*", so several instances can coexist
//--------------------------------------------------------------------------------------------
module apb_master_agent_bfm #(parameter int NODE_ID = -1) (apb_if intf);

  //-------------------------------------------------------
  // Importing uvm package file
  //-------------------------------------------------------
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  
  initial begin
    `uvm_info("apb master agent bfm",$sformatf("APB MASTER AGENT BFM"),UVM_LOW);
  end
  
  //-------------------------------------------------------
  // master driver bfm instantiation
  //-------------------------------------------------------
  apb_master_driver_bfm apb_master_drv_bfm_h (.pclk(intf.pclk),
                                              .preset_n(intf.preset_n),
                                              .pselx(intf.pselx),
                                              .penable(intf.penable),
                                              .pprot(intf.pprot),
                                              .paddr(intf.paddr),
                                              .pwrite(intf.pwrite),
                                              .pwdata(intf.pwdata),
                                              .pstrb(intf.pstrb),
                                              .pslverr(intf.pslverr),
                                              .pready(intf.pready),
                                              .prdata(intf.prdata)
                                              );

  //-------------------------------------------------------
  // master monitor bfm instantiation
  //-------------------------------------------------------
  apb_master_monitor_bfm apb_master_mon_bfm_h (.pclk(intf.pclk),
                                              .preset_n(intf.preset_n),
                                              .pselx(intf.pselx),
                                              .paddr(intf.paddr),
                                              .pwrite(intf.pwrite),
                                              .pwdata(intf.pwdata),
                                              .pstrb(intf.pstrb),
                                              .pslverr(intf.pslverr),
                                              .pready(intf.pready),
                                              .prdata(intf.prdata),
                                              .penable(intf.penable),
                                              .pprot(intf.pprot)
                                              );


  //-------------------------------------------------------
  // setting the virtual handle of BFMs into config_db
  //-------------------------------------------------------
  initial begin
    string bfm_scope;

    bfm_scope = (NODE_ID < 0) ? "*" : $sformatf("*apb_master_agent_h[%0d]*", NODE_ID);

    uvm_config_db#(virtual apb_master_driver_bfm)::set(null,bfm_scope,"apb_master_driver_bfm",apb_master_drv_bfm_h);
    uvm_config_db#(virtual apb_master_monitor_bfm)::set(null,bfm_scope,"apb_master_monitor_bfm",apb_master_mon_bfm_h);
  end

endmodule : apb_master_agent_bfm

`endif

