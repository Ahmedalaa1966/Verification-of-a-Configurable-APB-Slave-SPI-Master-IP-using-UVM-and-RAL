// ============================================================================
// SPI base sequence (slave side: provides the MISO word)
// ============================================================================
`ifndef SPI_BASE_SEQUENCE
`define SPI_BASE_SEQUENCE

import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_seq_pkg::*;
import reg_pkg::*;

class spi_base_seq extends uvm_sequence #(spi_seq_item);
  `uvm_object_utils(spi_base_seq)

  bit [1:0]  mode          = 2'b00;
  bit [1:0]  width_sel     = 2'b00;
  bit        lsb_first     = 1'b0;
  bit [31:0] miso_pattern  = 32'hA5A5_A5A5;
  int        num_transfers = 1;

  function new(string name = "spi_base_seq");
    super.new(name);
  endfunction

  task body();
    repeat (num_transfers) begin
      spi_seq_item t = new("spi_t");
      start_item(t);
      t.mode      = mode;
      t.width_sel = width_sel;
      t.lsb_first = lsb_first;
      t.miso_data = miso_pattern;
      finish_item(t);
    end
  endtask

endclass
`endif