`ifndef CTRL_REG
`define CTRL_REG

import uvm_pkg::*;
`include "uvm_macros.svh"

class ctrl_reg extends uvm_reg;
  `uvm_object_utils(ctrl_reg)

  rand uvm_reg_field RSVD;       // [31:8]
  rand uvm_reg_field WIDTH;      // [7:6]
  rand uvm_reg_field LOOPBACK;   // [5]
  rand uvm_reg_field LSB_FIRST;  // [4]
  rand uvm_reg_field MODE;       // [3:2]  {CPOL,CPHA}
  rand uvm_reg_field MSTR;       // [1]
  rand uvm_reg_field EN;         // [0]

  function new(string name = "ctrl_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    RSVD      = uvm_reg_field::type_id::create("RSVD");
    WIDTH     = uvm_reg_field::type_id::create("WIDTH");
    LOOPBACK  = uvm_reg_field::type_id::create("LOOPBACK");
    LSB_FIRST = uvm_reg_field::type_id::create("LSB_FIRST");
    MODE      = uvm_reg_field::type_id::create("MODE");
    MSTR      = uvm_reg_field::type_id::create("MSTR");
    EN        = uvm_reg_field::type_id::create("EN");

    RSVD.configure     (.parent(this), .size(24), .lsb_pos(8), .access("RO"), .volatile(0), .reset('h0), .has_reset(1), .is_rand(0), .individually_accessible(0));
    WIDTH.configure    (.parent(this), .size(2),  .lsb_pos(6), .access("RW"), .volatile(0), .reset('h0), .has_reset(1), .is_rand(1), .individually_accessible(0));
    LOOPBACK.configure (.parent(this), .size(1),  .lsb_pos(5), .access("RW"), .volatile(0), .reset('h0), .has_reset(1), .is_rand(1), .individually_accessible(0));
    LSB_FIRST.configure(.parent(this), .size(1),  .lsb_pos(4), .access("RW"), .volatile(0), .reset('h0), .has_reset(1), .is_rand(1), .individually_accessible(0));
    MODE.configure     (.parent(this), .size(2),  .lsb_pos(2), .access("RW"), .volatile(0), .reset('h0), .has_reset(1), .is_rand(1), .individually_accessible(0));
    MSTR.configure     (.parent(this), .size(1),  .lsb_pos(1), .access("RW"), .volatile(0), .reset('h0), .has_reset(1), .is_rand(1), .individually_accessible(0));
    EN.configure       (.parent(this), .size(1),  .lsb_pos(0), .access("RW"), .volatile(0), .reset('h0), .has_reset(1), .is_rand(1), .individually_accessible(0));
  endfunction
endclass

`endif