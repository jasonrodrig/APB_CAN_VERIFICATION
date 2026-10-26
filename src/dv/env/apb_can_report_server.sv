`ifndef APB_CAN_REPORT_SERVER_INCLUDED_
`define APB_CAN_REPORT_SERVER_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: apb_can_report_server
//  Custom report server used to format UVM messages of the APB CAN environment
//  Supports UVM 1.1 (uvm_report_server::compose_message) and
//  UVM 1.2 (uvm_default_report_server::compose_report_message)
//--------------------------------------------------------------------------------------------
`ifdef UVM_VERSION_1_1
class apb_can_report_server extends uvm_report_server;
`else
class apb_can_report_server extends uvm_default_report_server;
`endif

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "apb_can_report_server");
`ifdef UVM_VERSION_1_1
  extern virtual function string compose_message(uvm_severity severity, string name, string id,
                                                 string message, string filename, int line);
`else
  extern virtual function string compose_report_message(uvm_report_message report_message,
                                                        string report_object_name = "");
`endif

endclass : apb_can_report_server

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - apb_can_report_server
//--------------------------------------------------------------------------------------------
function apb_can_report_server::new(string name = "apb_can_report_server");
`ifdef UVM_VERSION_1_1
  super.new();
`else
  super.new(name);
`endif
endfunction : new

`ifdef UVM_VERSION_1_1
//--------------------------------------------------------------------------------------------
// Function: compose_message
//  Formats each report message (UVM 1.1)
//--------------------------------------------------------------------------------------------
function string apb_can_report_server::compose_message(uvm_severity severity, string name, string id,
                                                       string message, string filename, int line);
  // TODO: customise message format
  return super.compose_message(severity, name, id, message, filename, line);
endfunction : compose_message
`else
//--------------------------------------------------------------------------------------------
// Function: compose_report_message
//  Formats each report message (UVM 1.2)
//
// Parameters:
//  report_message     - message to be formatted
//  report_object_name - name of the reporting object
//--------------------------------------------------------------------------------------------
function string apb_can_report_server::compose_report_message(uvm_report_message report_message,
                                                             string report_object_name = "");
  // TODO: customise message format
  return super.compose_report_message(report_message, report_object_name);
endfunction : compose_report_message
`endif

`endif
