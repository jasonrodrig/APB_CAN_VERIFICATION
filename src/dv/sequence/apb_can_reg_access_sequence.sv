`ifndef APB_CAN_REG_ACCESS_SEQUENCE_INCLUDED_
`define APB_CAN_REG_ACCESS_SEQUENCE_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: apb_can_reg_access_sequence
//  Programs the BRP register of every node in parallel (for loop + fork/join_none, one thread
//  per node):
//   - writes BRP (value 5 + node) and reads it back
//  Accesses go through p_sequencer.apb_can_reg_model_h[i]; its map sends them to the
//  APB master sequencer of that node (apb_environment_h[i].apb_master_agent_h.apb_master_seqr_h).
//--------------------------------------------------------------------------------------------
class apb_can_reg_access_sequence extends apb_can_base_sequence;
  `uvm_object_utils(apb_can_reg_access_sequence)

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "apb_can_reg_access_sequence");
  extern virtual task body();
  extern virtual task program_brp(int node);

endclass : apb_can_reg_access_sequence

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - apb_can_reg_access_sequence
//--------------------------------------------------------------------------------------------
function apb_can_reg_access_sequence::new(string name = "apb_can_reg_access_sequence");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
//  Writes and reads back the BRP register of each node
//--------------------------------------------------------------------------------------------
task apb_can_reg_access_sequence::body();
  super.body();

  // One thread per node, so the BRP of all the nodes is programmed at the same time
  for(int i = 0; i < `NO_OF_NODES; i++) begin
    fork
      automatic int node = i;
      program_brp(node);
    join_none
  end

  // Wait till all the nodes are programmed
  wait fork;
endtask : body

//--------------------------------------------------------------------------------------------
// Task: program_brp
//  Writes and reads back the BRP register of the given node
//
// Parameters:
//  node - index of the CAN node
//--------------------------------------------------------------------------------------------
task apb_can_reg_access_sequence::program_brp(int node);
  uvm_status_e   status;
  uvm_reg_data_t rdata;
  uvm_reg_data_t brp_wdata;

  // Node specific value, so each node's register traffic can be told apart
  brp_wdata = 'h5 + node;

  p_sequencer.apb_can_reg_model_h[node].brp.write(status, brp_wdata, .parent(this));
  `uvm_info(get_type_name(), $sformatf("Node[%0d] BRP write : status = %s, data = 'h%0h", node, status.name(), brp_wdata), UVM_LOW)

  p_sequencer.apb_can_reg_model_h[node].brp.read(status, rdata, .parent(this));
  `uvm_info(get_type_name(), $sformatf("Node[%0d] BRP read  : status = %s, data = 'h%0h", node, status.name(), rdata), UVM_LOW)
endtask : program_brp

`endif
