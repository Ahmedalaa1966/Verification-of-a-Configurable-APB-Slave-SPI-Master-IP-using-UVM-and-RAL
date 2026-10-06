`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_pkg::*; 

class apb_monitor extends uvm_monitor;
  `uvm_component_utils(apb_monitor)

  virtual apb_if vif;
  uvm_analysis_port #(apb_seq_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", vif))
      `uvm_fatal("APB_MON", "virtual apb_if not found in config_db (key: apb_vif)")
  endfunction

  task run_phase(uvm_phase phase);
  apb_seq_item txn;

  wait (vif.presetn === 1'b1);

  forever begin
    // wait for SETUP
    @(vif.cb_monitor);
    if (vif.cb_monitor.psel === 1'b1 && vif.cb_monitor.penable === 1'b0) begin  // condition for the setup phase 
      txn        = new("apb_mon_item");
      txn.paddr  = vif.cb_monitor.paddr;
      txn.pwrite = vif.cb_monitor.pwrite;
      txn.pwdata = vif.cb_monitor.pwdata;

      // wait for ACCESS
      @(vif.cb_monitor);
      if (vif.cb_monitor.psel === 1'b1 && vif.cb_monitor.penable === 1'b1) begin  // condition for the acess phase 
        if (!txn.pwrite)
          txn.prdata = vif.cb_monitor.prdata;
        txn.pslverr = vif.cb_monitor.pslverr;
        ap.write(txn);
        `uvm_info("APB_MON", txn.convert2string(), UVM_HIGH)
      end
    end
  end
endtask

endclass    

`endif