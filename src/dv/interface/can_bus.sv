`ifndef CAN_BUS_INCLUDED_
`define CAN_BUS_INCLUDED_

//--------------------------------------------------------------------------------------------
// Module      : can_bus
// Description : Shared CAN bus model. Resolves the can_tx of every node into a single bus
//               level using wired-AND logic (dominant = 0, recessive = 1): the bus is
//               recessive only when every node transmits recessive. The resolved level is
//               fed back to every node as can_rx.
//               A node in loopback mode (node_loopback[i] = 1):
//                - is disconnected from the bus: its can_tx is treated as recessive, so it
//                  cannot drive the other nodes
//                - receives its own can_tx on its can_rx instead of the bus level
//--------------------------------------------------------------------------------------------
module can_bus #(
  parameter int NO_OF_NODES = 3
) (
  input  logic [NO_OF_NODES-1:0] can_tx,
  input  logic [NO_OF_NODES-1:0] node_loopback,
  output logic [NO_OF_NODES-1:0] can_rx,
  output logic                   can_bus
);

  //-------------------------------------------------------
  // CAN bus resolution (wired-AND)
  //  Loopback nodes are forced recessive (1) before the AND
  //-------------------------------------------------------
  assign can_bus = &(can_tx | node_loopback);

  //-------------------------------------------------------
  // can_rx of every node
  //  Loopback node : its own can_tx
  //  Other nodes   : the resolved bus level
  //-------------------------------------------------------
  genvar i;
  generate
    for(i = 0; i < NO_OF_NODES; i++) begin : rx
      assign can_rx[i] = node_loopback[i] ? can_tx[i] : can_bus;
    end : rx
  endgenerate

endmodule : can_bus

`endif
