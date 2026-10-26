`ifndef APB_CAN_RAL_REPORT_CATCHER_INCLUDED_
`define APB_CAN_RAL_REPORT_CATCHER_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: apb_can_ral_report_catcher
//  The generated RAL (ral/, gen_ral.py) adds the WO command registers TX_COMMAND and
//  RX_COMMAND to the map with "WO" rights while their 'reserved' field is "RO". UVM reports
//  this as a RegModel UVM_ERROR, which stops the build (BUILDERR).
//  This catcher demotes only that message to UVM_WARNING so the generated RAL can be used
//  unmodified. Remove it once gen_ral.py is fixed.
//--------------------------------------------------------------------------------------------
class apb_can_ral_report_catcher extends uvm_report_catcher;
  `uvm_object_utils(apb_can_ral_report_catcher)

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "apb_can_ral_report_catcher");
  extern virtual function action_e catch();

endclass : apb_can_ral_report_catcher

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - apb_can_ral_report_catcher
//--------------------------------------------------------------------------------------------
function apb_can_ral_report_catcher::new(string name = "apb_can_ral_report_catcher");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: catch
//  Demotes the "RO field '*.reserved' restricted to WO" RegModel error to a warning
//--------------------------------------------------------------------------------------------
function uvm_report_catcher::action_e apb_can_ral_report_catcher::catch();
  if(get_severity() == UVM_ERROR && get_id() == "RegModel" &&
     uvm_is_match("RO field '*.reserved' restricted to WO in map*", get_message())) begin
    set_severity(UVM_WARNING);
  end
  return THROW;
endfunction : catch

`endif
