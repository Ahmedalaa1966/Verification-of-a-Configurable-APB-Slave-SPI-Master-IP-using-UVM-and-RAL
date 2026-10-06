`ifndef SPI_DRIVER_SV
`define SPI_DRIVER_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_pkg::*; 

class spi_driver extends uvm_driver #(spi_seq_item);
  `uvm_component_utils(spi_driver)

  virtual spi_if vif;
  bit prev_sclk;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", vif))
      `uvm_fatal("SPI_DRV", "virtual spi_if not found in config_db (key: spi_vif)")
  endfunction

  task run_phase(uvm_phase phase);
    vif.cb_slave.miso <= 0;   // idle value

    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask

  // wait for one SCLK edge (rising or falling), detected on PCLK samples
  task wait_sclk_edge(bit rising);
    bit cur;
    forever begin
      @(vif.cb_slave);
      cur = vif.cb_slave.sclk;
      if (rising ? (!prev_sclk && cur) : (prev_sclk && !cur)) begin
        prev_sclk = cur;
        return;
      end
      prev_sclk = cur;
    end
  endtask

  task drive_item(spi_seq_item item);
    int width;
    int idx;
    bit cpha;
    bit launch_rising;

    width         = (item.width_sel == 2'b00) ? 8 :
                    (item.width_sel == 2'b01) ? 16 : 32;
    cpha          = item.mode[0];
    launch_rising = item.mode[1] ^ item.mode[0];   // modes 1,2 launch on rising; 0,3 on falling

    // wait until the DUT asserts any slave select
    while (vif.cb_slave.ss_n === 4'hF)
      @(vif.cb_slave);
    prev_sclk = vif.cb_slave.sclk;

    // CPHA=0: first bit must already be on MISO before the first sample edge
    if (!cpha) begin
      idx = item.lsb_first ? 0 : width-1;
      vif.cb_slave.miso <= item.miso_data[idx];
    end

    for (int i = 0; i < width; i++) begin
      // launch the next bit (CPHA=0 already launched bit 0 above)
      if (cpha || i > 0) begin
        wait_sclk_edge(launch_rising);
        idx = item.lsb_first ? i : width-1-i;
        vif.cb_slave.miso <= item.miso_data[idx];
      end
      // wait for the sample edge of this bit
      wait_sclk_edge(!launch_rising);
    end

    vif.cb_slave.miso <= 0;
  endtask

endclass
`endif