`ifndef CLK_DIV_REG
`define CLK_DIV_REG

import uvm_pkg::*;
`include "uvm_macros.svh"

class clk_div_reg extends uvm_reg;
  `uvm_object_utils(clk_div_reg)

  rand uvm_reg_field RSVD;   // [31:16]
  rand uvm_reg_field DIV;    // [15:0]

  function new(string name = "clk_div_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    RSVD = uvm_reg_field::type_id::create("RSVD");
    DIV  = uvm_reg_field::type_id::create("DIV");

    RSVD.configure(.parent(this), .size(16), .lsb_pos(16), .access("RO"), .volatile(0), .reset('h0), .has_reset(1), .is_rand(0), .individually_accessible(0));
    DIV.configure (.parent(this), .size(16), .lsb_pos(0),  .access("RW"), .volatile(0), .reset('h0), .has_reset(1), .is_rand(1), .individually_accessible(0));
  endfunction
endclass

`endif