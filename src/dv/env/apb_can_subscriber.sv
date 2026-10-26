`ifndef APB_CAN_SUBSCRIBER_INCLUDED_
`define APB_CAN_SUBSCRIBER_INCLUDED_

//--------------------------------------------------------------------------------------------
// Analysis imp declarations used by apb_can_subscriber
//--------------------------------------------------------------------------------------------
`uvm_analysis_imp_decl(_apb)
`uvm_analysis_imp_decl(_can)

//--------------------------------------------------------------------------------------------
// Class: apb_can_subscriber
//  Functional coverage collector for one node; samples APB register accesses and CAN frames
//--------------------------------------------------------------------------------------------
class apb_can_subscriber extends uvm_component;
  `uvm_component_utils(apb_can_subscriber)

  //Variable: node_id
  //Index of the CAN node covered by this subscriber
  int node_id;

  //Variable: apb_analysis_imp
  //Receives APB transactions from apb_master_monitor_proxy
  uvm_analysis_imp_apb #(apb_master_tx, apb_can_subscriber) apb_analysis_imp;

  //Variable: can_analysis_imp
  //Receives CAN frames from can_passive_monitor
  uvm_analysis_imp_can #(can_sequence_item, apb_can_subscriber) can_analysis_imp;

  //Variable: apb_tx_h
  //Last sampled APB transaction
  apb_master_tx apb_tx_h;

  //Variable: can_item_h
  //Last sampled CAN frame
  can_sequence_item can_item_h;

  //-------------------------------------------------------
  // Covergroup: can_frame_cg
  //  Coverage of CAN frame attributes
  //-------------------------------------------------------
  covergroup can_frame_cg;
    option.per_instance = 1;
    IDE_CP : coverpoint can_item_h.ide;
    RTR_CP : coverpoint can_item_h.rtr;
    DLC_CP : coverpoint can_item_h.dlc { bins dlc[] = {[0:8]}; }
    // TODO: add error type / cross coverage
  endgroup : can_frame_cg

  //-------------------------------------------------------
  // Covergroup: apb_access_cg
  //  Coverage of APB register accesses
  //-------------------------------------------------------
  covergroup apb_access_cg;
    option.per_instance = 1;
    PWRITE_CP : coverpoint apb_tx_h.pwrite;
    // TODO: add register address / pslverr coverage
  endgroup : apb_access_cg

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "apb_can_subscriber", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void write_apb(apb_master_tx t);
  extern virtual function void write_can(can_sequence_item t);
  extern virtual function void report_phase(uvm_phase phase);

endclass : apb_can_subscriber

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - apb_can_subscriber
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function apb_can_subscriber::new(string name = "apb_can_subscriber", uvm_component parent = null);
  super.new(name, parent);
  can_frame_cg  = new();
  apb_access_cg = new();
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//  Creates the analysis imps
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void apb_can_subscriber::build_phase(uvm_phase phase);
  super.build_phase(phase);
  apb_analysis_imp = new("apb_analysis_imp", this);
  can_analysis_imp = new("can_analysis_imp", this);
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: write_apb
//  Samples APB coverage
//
// Parameters:
//  t - apb_master_tx
//--------------------------------------------------------------------------------------------
function void apb_can_subscriber::write_apb(apb_master_tx t);
  apb_tx_h = t;
  apb_access_cg.sample();
endfunction : write_apb

//--------------------------------------------------------------------------------------------
// Function: write_can
//  Samples CAN coverage
//
// Parameters:
//  t - can_sequence_item
//--------------------------------------------------------------------------------------------
function void apb_can_subscriber::write_can(can_sequence_item t);
  can_item_h = t;
  can_frame_cg.sample();
endfunction : write_can

//--------------------------------------------------------------------------------------------
// Function: report_phase
//  Reports coverage
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void apb_can_subscriber::report_phase(uvm_phase phase);
  super.report_phase(phase);
  `uvm_info(get_type_name(), $sformatf("Node[%0d] CAN frame coverage = %0.2f %%, APB access coverage = %0.2f %%",
                                       node_id, can_frame_cg.get_inst_coverage(), apb_access_cg.get_inst_coverage()), UVM_LOW)
endfunction : report_phase

`endif
