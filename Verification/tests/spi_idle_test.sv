`ifndef SPI_IDLE_TEST_SV
`define SPI_IDLE_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_test_pkg::*;
import spi_seq_pkg::*;


class spi_idle_test extends spi_base_test;
  `uvm_component_utils(spi_idle_test)

  virtual spi_if vif;
  bit chk_en;       // check is active
  bit exp_cpol;     // expected idle level of SCLK
  int errors;

  function new(string name = "spi_idle_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // R4: while all slave selects are high, SCLK must sit at CPOL
  task watch_sclk();
    forever begin
      @(posedge vif.pclk);
      if (chk_en && (&vif.ss_n) && vif.sclk !== exp_cpol) begin
        errors++;
        `uvm_error("R4", $sformatf("SCLK idle = %b, expected CPOL = %b", vif.sclk, exp_cpol))
      end
    end
  endtask

  virtual task run_scenario();
    spi_idle_seq seq;

    if (!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", vif))
      `uvm_fatal("R4", "spi_vif not found")

    fork watch_sclk(); join_none

    for (int m = 0; m < 4; m++) begin
      exp_cpol = m[1];                          // CPOL of this mode
      seq = spi_idle_seq::type_id::create("seq");
      seq.mode      = m;
      seq.reg_block = env.reg_block;

      fork
        seq.start(env.apb_agt.sequencer);
        begin repeat (20) @(posedge vif.pclk); chk_en = 1; end   // start checking after CTRL is written
      join
      chk_en = 0;
    end

    disable fork;
    if (errors == 0)
      `uvm_info("R4", "PASS: SCLK idle matched CPOL in all 4 modes", UVM_LOW)
  endtask
endclass

`endif