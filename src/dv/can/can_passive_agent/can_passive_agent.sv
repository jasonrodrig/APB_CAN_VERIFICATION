`ifndef CAN_PASSIVE_AGENT_INCLUDED_
`define CAN_PASSIVE_AGENT_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: can_passive_agent
//  Passive agent observing one CAN node; contains only the can_passive_monitor
//--------------------------------------------------------------------------------------------
class can_passive_agent extends uvm_agent;
  `uvm_component_utils(can_passive_agent)

  //Variable: node_id
  //Index of the CAN node observed by this agent
  int node_id;

  //Variable: can_passive_mon_h
  //Handle for the CAN passive monitor
  can_passive_monitor can_passive_mon_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "can_passive_agent", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);

endclass : can_passive_agent

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - can_passive_agent
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function can_passive_agent::new(string name = "can_passive_agent", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//  Creates the passive monitor
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void can_passive_agent::build_phase(uvm_phase phase);
  super.build_phase(phase);
  is_active = UVM_PASSIVE;
  can_passive_mon_h = can_passive_monitor::type_id::create("can_passive_mon_h", this);
  can_passive_mon_h.node_id = node_id;
endfunction : build_phase

`endif
