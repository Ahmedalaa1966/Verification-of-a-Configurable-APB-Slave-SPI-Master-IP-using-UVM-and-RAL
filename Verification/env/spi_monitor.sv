`ifndef SPI_MONITOR_SV
`define SPI_MONITOR_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_pkg::*; 

class spi_monitor extends uvm_monitor;
  `uvm_component_utils(spi_monitor)

  virtual spi_if vif;
  uvm_analysis_port #(spi_seq_item) ap;

  // set by the reference model from every CTRL write (or by the test)
  bit [1:0] mode      = 0;   // {CPOL, CPHA}
  bit [1:0] width_sel = 0;   // 00 = 8b, 01 = 16b, 10 = 32b
  bit       lsb_first = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", vif))
      `uvm_fatal("SPI_MON", "virtual spi_if not found in config_db (key: spi_vif)")
  endfunction

  task run_phase(uvm_phase phase);
    spi_seq_item item;
    int        width;
    bit        sample_rising;
    bit        prev_sclk, cur_sclk;
    int        count;
    bit [31:0] mosi_word;
    bit [31:0] miso_word;

    forever begin
      // wait for a slave select to go low
      @(vif.cb_mon);
      while (vif.cb_mon.ss_n === 4'hF)
        @(vif.cb_mon);

      width         = (width_sel == 2'b00) ? 8 : (width_sel == 2'b01) ? 16 : 32;
      sample_rising = ~(mode[1] ^ mode[0]);   // modes 0,3 rising; 1,2 falling
      prev_sclk     = vif.cb_mon.sclk;
      count         = 0;
      mosi_word     = 0;
      miso_word     = 0;

      // collect one bit of MOSI and MISO on every sample edge
      while (count < width) begin
        @(vif.cb_mon);
        cur_sclk = vif.cb_mon.sclk;

        if (sample_rising ? (!prev_sclk && cur_sclk) : (prev_sclk && !cur_sclk)) begin
          if (lsb_first) begin
            mosi_word[count] = vif.cb_mon.mosi;
            miso_word[count] = vif.cb_mon.miso;
          end
          else begin
            mosi_word[width-1-count] = vif.cb_mon.mosi;
            miso_word[width-1-count] = vif.cb_mon.miso;
          end
          count++;
        end
        prev_sclk = cur_sclk;
      end

      // send the finished word
      item           = new("spi_mon_item");
      item.mode      = mode;
      item.width_sel = width_sel;
      item.lsb_first = lsb_first;
      item.mosi_data = mosi_word;
      item.miso_data = miso_word;
      ap.write(item);
      `uvm_info("SPI_MON", item.convert2string(), UVM_HIGH)
    end
  endtask

endclass
`endif