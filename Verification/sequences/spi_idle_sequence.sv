`ifndef SPI_IDLE_SEQUENCE_SV
`define SPI_IDLE_SEQUENCE_SV


import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_seq_pkg::*;
import reg_pkg::*; 


class spi_idle_seq extends apb_base_seq;
  `uvm_object_utils(spi_idle_seq)

  spi_reg_block reg_block;   // set by the test
  bit [1:0]     mode;        // set by the test

  function new(string name = "spi_idle_seq");
    super.new(name);
  endfunction

  // send one word and wait until the core is not busy
  task send(bit [31:0] data);
    uvm_status_e   status;
    uvm_reg_data_t rdata;

    reg_block.TX_DATA.write(status, data, UVM_FRONTDOOR, .parent(this));
    repeat (2) reg_block.STATUS.read(status, rdata, UVM_FRONTDOOR, .parent(this));  // let BUSY rise
    repeat (200) begin
      reg_block.STATUS.read(status, rdata, UVM_FRONTDOOR, .parent(this));
      if (!rdata[0]) break;                                                         // BUSY = bit 0
    end
  endtask

  task body();
    uvm_status_e   status;
    uvm_reg_data_t rdata;
    bit [31:0]     ctrl = (mode << 2) | 32'h22;      // MSTR=1, LOOPBACK=1, mode, EN=0

    reg_block.CLK_DIV.write(status, 2, UVM_FRONTDOOR, .parent(this));
    reg_block.SS_CTRL.write(status, 1, UVM_FRONTDOOR, .parent(this));

    // before: EN=0 holds SCLK at CPOL
    reg_block.CTRL.write(status, ctrl, UVM_FRONTDOOR, .parent(this));
    repeat (5) reg_block.STATUS.read(status, rdata, UVM_FRONTDOOR, .parent(this));

    // between: two back-to-back transfers
    reg_block.CTRL.write(status, ctrl | 32'h1, UVM_FRONTDOOR, .parent(this));      // EN=1
    send(32'hA5);
    send(32'h3C);

    // after: EN=0 again
    reg_block.CTRL.write(status, ctrl, UVM_FRONTDOOR, .parent(this));
    repeat (5) reg_block.STATUS.read(status, rdata, UVM_FRONTDOOR, .parent(this));
  endtask
endclass

`endif