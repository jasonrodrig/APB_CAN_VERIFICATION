`ifndef CAN_PASSIVE_MONITOR_INCLUDED_
`define CAN_PASSIVE_MONITOR_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: can_passive_monitor
//  Samples can_tx/can_rx of one CAN node through can_interface, reconstructs CAN 2.0B frames
//  and broadcasts them on the analysis port
//--------------------------------------------------------------------------------------------
class can_passive_monitor extends uvm_monitor;
  `uvm_component_utils(can_passive_monitor)

  //Variable: node_id
  //Index of the CAN node monitored by this component
  int node_id;

  //Variable: can_vif
  //Virtual interface handle of the monitored CAN node
  virtual can_interface can_vif;

  //Variable: can_analysis_port
  //Broadcasts every observed CAN frame
  uvm_analysis_port #(can_sequence_item) can_analysis_port;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "can_passive_monitor", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task collect_frame(can_sequence_item can_item_h);

endclass : can_passive_monitor

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - can_passive_monitor
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function can_passive_monitor::new(string name = "can_passive_monitor", uvm_component parent = null);
  super.new(name, parent);
  can_analysis_port = new("can_analysis_port", this);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//  Gets the CAN virtual interface from config_db
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void can_passive_monitor::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if(!uvm_config_db #(virtual can_interface)::get(this, "", $sformatf("can_vif[%0d]", node_id), can_vif)) begin
    `uvm_fatal("FATAL_CAN_VIF", $sformatf("Couldn't get can_vif[%0d] from config_db", node_id))
  end
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
//  Waits for reset release, then collects frames forever
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task can_passive_monitor::run_phase(uvm_phase phase);
  can_sequence_item can_item_h;

  wait(can_vif.can_rst_n === 1'b1);

  forever begin
    can_item_h = can_sequence_item::type_id::create("can_item_h");
    can_item_h.node_id = node_id;
    collect_frame(can_item_h);
    can_analysis_port.write(can_item_h);
  end
endtask : run_phase

//--------------------------------------------------------------------------------------------
// Task: collect_frame
//  Detects SOF, samples bits at the sample point, de-stuffs and decodes one frame
//
// Parameters:
//  can_item_h - frame object to be filled
//--------------------------------------------------------------------------------------------
task can_passive_monitor::collect_frame(can_sequence_item can_item_h);
  // TODO: implement bit-timing aware sampling, de-stuffing, field decode and CRC check
  @(can_vif.mon_cb);
endtask : collect_frame

`endif
