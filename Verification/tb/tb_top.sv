`timescale 1ns/1ps

module spi_tb_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import spi_test_pkg::*;

  // ---------------------------------------------------------------
  // Clock and reset
  // ---------------------------------------------------------------
  logic pclk;
  logic presetn;

  initial pclk = 1'b0;
  always #5 pclk = ~pclk;                 // 100 MHz

  initial begin
    presetn = 1'b0;                       // active-low reset
    repeat (5) @(posedge pclk);
    presetn = 1'b1;
  end

  // ---------------------------------------------------------------
  // Interfaces
  // ---------------------------------------------------------------
  apb_if apb_vif (.pclk(pclk), .presetn(presetn));
  spi_if spi_vif (.pclk(pclk));

  // ---------------------------------------------------------------
  // DUT
  // ---------------------------------------------------------------
  spi_master dut (
    // APB side
    .PCLK    (pclk),
    .PRESETn (presetn),
    .PSEL    (apb_vif.psel),
    .PENABLE (apb_vif.penable),
    .PWRITE  (apb_vif.pwrite),
    .PADDR   (apb_vif.paddr),
    .PWDATA  (apb_vif.pwdata),
    .PRDATA  (apb_vif.prdata),
    .PREADY  (apb_vif.pready),
    .PSLVERR (apb_vif.pslverr),

    // SPI side
    .SCLK    (spi_vif.sclk),
    .MOSI    (spi_vif.mosi),
    .MISO    (spi_vif.miso),
    .SS_n    (spi_vif.ss_n),

    // interrupt
    .IRQ     (spi_vif.irq)
  );

  // ---------------------------------------------------------------
  // UVM start
  // ---------------------------------------------------------------
  initial begin
    uvm_config_db#(virtual apb_if)::set(null, "*", "apb_vif", apb_vif);
    uvm_config_db#(virtual spi_if)::set(null, "*", "spi_vif", spi_vif);

    run_test();                           // test chosen with +UVM_TESTNAME=<name>
  end

  // ---------------------------------------------------------------
  // Watchdog: ends a hung simulation with a clear message
  // ---------------------------------------------------------------
  initial begin
    #50ms;
    `uvm_fatal("TIMEOUT", "simulation timed out")
  end

endmodule : spi_tb_top