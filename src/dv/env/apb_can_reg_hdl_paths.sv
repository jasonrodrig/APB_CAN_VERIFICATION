`ifndef APB_CAN_REG_HDL_PATHS_INCLUDED_
`define APB_CAN_REG_HDL_PATHS_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: apb_can_reg_hdl_paths
//  Adds the backdoor HDL paths to a can_reg_block (the RAL files are auto-generated, so the
//  paths are kept here). The block root is the DUT of one node:
//    apb_can_top.node[i].dut                 (can_controller_top)
//  and every slice names the RTL signal that drives the bit on PRDATA:
//   - RW registers, TX sticky bits         : u_apb_slave         (can_apb_slave.v)
//   - TEC, REC, ERROR_STATUS, STATUS errors: u_error_status_cdc  (can_error_status_cdc.v)
//   - RX FIFO status, rx_overflow          : u_rx_fifo_bridge    (can_rx_fifo_bridge.v)
//   - RX_ID, RX_CTRL, RX_DATA_LO/HI        : u_rx_fifo_bridge    (can_rx_fifo_bridge.v)
//
//  Fields are sorted in two lists, used by the backdoor sequence:
//   - storage_field : RO fields mapped on a reg that holds a poked value until the RTL
//                     updates it, so a poke can be read back through the frontdoor
//   - skipped_field : fields mapped on a wire, or on a reg that the RTL reloads every PCLK.
//                     A peek still returns the value the frontdoor reads, but a poke is not
//                     kept, so these fields are not poked and are listed as skipped fields
//                     with the reason.
//--------------------------------------------------------------------------------------------

class apb_can_reg_hdl_paths;

  //Variable: storage_field
  //RO fields whose backdoor path is a holding reg (poke can be read back)
  static bit storage_field[uvm_reg_field];

  //Variable: skipped_field
  //Fields whose backdoor path is a wire or a reloaded reg (peek only), and why
  static string skipped_field[uvm_reg_field];

  //Variable: missing_fields
  //Registers with no backdoor path: fields that are not present as storage, and why
  static string missing_fields[uvm_reg];

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern static function void set_hdl_paths(can_reg_block can_reg_block_h, string root);

endclass : apb_can_reg_hdl_paths

