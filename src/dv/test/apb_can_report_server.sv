`ifndef APBCANREPORTSERVER_INCLUDED_
`define APBCANREPORTSERVER_INCLUDED_

class apb_can_report_server extends uvm_report_server;

  `uvm_object_utils(apb_can_report_server)

  localparam string GREEN  = "\033[38;5;114m"; // info
  localparam string YELLOW = "\033[38;5;180m"; // warning
  localparam string RED    = "\033[38;5;203m"; // error 
  localparam string MAGENTA= "\033[38;5;141m"; // fatal
  localparam string CYAN   = "\033[38;5;110m"; // message id
  localparam string BLUE   = "\033[38;5;109m"; // time
  localparam string PINK   = "\033[38;5;175m"; // file path
  localparam string RESET  = "\033[0m";

  function new(string name = "apb_can_report_server");
    super.new();
  endfunction

  virtual function string compose_message( uvm_severity severity, string name, string id, string message, string filename, int line );

    string sev_color, sev_label , composed , id_str;

    case(severity)
      UVM_INFO:    begin sev_color = GREEN;   sev_label = "[INFO]";  end
      UVM_WARNING: begin sev_color = YELLOW;  sev_label = "[WARN]";  end
      UVM_ERROR:   begin sev_color = RED;     sev_label = "[ERROR]"; end
      UVM_FATAL:   begin sev_color = MAGENTA; sev_label = "[FATAL]"; end
      default:     begin sev_color = RESET;   sev_label = "[MSG]";   end
    endcase


    id_str = $sformatf("(ID=%s)", id);

    composed = $sformatf(
              "%s%-7s%s  %s%-25s%s  %s%-50s%s  [time=%0t]  %s%s",
              sev_color, sev_label, RESET,
              CYAN,     id_str,   RESET,
              PINK,     filename,     BLUE,
              $time, RESET,
              message
            
    );

    return composed;
  endfunction

endclass

`endif
