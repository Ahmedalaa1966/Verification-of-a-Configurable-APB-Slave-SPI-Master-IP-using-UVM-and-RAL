`ifndef DELAY_REG
`define DELAY_REG

import uvm_pkg::*;
`include "uvm_macros.svh"


class delay_reg extends uvm_reg;
  `uvm_object_utils(delay_reg)

  rand uvm_reg_field RSVD;    // [31:8]
  rand uvm_reg_field DELAY;   // [7:0]

  function new(string name = "delay_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    RSVD  = uvm_reg_field::type_id::create("RSVD");
    DELAY = uvm_reg_field::type_id::create("DELAY");

    RSVD.configure (.parent(this), .size(24), .lsb_pos(8), .access("RO"), .volatile(0), .reset('h0), .has_reset(1), .is_rand(0), .individually_accessible(0));
    DELAY.configure(.parent(this), .size(8),  .lsb_pos(0), .access("RW"), .volatile(0), .reset('h0), .has_reset(1), .is_rand(1), .individually_accessible(0));
  endfunction
endclass

`endif