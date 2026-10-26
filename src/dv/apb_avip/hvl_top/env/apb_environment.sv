`ifndef APB_ENVIRONMENT_INCLUDED_
`define APB_ENVIRONMENT_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: apb_environment
//  APB_ENVIRONMENT of one node (inside APB_HVL_AVIP). Contains:
//   - apb_master_agent (active)       : sequencer, driver proxy, monitor proxy, agent config
//   - apb_reg2bus_adapter_h           : reg2bus adapter between the register map and the sequencer
//   - apb_predictor_h                 : uvm_reg_predictor fed by the monitor proxy
//   - apb_bus2reg_adapter_h           : bus2reg adapter used by the predictor
//  The register model is not part of this environment; it lives in apb_can_environment
//  (APB_CAN_REG_MODEL[]), which sets the map on the predictor and the sequencer on the map.
//--------------------------------------------------------------------------------------------
class apb_environment extends uvm_env;
  `uvm_component_utils(apb_environment)

  //Variable: node_id
  //Index of the node served by this environment, set by the parent before build
  int node_id;

  //Variable: apb_master_agent_h
  //APB master active agent. Named apb_master_agent_h[node_id] so that the agent config and
  //the NODE_ID scoped BFMs in config_db reach it
  apb_master_agent apb_master_agent_h;

  //Variable: apb_reg2bus_adapter_h
  //Adapter used by the register map to convert register accesses into APB transactions
  apb_master_adapter apb_reg2bus_adapter_h;

  //Variable: apb_bus2reg_adapter_h
  //Adapter used by the predictor to convert observed APB transactions into register accesses
  apb_master_adapter apb_bus2reg_adapter_h;

  //Variable: apb_predictor_h
  //Register predictor, updates the register model from observed APB traffic
  uvm_reg_predictor #(apb_master_tx) apb_predictor_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "apb_environment", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);

endclass : apb_environment

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - apb_environment
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function apb_environment::new(string name = "apb_environment", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//  Creates the master agent, the adapters and the predictor
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void apb_environment::build_phase(uvm_phase phase);
  super.build_phase(phase);

  apb_master_agent_h    = apb_master_agent::type_id::create($sformatf("apb_master_agent_h[%0d]", node_id), this);
  apb_reg2bus_adapter_h = apb_master_adapter::type_id::create("apb_reg2bus_adapter_h");
  apb_bus2reg_adapter_h = apb_master_adapter::type_id::create("apb_bus2reg_adapter_h");
  apb_predictor_h       = uvm_reg_predictor#(apb_master_tx)::type_id::create("apb_predictor_h", this);
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: connect_phase
//  Connects the monitor proxy to the predictor and gives the predictor its bus2reg adapter.
//  The predictor's map is set by apb_can_environment.
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void apb_environment::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  apb_predictor_h.adapter = apb_bus2reg_adapter_h;
  apb_master_agent_h.apb_master_mon_proxy_h.apb_master_analysis_port.connect(apb_predictor_h.bus_in);
endfunction : connect_phase

`endif