//--------------------------------------------------------------------------------------------
// Function: set_hdl_paths
//  Sets the block root, the slices of every register and the storage / skipped lists
//
// Parameters:
//  can_reg_block_h - register model of one node
//  root            - HDL path of that node's DUT
//--------------------------------------------------------------------------------------------
function void apb_can_reg_hdl_paths::set_hdl_paths(can_reg_block can_reg_block_h, string root);
  can_reg_block_h.add_hdl_path(root);

  // Registers with no backdoor path: fields not present as storage in the RTL
  missing_fields[can_reg_block_h.version]    = "version (constant 'h01002001 driven on PRDATA)";
  missing_fields[can_reg_block_h.tx_command] = "tx_start (write only, tx_request pulse)";
  missing_fields[can_reg_block_h.rx_command] = "rx_pop (write only, rx_pop pulse)";

  // CONTROL (0x004)
  can_reg_block_h.control.add_hdl_path_slice("u_apb_slave.can_enable",  0, 1);
  can_reg_block_h.control.add_hdl_path_slice("u_apb_slave.loopback",    1, 1);
  can_reg_block_h.control.add_hdl_path_slice("u_apb_slave.listen_only", 2, 1);

  // STATUS (0x008)
  can_reg_block_h.status.add_hdl_path_slice("u_error_status_cdc.line_busy",        0, 1);
  can_reg_block_h.status.add_hdl_path_slice("u_apb_slave.tx_done_latched",         1, 1);
  can_reg_block_h.status.add_hdl_path_slice("u_apb_slave.rx_available",            2, 1);
  can_reg_block_h.status.add_hdl_path_slice("u_rx_fifo_bridge.fifo_full_pclk",     3, 1);
  can_reg_block_h.status.add_hdl_path_slice("u_error_status_cdc.arbitration_lost", 4, 1);
  can_reg_block_h.status.add_hdl_path_slice("u_error_status_cdc.ack_error",        5, 1);
  can_reg_block_h.status.add_hdl_path_slice("u_error_status_cdc.crc_error",        6, 1);
  can_reg_block_h.status.add_hdl_path_slice("u_error_status_cdc.stuff_error",      7, 1);
  can_reg_block_h.status.add_hdl_path_slice("u_error_status_cdc.form_error",       8, 1);
  can_reg_block_h.status.add_hdl_path_slice("u_error_status_cdc.bit_error",        9, 1);
  can_reg_block_h.status.add_hdl_path_slice("u_rx_fifo_bridge.fifo_overflow",      10, 1);
  storage_field[can_reg_block_h.status.tx_done]     = 1;
  storage_field[can_reg_block_h.status.rx_overflow] = 1;
  skipped_field[can_reg_block_h.status.tx_busy]      = "reg, reloaded every PCLK (u_error_status_cdc.line_busy)";
  skipped_field[can_reg_block_h.status.rx_available] = "wire (input rx_available of can_apb_slave = !rx_fifo_empty)";
  skipped_field[can_reg_block_h.status.rx_fifo_full] = "wire (output fifo_full_pclk of can_rx_fifo_bridge)";
  skipped_field[can_reg_block_h.status.arb_lost]     = "reg, 1-PCLK pulse (u_error_status_cdc.arbitration_lost)";
  skipped_field[can_reg_block_h.status.ack_error]    = "reg, 1-PCLK pulse (u_error_status_cdc.ack_error)";
  skipped_field[can_reg_block_h.status.crc_error]    = "reg, 1-PCLK pulse (u_error_status_cdc.crc_error)";
  skipped_field[can_reg_block_h.status.stuff_error]  = "reg, 1-PCLK pulse (u_error_status_cdc.stuff_error)";
  skipped_field[can_reg_block_h.status.form_error]   = "reg, 1-PCLK pulse (u_error_status_cdc.form_error)";
  skipped_field[can_reg_block_h.status.bit_error]    = "reg, 1-PCLK pulse (u_error_status_cdc.bit_error)";

  // ERROR_STATUS (0x00C)
  can_reg_block_h.error_status.add_hdl_path_slice("u_error_status_cdc.error_state",      0, 2);
  can_reg_block_h.error_status.add_hdl_path_slice("u_error_status_cdc.recovery_active",  2, 1);
  can_reg_block_h.error_status.add_hdl_path_slice("u_error_status_cdc.last_error_valid", 3, 1);
  can_reg_block_h.error_status.add_hdl_path_slice("u_error_status_cdc.last_error_type",  4, 4);
  storage_field[can_reg_block_h.error_status.error_state]      = 1;
  storage_field[can_reg_block_h.error_status.last_error_valid] = 1;
  storage_field[can_reg_block_h.error_status.last_error_type]  = 1;
  skipped_field[can_reg_block_h.error_status.recovery_active]  = "reg, reloaded every PCLK (u_error_status_cdc.recovery_active)";

  // BRP (0x010), SEGMENTS (0x014), SJW_CONTROL (0x018)
  can_reg_block_h.brp.add_hdl_path_slice("u_apb_slave.brp", 0, 32);
  can_reg_block_h.segments.add_hdl_path_slice("u_apb_slave.prop_seg",   0,  8);
  can_reg_block_h.segments.add_hdl_path_slice("u_apb_slave.phase_seg1", 8,  8);
  can_reg_block_h.segments.add_hdl_path_slice("u_apb_slave.phase_seg2", 16, 8);
  can_reg_block_h.sjw_control.add_hdl_path_slice("u_apb_slave.sjw", 0, 4);

  // TX_ID (0x01C), TX_CTRL (0x020), TX_DATA_LO (0x024), TX_DATA_HI (0x028)
  can_reg_block_h.tx_id.add_hdl_path_slice("u_apb_slave.tx_identifier", 0, 29);
  can_reg_block_h.tx_ctrl.add_hdl_path_slice("u_apb_slave.tx_ide", 0, 1);
  can_reg_block_h.tx_ctrl.add_hdl_path_slice("u_apb_slave.tx_rtr", 1, 1);
  can_reg_block_h.tx_ctrl.add_hdl_path_slice("u_apb_slave.tx_dlc", 2, 4);
  can_reg_block_h.tx_data_lo.add_hdl_path_slice("u_apb_slave.tx_data[31:0]",  0, 32);
  can_reg_block_h.tx_data_hi.add_hdl_path_slice("u_apb_slave.tx_data[63:32]", 0, 32);

  // TX_STATUS (0x030)
  can_reg_block_h.tx_status.add_hdl_path_slice("u_tx_cdc.p_tx_pending",                   0, 1);
  can_reg_block_h.tx_status.add_hdl_path_slice("u_error_status_cdc.line_busy",            1, 1);
  can_reg_block_h.tx_status.add_hdl_path_slice("u_apb_slave.tx_done_latched",             2, 1);
  can_reg_block_h.tx_status.add_hdl_path_slice("u_apb_slave.tx_ack_received_latched",     3, 1);
  can_reg_block_h.tx_status.add_hdl_path_slice("u_apb_slave.tx_arbitration_lost_latched", 4, 1);
  can_reg_block_h.tx_status.add_hdl_path_slice("u_apb_slave.tx_error_latched",            5, 1);
  storage_field[can_reg_block_h.tx_status.tx_done]             = 1;
  storage_field[can_reg_block_h.tx_status.tx_ack_received]     = 1;
  storage_field[can_reg_block_h.tx_status.tx_arbitration_lost] = 1;
  storage_field[can_reg_block_h.tx_status.tx_error]            = 1;
  skipped_field[can_reg_block_h.tx_status.tx_pending] = "reg, cleared on the next PCLK when no TX is queued (u_tx_cdc.p_tx_pending)";
  skipped_field[can_reg_block_h.tx_status.tx_busy]    = "reg, reloaded every PCLK (u_error_status_cdc.line_busy)";

  // RX_STATUS (0x034)
  can_reg_block_h.rx_status.add_hdl_path_slice("u_rx_fifo_bridge.fifo_count",     0,  8);
  can_reg_block_h.rx_status.add_hdl_path_slice("u_rx_fifo_bridge.fifo_empty",     8,  1);
  can_reg_block_h.rx_status.add_hdl_path_slice("u_rx_fifo_bridge.fifo_full_pclk", 9,  1);
  can_reg_block_h.rx_status.add_hdl_path_slice("u_rx_fifo_bridge.fifo_overflow",  10, 1);
  storage_field[can_reg_block_h.rx_status.rx_overflow] = 1;
  skipped_field[can_reg_block_h.rx_status.fifo_count]   = "wire (output fifo_count of can_rx_fifo_bridge)";
  skipped_field[can_reg_block_h.rx_status.rx_empty]     = "wire (output fifo_empty of can_rx_fifo_bridge)";
  skipped_field[can_reg_block_h.rx_status.rx_fifo_full] = "wire (output fifo_full_pclk of can_rx_fifo_bridge)";

  // RX_ID (0x038), RX_CTRL (0x03C), RX_DATA_LO (0x040), RX_DATA_HI (0x044)
  // The rx_*_out outputs of can_rx_fifo_bridge are wires; the reg behind them is the FIFO
  // memory entry: {29'd0, id[98:70], ide[69], rtr[68], dlc[67:64], data[63:0]}
  can_reg_block_h.rx_id.add_hdl_path_slice("u_rx_fifo_bridge.rx_identifier_out", 0, 29);
  can_reg_block_h.rx_ctrl.add_hdl_path_slice("u_rx_fifo_bridge.rx_ide_out", 0, 1);
  can_reg_block_h.rx_ctrl.add_hdl_path_slice("u_rx_fifo_bridge.rx_rtr_out", 1, 1);
  can_reg_block_h.rx_ctrl.add_hdl_path_slice("u_rx_fifo_bridge.rx_dlc_out", 2, 4);
  can_reg_block_h.rx_data_lo.add_hdl_path_slice("u_rx_fifo_bridge.rx_data_out[31:0]",  0, 32);
  can_reg_block_h.rx_data_hi.add_hdl_path_slice("u_rx_fifo_bridge.rx_data_out[63:32]", 0, 32);
  //storage_field[can_reg_block_h.rx_id.rx_identifier]      = 1;
  //storage_field[can_reg_block_h.rx_ctrl.rx_ide]           = 1;
  //storage_field[can_reg_block_h.rx_ctrl.rx_rtr]           = 1;
  //storage_field[can_reg_block_h.rx_ctrl.rx_dlc]           = 1;
  //storage_field[can_reg_block_h.rx_data_lo.rx_data_31_0]  = 1;
  //storage_field[can_reg_block_h.rx_data_hi.rx_data_63_32] = 1;
  
  skipped_field[can_reg_block_h.rx_id.rx_identifier]      = "wire (output rx_identifier_out of can_rx_fifo_bridge)";
  skipped_field[can_reg_block_h.rx_ctrl.rx_ide]           = "wire (output rx_ide_out of can_rx_fifo_bridge)";
  skipped_field[can_reg_block_h.rx_ctrl.rx_rtr]           = "wire (output rx_rtr_out of can_rx_fifo_bridge)";
  skipped_field[can_reg_block_h.rx_ctrl.rx_dlc]           = "wire (output rx_dlc_out of can_rx_fifo_bridge)";
  skipped_field[can_reg_block_h.rx_data_lo.rx_data_31_0]  = "wire (output rx_data_out[31:00] of can_rx_fifo_bridge)";
  skipped_field[can_reg_block_h.rx_data_hi.rx_data_63_32] = "wire (output rx_data_out[63:32] of can_rx_fifo_bridge)";


  // FILTER0 (0x04C..0x054), FILTER1 (0x058..0x060)
  can_reg_block_h.filter0_id.add_hdl_path_slice("u_apb_slave.filter0_id",   0, 29);
  can_reg_block_h.filter0_mask.add_hdl_path_slice("u_apb_slave.filter0_mask", 0, 29);
  can_reg_block_h.filter0_ctrl.add_hdl_path_slice("u_apb_slave.filter0_enable", 0, 1);
  can_reg_block_h.filter0_ctrl.add_hdl_path_slice("u_apb_slave.filter0_ide",    1, 1);
  can_reg_block_h.filter1_id.add_hdl_path_slice("u_apb_slave.filter1_id",   0, 29);
  can_reg_block_h.filter1_mask.add_hdl_path_slice("u_apb_slave.filter1_mask", 0, 29);
  can_reg_block_h.filter1_ctrl.add_hdl_path_slice("u_apb_slave.filter1_enable", 0, 1);
  can_reg_block_h.filter1_ctrl.add_hdl_path_slice("u_apb_slave.filter1_ide",    1, 1);

  // TEC (0x064), REC (0x068)
  can_reg_block_h.tec.add_hdl_path_slice("u_error_status_cdc.tec", 0, 9);
  can_reg_block_h.rec.add_hdl_path_slice("u_error_status_cdc.rec", 0, 8);
  storage_field[can_reg_block_h.tec.tec] = 1;
  storage_field[can_reg_block_h.rec.rec] = 1;

endfunction : set_hdl_paths

`endif

