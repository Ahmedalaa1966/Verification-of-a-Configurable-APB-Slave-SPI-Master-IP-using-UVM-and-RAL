`ifndef SS_CTRL_REG
`define SS_CTRL_REG

import uvm_pkg::*;
`include "uvm_macros.svh"

class ss_ctrl_reg extends uvm_reg;
  `uvm_object_utils(ss_ctrl_reg)

  rand uvm_reg_field RSVD;     // [31:8]
  rand uvm_reg_field SS_VAL;   // [7:4]
  rand uvm_reg_field SS_EN;    // [3:0]

  function new(string name = "ss_ctrl_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    RSVD   = uvm_reg_field::type_id::create("RSVD");
    SS_VAL = uvm_reg_field::type_id::create("SS_VAL");
    SS_EN  = uvm_reg_field::type_id::create("SS_EN");

    RSVD.configure  (.parent(this), .size(24), .lsb_pos(8), .access("RO"), .volatile(0), .reset('h0), .has_reset(1), .is_rand(0), .individually_accessible(0));
    SS_VAL.configure(.parent(this), .size(4),  .lsb_pos(4), .access("RW"), .volatile(0), .reset('h0), .has_reset(1), .is_rand(1), .individually_accessible(0));
    SS_EN.configure (.parent(this), .size(4),  .lsb_pos(0), .access("RW"), .volatile(0), .reset('h0), .has_reset(1), .is_rand(1), .individually_accessible(0));
  endfunction
endclass

`endif