`ifndef APB_CAN_SCOREBOARD_INCLUDED_
`define APB_CAN_SCOREBOARD_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: apb_can_scoreboard
//  Compares APB register traffic (TX/RX registers) of one node against the CAN frames
//  observed on the CAN bus by the passive monitor
//--------------------------------------------------------------------------------------------
class apb_can_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(apb_can_scoreboard)

  //Variable: node_id
  //Index of the CAN node checked by this scoreboard
  int node_id;

  //Variable: apb_master_analysis_fifo
  //Receives APB transactions from apb_master_monitor_proxy
  uvm_tlm_analysis_fifo #(apb_master_tx) apb_master_analysis_fifo;

  //Variable: can_analysis_fifo
  //Receives CAN frames from can_passive_monitor
  uvm_tlm_analysis_fifo #(can_sequence_item) can_analysis_fifo;

  //Variable: can_reg_block_h
  //Register model of this node, used as reference for expected values
  can_reg_block can_reg_block_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "apb_can_scoreboard", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual function void check_phase(uvm_phase phase);
  extern virtual function void report_phase(uvm_phase phase);

endclass : apb_can_scoreboard

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - apb_can_scoreboard
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function apb_can_scoreboard::new(string name = "apb_can_scoreboard", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//  Creates the analysis fifos
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void apb_can_scoreboard::build_phase(uvm_phase phase);
  super.build_phase(phase);
  apb_master_analysis_fifo = new("apb_master_analysis_fifo", this);
  can_analysis_fifo        = new("can_analysis_fifo", this);
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
//  Builds expected CAN frames from APB TX register writes and compares them with observed
//  frames; checks RX register reads against received frames
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task apb_can_scoreboard::run_phase(uvm_phase phase);
  apb_master_tx     apb_tx_h;
  can_sequence_item can_item_h;

  fork
    forever begin
      apb_master_analysis_fifo.get(apb_tx_h);
      // TODO: decode APB access (TX_ID/TX_CTRL/TX_DATA/TX_COMMAND, RX_* reads) into expectations
    end
    forever begin
      can_analysis_fifo.get(can_item_h);
      // TODO: compare observed frame against expected frame
    end
  join
endtask : run_phase

//--------------------------------------------------------------------------------------------
// Function: check_phase
//  Checks that no expected transactions are left pending
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void apb_can_scoreboard::check_phase(uvm_phase phase);
  super.check_phase(phase);
  // TODO: check pending expectations / fifo emptiness
endfunction : check_phase

//--------------------------------------------------------------------------------------------
// Function: report_phase
//  Reports pass/fail counts
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void apb_can_scoreboard::report_phase(uvm_phase phase);
  super.report_phase(phase);
  // TODO: report match/mismatch counts
endfunction : report_phase

`endif
