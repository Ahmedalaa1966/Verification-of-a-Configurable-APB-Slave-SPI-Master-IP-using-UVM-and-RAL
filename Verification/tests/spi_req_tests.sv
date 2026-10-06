`ifndef SPI_REQ_TESTS_SV
`define SPI_REQ_TESTS_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_test_pkg::*;
import spi_seq_pkg::*;


class spi_req_test extends spi_base_test;      // R3, R9..R23, R25
  `uvm_component_utils(spi_req_test)

  virtual spi_if vif;
  virtual apb_if avif;
  int errors;

  function new(string name = "spi_req_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // R22: zero wait states and no slave error on every access (runs during all four sequences)
  task watch_apb();
    forever begin
      @(posedge avif.pclk);
      if (avif.psel && avif.penable) begin
        if (avif.pready !== 1'b1) begin errors++; `uvm_error("R22", "PREADY not 1 (wait state)") end
        if (avif.pslverr !== 1'b0) begin errors++; `uvm_error("R22", "PSLVERR asserted") end
      end
    end
  endtask

  // bring the DUT back to a clean state, then run one sequence
  task run_seq(spi_req_seq seq);
    uvm_status_e s;
    env.reg_block.CTRL.write(s, 0);            // EN=0 flushes the FIFOs
    env.reg_block.INT_EN.write(s, 0);
    env.reg_block.INT_STAT.write(s, 32'h1F);   // W1C
    env.reg_block.SS_CTRL.write(s, 0);
    env.reg_block.DELAY.write(s, 0);
    env.reg_block.CLK_DIV.write(s, 0);

    seq.reg_block = env.reg_block;
    seq.vif       = vif;
    seq.start(env.apb_agt.sequencer);
  endtask

  virtual task run_scenario();
    spi_fifo_seq fifo_seq = spi_fifo_seq::type_id::create("fifo_seq");   // R9..R15
    spi_irq_seq  irq_seq  = spi_irq_seq::type_id::create("irq_seq");     // R16..R18
    spi_ctrl_seq ctrl_seq = spi_ctrl_seq::type_id::create("ctrl_seq");   // R3, R19, R20, R25
    spi_misc_seq misc_seq = spi_misc_seq::type_id::create("misc_seq");   // R21, R23

    if (!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", vif))
      `uvm_fatal("REQ", "spi_vif not found")
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", avif))
      `uvm_fatal("REQ", "apb_vif not found")

    fork watch_apb(); join_none

    run_seq(fifo_seq);      // first: it needs a fresh STATUS (sticky overflow bits)
    run_seq(irq_seq);
    run_seq(ctrl_seq);
    run_seq(misc_seq);

    disable fork;
    if (errors == 0)
      `uvm_info("R22", "PASS: PREADY=1 and PSLVERR=0 on every access", UVM_LOW)
  endtask
endclass

`endif