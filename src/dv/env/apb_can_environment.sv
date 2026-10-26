`ifndef APB_CAN_ENVIRONMENT_INCLUDED_
`define APB_CAN_ENVIRONMENT_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: apb_can_environment
//  Top level environment of the APB CAN bridge (APB_CAN_ENVIRONMENT). Per node it creates:
//   - APB_CAN_REG_MODEL[]    : can_reg_block (register model of the node's DUT)
//   - APB_ENVIRONMENT[]      : apb_environment (APB master agent, predictor, adapters)
//   - CAN_PASSIVE_AGENT[]    : can_passive_agent
//   - APB_CAN_SCOREBOARD[]   : apb_can_scoreboard
//   - APB_CAN_SUBSCRIBER[]   : apb_can_subscriber
//  and a single apb_can_virtual_sequencer (APB_CAN_VIRTUAL_SEQUENCER).
//  The register model is owned here, not by the APB environment, and is connected to the
//  APB environment of its node: reg2bus through the map's sequencer/adapter and bus2reg
//  through the predictor.
//  One register model instance is needed per node because each DUT has its own APB bus
//  and a register map can only drive one sequencer.
//--------------------------------------------------------------------------------------------
class apb_can_environment extends uvm_env;
  `uvm_component_utils(apb_can_environment)

  //Variable: apb_can_reg_model_h
  //CAN register model of each node (APB_CAN_REG_MODEL[], from ral/can_reg_pkg)
  can_reg_block apb_can_reg_model_h[];

  //Variable: apb_environment_h
  //APB environment of each node (APB_ENVIRONMENT, from APB AVIP)
  apb_environment apb_environment_h[];

  //Variable: can_passive_agent_h
  //CAN passive agent of each node
  can_passive_agent can_passive_agent_h[];

  //Variable: apb_can_scoreboard_h
  //Scoreboard of each node
  apb_can_scoreboard apb_can_scoreboard_h[];

  //Variable: apb_can_subscriber_h
  //Coverage subscriber of each node
  apb_can_subscriber apb_can_subscriber_h[];

  //Variable: apb_can_virtual_seqr_h
  //Virtual sequencer
  apb_can_virtual_sequencer apb_can_virtual_seqr_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "apb_can_environment", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);

endclass : apb_can_environment

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - apb_can_environment
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function apb_can_environment::new(string name = "apb_can_environment", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//  Creates register models, APB environments, CAN agents, scoreboards, subscribers and the
//  virtual sequencer
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void apb_can_environment::build_phase(uvm_phase phase);
  super.build_phase(phase);

  apb_can_reg_model_h  = new[`NO_OF_NODES];
  apb_environment_h    = new[`NO_OF_NODES];
  can_passive_agent_h  = new[`NO_OF_NODES];
  apb_can_scoreboard_h = new[`NO_OF_NODES];
  apb_can_subscriber_h = new[`NO_OF_NODES];

  for(int i = 0; i < `NO_OF_NODES; i++) begin
    // Register model
    apb_can_reg_model_h[i] = can_reg_block::type_id::create($sformatf("apb_can_reg_model_h[%0d]", i));
    apb_can_reg_model_h[i].build();

    // APB side
    apb_environment_h[i] = apb_environment::type_id::create($sformatf("apb_environment_h[%0d]", i), this);
    apb_environment_h[i].node_id = i;

    // CAN side
    can_passive_agent_h[i] = can_passive_agent::type_id::create($sformatf("can_passive_agent_h[%0d]", i), this);
    can_passive_agent_h[i].node_id = i;

    // Checking and coverage
    apb_can_scoreboard_h[i] = apb_can_scoreboard::type_id::create($sformatf("apb_can_scoreboard_h[%0d]", i), this);
    apb_can_scoreboard_h[i].node_id = i;
    apb_can_scoreboard_h[i].can_reg_block_h = apb_can_reg_model_h[i];

    apb_can_subscriber_h[i] = apb_can_subscriber::type_id::create($sformatf("apb_can_subscriber_h[%0d]", i), this);
    apb_can_subscriber_h[i].node_id = i;
  end

  apb_can_virtual_seqr_h = apb_can_virtual_sequencer::type_id::create("apb_can_virtual_seqr_h", this);
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: connect_phase
//  - APB_CAN_REG_MODEL[] <-> APB_ENVIRONMENT[] : reg2bus (map -> sequencer via reg2bus adapter)
//                                                bus2reg (predictor -> map)
//  - APB monitor proxy   -> scoreboard, subscriber
//  - CAN passive monitor -> scoreboard, subscriber
//  - Sequencer / register model handles -> virtual sequencer
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void apb_can_environment::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  for(int i = 0; i < `NO_OF_NODES; i++) begin
    // reg2bus path
    apb_can_reg_model_h[i].default_map.set_sequencer(apb_environment_h[i].apb_master_agent_h.apb_master_seqr_h,
                                                     apb_environment_h[i].apb_reg2bus_adapter_h);
    apb_can_reg_model_h[i].default_map.set_auto_predict(0);

    // bus2reg path
    apb_environment_h[i].apb_predictor_h.map = apb_can_reg_model_h[i].default_map;

    // Scoreboard
    apb_environment_h[i].apb_master_agent_h.apb_master_mon_proxy_h.apb_master_analysis_port.connect(
                                                apb_can_scoreboard_h[i].apb_master_analysis_fifo.analysis_export);
    can_passive_agent_h[i].can_passive_mon_h.can_analysis_port.connect(
                                                apb_can_scoreboard_h[i].can_analysis_fifo.analysis_export);

    // Subscriber
    apb_environment_h[i].apb_master_agent_h.apb_master_mon_proxy_h.apb_master_analysis_port.connect(
                                                apb_can_subscriber_h[i].apb_analysis_imp);
    can_passive_agent_h[i].can_passive_mon_h.can_analysis_port.connect(apb_can_subscriber_h[i].can_analysis_imp);

    // Virtual sequencer
    apb_can_virtual_seqr_h.apb_master_seqr_h[i]   = apb_environment_h[i].apb_master_agent_h.apb_master_seqr_h;
    apb_can_virtual_seqr_h.apb_can_reg_model_h[i] = apb_can_reg_model_h[i];
  end
endfunction : connect_phase

`endif
