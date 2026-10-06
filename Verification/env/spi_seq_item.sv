`ifndef SPI_SEQ_ITEM
`define SPI_SEQ_ITEM

import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_pkg::*; 

class spi_seq_item extends uvm_sequence_item;

  bit [1:0]  mode;        // {CPOL, CPHA}
  bit [1:0]  width_sel;   // 00 = 8b, 01 = 16b, 10 = 32b
  bit        lsb_first;   // 1 = LSB-first, 0 = MSB-first
  bit [31:0] miso_data;   // driven by the slave BFM
  bit [31:0] mosi_data;   // observed by the monitor

  function new(string name = "spi_seq_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("mode=%0d width_sel=%0d lsb_first=%0b miso=0x%08h mosi=0x%08h",
                     mode, width_sel, lsb_first, miso_data, mosi_data);
  endfunction

endclass
`endif