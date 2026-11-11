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

  bit [ `CAN_APB_DATA_WIDTH - 1 : 0 ] mem [ ( 2 ** `CAN_APB_ADDR_WIDTH - 1 ) : 0 ];
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "apb_can_scoreboard", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern task apb_functionality(apb_master_tx tx);
  extern task apb_write(apb_master_tx tx); 
  extern task apb_read(apb_master_tx tx);
  extern virtual function void check_phase(uvm_phase phase);
  extern virtual function void report_phase(uvm_phase phase);
  extern function void pslverr(apb_master_tx tx);
  extern function void no_pslverr(apb_master_tx tx);

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
  mem [ `CAN_ADDR_VERSION  ] = 32'h0100_2001;
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
  apb_master_tx     apb_tx;
  can_sequence_item can_item_h;

  fork
    forever begin
      apb_master_analysis_fifo.get(apb_tx);
      apb_functionality(apb_tx);  
    end
    forever begin
      can_analysis_fifo.get(can_item_h);
      // TODO: compare observed frame against expected frame
    end
  join

endtask : run_phase

task apb_can_scoreboard::apb_functionality(apb_master_tx tx); 
  case(tx.paddr)
    `CAN_ADDR_VERSION:      begin  if( tx.pwrite ) begin `uvm_info(get_type_name(), $sformatf(" NODE = %0d ->  write ignored for RO access policy register at address = %0h " , node_id , tx.paddr ) , UVM_NONE ) no_pslverr(tx); end else apb_read(tx); end //ro
    `CAN_ADDR_CONTROL:      begin  if( tx.pwrite ) apb_write(tx); else apb_read(tx); end //rw
    `CAN_ADDR_STATUS:       begin  if( tx.pwrite ) begin `uvm_info(get_type_name(), $sformatf(" NODE = %0d ->  write ignored for RO access policy register at address = %0h " , node_id , tx.paddr ) , UVM_NONE ) no_pslverr(tx); end else apb_read(tx); end //ro
    `CAN_ADDR_ERROR_STATUS: begin  if( tx.pwrite ) begin `uvm_info(get_type_name(), $sformatf(" NODE = %0d ->  write ignored for RO access policy register at address = %0h " , node_id , tx.paddr ) , UVM_NONE ) no_pslverr(tx); end else apb_read(tx); end //ro
    `CAN_ADDR_BRP:          begin  if( tx.pwrite ) apb_write(tx); else apb_read(tx); end //rw
    `CAN_ADDR_SEGMENTS:     begin  if( tx.pwrite ) apb_write(tx); else apb_read(tx); end //rw
    `CAN_ADDR_SJW_CONTROL:  begin  if( tx.pwrite ) apb_write(tx); else apb_read(tx); end //rw
    `CAN_ADDR_TX_ID:        begin  if( tx.pwrite ) apb_write(tx); else apb_read(tx); end //rw
    `CAN_ADDR_TX_CTRL:      begin  if( tx.pwrite ) apb_write(tx); else apb_read(tx); end //rw
    `CAN_ADDR_TX_DATA_LO:   begin  if( tx.pwrite ) apb_write(tx); else apb_read(tx); end //rw
    `CAN_ADDR_TX_DATA_HI:   begin  if( tx.pwrite ) apb_write(tx); else apb_read(tx); end //rw
    `CAN_ADDR_TX_COMMAND:   begin  if( tx.pwrite ) apb_write(tx); else apb_read(tx); end //wo
    `CAN_ADDR_TX_STATUS:    begin  if( tx.pwrite ) begin `uvm_info(get_type_name(), $sformatf(" NODE = %0d ->  write ignored for RO access policy register at address = %0h " , node_id , tx.paddr ) , UVM_NONE ) no_pslverr(tx) ; end else apb_read(tx); end //ro
    `CAN_ADDR_RX_STATUS:    begin  if( tx.pwrite ) begin `uvm_info(get_type_name(), $sformatf(" NODE = %0d ->  write ignored for RO access policy register at address = %0h " , node_id , tx.paddr ) , UVM_NONE ) no_pslverr(tx) ; end else apb_read(tx); end //ro
    `CAN_ADDR_RX_ID:        begin  if( tx.pwrite ) begin `uvm_info(get_type_name(), $sformatf(" NODE = %0d ->  write ignored for RO access policy register at address = %0h " , node_id , tx.paddr ) , UVM_NONE ) no_pslverr(tx) ; end else apb_read(tx); end //ro
    `CAN_ADDR_RX_CTRL:      begin  if( tx.pwrite ) begin `uvm_info(get_type_name(), $sformatf(" NODE = %0d ->  write ignored for RO access policy register at address = %0h " , node_id , tx.paddr ) , UVM_NONE ) no_pslverr(tx) ; end else apb_read(tx); end //ro
    `CAN_ADDR_RX_DATA_LO:   begin  if( tx.pwrite ) begin `uvm_info(get_type_name(), $sformatf(" NODE = %0d ->  write ignored for RO access policy register at address = %0h " , node_id , tx.paddr ) , UVM_NONE ) no_pslverr(tx) ; end else apb_read(tx); end //ro
    `CAN_ADDR_RX_DATA_HI:   begin  if( tx.pwrite ) begin `uvm_info(get_type_name(), $sformatf(" NODE = %0d ->  write ignored for RO access policy register at address = %0h " , node_id , tx.paddr ) , UVM_NONE ) no_pslverr(tx) ; end else apb_read(tx); end //ro
    `CAN_ADDR_RX_COMMAND:   begin  if( tx.pwrite ) apb_write(tx); else apb_read(tx); end // wo
    `CAN_ADDR_FILTER0_ID:   begin  if( tx.pwrite ) apb_write(tx); else apb_read(tx); end // rw
    `CAN_ADDR_FILTER0_MASK: begin  if( tx.pwrite ) apb_write(tx); else apb_read(tx); end // rw
    `CAN_ADDR_FILTER0_CTRL: begin  if( tx.pwrite ) apb_write(tx); else apb_read(tx); end // rw
    `CAN_ADDR_FILTER1_ID:   begin  if( tx.pwrite ) apb_write(tx); else apb_read(tx); end // rw
    `CAN_ADDR_FILTER1_MASK: begin  if( tx.pwrite ) apb_write(tx); else apb_read(tx); end // rw
    `CAN_ADDR_FILTER1_CTRL: begin  if( tx.pwrite ) apb_write(tx); else apb_read(tx); end // rw
    `CAN_ADDR_TEC:          begin  if( tx.pwrite ) begin `uvm_info(get_type_name(), $sformatf(" NODE = %0d ->  write ignored for RO access policy register at address = %0h " , node_id , tx.paddr ) , UVM_NONE ) no_pslverr(tx); end else apb_read(tx); end //ro
    `CAN_ADDR_REC:          begin  if( tx.pwrite ) begin `uvm_info(get_type_name(), $sformatf(" NODE = %0d ->  write ignored for RO access policy register at address = %0h " , node_id , tx.paddr ) , UVM_NONE ) no_pslverr(tx); end else apb_read(tx); end //ro
    default:                begin  no_pslverr(tx); end // invlaid address
  endcase    

endtask : apb_functionality

task apb_can_scoreboard::apb_write(apb_master_tx tx);

    if( tx.paddr == `CAN_ADDR_TX_COMMAND || tx.paddr == `CAN_ADDR_RX_COMMAND ) begin mem[tx.paddr] = 0; no_pslverr(tx) ; end  
    else if( tx.paddr == `CAN_ADDR_CONTROL && ( !tx.pwdata[0] && ( mem[`CAN_ADDR_STATUS] & 32'h0000_0001 ) === 1  ) || tx.pwdata[2:1] === 2'b11 ) begin pslverr(tx); end
    else if((( mem[`CAN_ADDR_CONTROL] & 32'h0000_0001 ) === 1) && (tx.paddr inside { `CAN_ADDR_BRP, `CAN_ADDR_SEGMENTS, `CAN_ADDR_SJW_CONTROL, `CAN_ADDR_FILTER0_ID, `CAN_ADDR_FILTER0_MASK, `CAN_ADDR_FILTER0_CTRL, `CAN_ADDR_FILTER1_ID, `CAN_ADDR_FILTER1_MASK, `CAN_ADDR_FILTER1_CTRL })) begin pslverr(tx); end
    else begin mem[tx.paddr] = tx.pwdata; no_pslverr(tx); `uvm_info(get_type_name(), $sformatf(" NODE = %0d ->  WRITE: plsverr = %0d | address = %0h | data = %0h " , node_id , tx.pslverr , tx.paddr , tx.pwdata ) , UVM_NONE ) end
  
endtask : apb_write

task apb_can_scoreboard::apb_read(apb_master_tx tx);
  
  if( tx.paddr == `CAN_ADDR_TX_COMMAND || tx.paddr == `CAN_ADDR_RX_COMMAND ) begin //for wo
    if( !tx.prdata ) `uvm_info(get_type_name(), $sformatf(" NODE = %0d -> READ PASS : plsverr = %0d | address = %0h | expected = %0h | got = %0h" , node_id , tx.pslverr , tx.paddr , 0 , tx.prdata ) , UVM_NONE )
    else             `uvm_error(get_type_name(), $sformatf(" NODE = %0d -> READ FAIL : plsverr = %0d | address = %0h | expected = %0h | got = %0h" , node_id , tx.pslverr , tx.paddr , 0 , tx.prdata ) )
    no_pslverr(tx); 
  end

  else begin 
    if( tx.prdata === mem[tx.paddr] ) `uvm_info(get_type_name(), $sformatf(" NODE = %0d -> READ PASS : plsverr = %0d | address = %0h | expected = %0h | got = %0h" , node_id , tx.pslverr , tx.paddr , mem[tx.paddr] , tx.prdata ) , UVM_NONE )
    else                              `uvm_error(get_type_name(), $sformatf(" NODE = %0d -> READ FAIL : plsverr = %0d | address = %0h | expected = %0h | got = %0h" , node_id , tx.pslverr , tx.paddr , mem[tx.paddr] , tx.prdata ) )
    no_pslverr(tx);
  end

endtask : apb_read

function void apb_can_scoreboard::no_pslverr(apb_master_tx tx);
  if( !tx.pslverr ) `uvm_info(get_type_name(), $sformatf(" NODE = %0d -> NO PSLVERR PASS : address = %0h | expected = %0h | got = %0h" , node_id ,  tx.paddr , 0 , tx.pslverr ) , UVM_NONE )
  else              `uvm_error(get_type_name(), $sformatf(" NODE = %0d -> NO PLSVERR FAIL : address = %0h | expected = %0h | got = %0h" , node_id ,  tx.paddr , 0 , tx.pslverr ) )
endfunction : no_pslverr 

function void apb_can_scoreboard::pslverr(apb_master_tx tx);
  if( tx.pslverr ) `uvm_info(get_type_name(), $sformatf(" NODE = %0d ->  PSLVERR PASS : address = %0h | expected = %0h | got = %0h" , node_id ,  tx.paddr , 1 , tx.pslverr ) , UVM_NONE )
  else             `uvm_error(get_type_name(), $sformatf(" NODE = %0d -> PLSVERR FAIL : address = %0h | expected = %0h | got = %0h" , node_id ,  tx.paddr , 1 , tx.pslverr ) )
endfunction : pslverr 

//-------------------------------------------------------------------------
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
