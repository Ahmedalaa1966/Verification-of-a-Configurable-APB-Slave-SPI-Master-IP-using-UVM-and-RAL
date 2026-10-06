`ifndef APB_REG_ADAPTOR_SV
`define APB_REG_ADAPTOR_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_pkg::*; 


class apb_reg_adapter extends uvm_reg_adapter;

  function new(string name = "apb_reg_adapter");
    super.new(name);
    supports_byte_enable = 0;
    provides_responses   = 0;
  endfunction

  // RAL operation -> APB item
  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    apb_seq_item item = new("apb_item");

    item.pwrite = (rw.kind == UVM_WRITE);
    item.paddr  = rw.addr[7:0];
    item.pwdata = rw.data[31:0];

    return item;
  endfunction

  // completed APB item -> RAL operation
  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    apb_seq_item item;

    if (!$cast(item, bus_item)) begin
      `uvm_fatal("APB_ADAPTER", "bus_item is not an apb_seq_item")
      return;
    end

    rw.kind   = item.pwrite ? UVM_WRITE : UVM_READ;
    rw.addr   = item.paddr;
    rw.data   = item.pwrite ? item.pwdata : item.prdata;
    rw.status = item.pslverr ? UVM_NOT_OK : UVM_IS_OK;
  endfunction

endclass

`endif