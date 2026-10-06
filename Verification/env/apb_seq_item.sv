`ifndef APB_SEQ_ITEM_SV
`define APB_SEQ_ITEM_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_pkg::*; 


class apb_seq_item extends uvm_sequence_item;

  // stimulus fields
  rand bit [7:0]  paddr;
  rand bit [31:0] pwdata;
  rand bit        pwrite;     // 1 = write, 0 = read

  // response fields (filled by the driver / monitor)
  bit [31:0]      prdata;
  bit             pslverr;

  // word aligned by default (soft so tests can override it)
  constraint c_align { soft paddr[1:0] == 2'b00; }

  // default: stay inside the register map 0x00..0x20
  constraint c_range { soft paddr <= 8'h20; }

  function new(string name = "apb_seq_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("%s addr=0x%02h wdata=0x%08h rdata=0x%08h slverr=%0b",
                     pwrite ? "WRITE" : "READ ", paddr, pwdata, prdata, pslverr);
  endfunction

endclass

`endif