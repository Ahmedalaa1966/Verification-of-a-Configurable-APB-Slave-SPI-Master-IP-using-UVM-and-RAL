`ifndef APB_DRIVER_SV
`define APB_DRIVER_SV


`include "uvm_macros.svh"

import uvm_pkg::*;
import spi_pkg::*; 


class apb_driver extends uvm_driver #(apb_seq_item);

  `uvm_component_utils(apb_driver)

  virtual apb_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", vif))
      `uvm_fatal("APB_DRV", "virtual apb_if not found in config_db (key: apb_vif)")
  endfunction

  task run_phase(uvm_phase phase);
    // idle values, then wait for reset release
    vif.cb_master.psel    <= 'b0;
    vif.cb_master.penable <= 'b0;
    vif.cb_master.pwrite  <= 'b0;
    vif.cb_master.paddr   <= 'b0;
    vif.cb_master.pwdata  <= 'b0;
    wait (vif.presetn === 1'b1);

    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_item(apb_seq_item item);
    // SETUP phase: PSEL=1, PENABLE=0
    @(vif.cb_master);
    vif.cb_master.psel    <= 1;
    vif.cb_master.penable <= 0;
    vif.cb_master.pwrite  <= item.pwrite;
    vif.cb_master.paddr   <= item.paddr;
    vif.cb_master.pwdata  <= item.pwdata;

    // ACCESS phase: PENABLE=1
    @(vif.cb_master);
    vif.cb_master.penable <= 1;

    // wait until the slave is ready (always 1 in this DUT), sample at that edge
    @(vif.cb_master);
    while (vif.cb_master.pready !== 1'b1)
      @(vif.cb_master);

    // capture the response into the same item (adapter reads it from here)
    item.prdata  = vif.cb_master.prdata;
    item.pslverr = vif.cb_master.pslverr;

    // back to IDLE
    vif.cb_master.psel    <= 0;
    vif.cb_master.penable <= 0;
    vif.cb_master.pwrite  <= 0;
  endtask

endclass

`endif