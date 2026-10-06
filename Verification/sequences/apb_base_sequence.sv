// ============================================================================
// APB base sequence
// ============================================================================
`ifndef APB_BASE_SEQUENCE
`define APB_BASE_SEQUENCE

import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_seq_pkg::*;

class apb_base_seq extends uvm_sequence #(apb_seq_item);
  `uvm_object_utils(apb_base_seq)

  function new(string name = "apb_base_seq");
    super.new(name);
  endfunction

  task write_reg(bit [7:0] addr, bit [31:0] data);
    apb_seq_item item = new("apb_wr");
    start_item(item);
    item.paddr  = addr;
    item.pwdata = data;
    item.pwrite = 1;
    finish_item(item);
  endtask

  task read_reg(bit [7:0] addr, output bit [31:0] data);
    apb_seq_item item = new("apb_rd");
    start_item(item);
    item.paddr  = addr;
    item.pwdata = 0;
    item.pwrite = 0;
    finish_item(item);
    data = item.prdata;
  endtask

endclass
`endif