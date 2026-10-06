`ifndef STATUS_REG
`define STATUS_REG

import uvm_pkg::*;
`include "uvm_macros.svh"


class status_reg extends uvm_reg;
  `uvm_object_utils(status_reg)

  rand uvm_reg_field RSVD;      // [31:7]
  rand uvm_reg_field RX_OVF;    // [6]
  rand uvm_reg_field TX_OVF;    // [5]
  rand uvm_reg_field RX_EMPTY;  // [4]
  rand uvm_reg_field RX_FULL;   // [3]
  rand uvm_reg_field TX_EMPTY;  // [2]
  rand uvm_reg_field TX_FULL;   // [1]
  rand uvm_reg_field BUSY;      // [0]

  function new(string name = "status_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    RSVD     = uvm_reg_field::type_id::create("RSVD");
    RX_OVF   = uvm_reg_field::type_id::create("RX_OVF");
    TX_OVF   = uvm_reg_field::type_id::create("TX_OVF");
    RX_EMPTY = uvm_reg_field::type_id::create("RX_EMPTY");
    RX_FULL  = uvm_reg_field::type_id::create("RX_FULL");
    TX_EMPTY = uvm_reg_field::type_id::create("TX_EMPTY");
    TX_FULL  = uvm_reg_field::type_id::create("TX_FULL");
    BUSY     = uvm_reg_field::type_id::create("BUSY");

    // All fields are RO and volatile (hardware changes them)
    RSVD.configure    (.parent(this), .size(25), .lsb_pos(7), .access("RO"), .volatile(0), .reset('h0), .has_reset(1), .is_rand(0), .individually_accessible(0));
    RX_OVF.configure  (.parent(this), .size(1),  .lsb_pos(6), .access("RO"), .volatile(1), .reset('h0), .has_reset(1), .is_rand(0), .individually_accessible(0));
    TX_OVF.configure  (.parent(this), .size(1),  .lsb_pos(5), .access("RO"), .volatile(1), .reset('h0), .has_reset(1), .is_rand(0), .individually_accessible(0));
    RX_EMPTY.configure(.parent(this), .size(1),  .lsb_pos(4), .access("RO"), .volatile(1), .reset('h1), .has_reset(1), .is_rand(0), .individually_accessible(0));
    RX_FULL.configure (.parent(this), .size(1),  .lsb_pos(3), .access("RO"), .volatile(1), .reset('h0), .has_reset(1), .is_rand(0), .individually_accessible(0));
    TX_EMPTY.configure(.parent(this), .size(1),  .lsb_pos(2), .access("RO"), .volatile(1), .reset('h0), .has_reset(1), .is_rand(0), .individually_accessible(0));
    TX_FULL.configure (.parent(this), .size(1),  .lsb_pos(1), .access("RO"), .volatile(1), .reset('h1), .has_reset(1), .is_rand(0), .individually_accessible(0));
    BUSY.configure    (.parent(this), .size(1),  .lsb_pos(0), .access("RO"), .volatile(1), .reset('h0), .has_reset(1), .is_rand(0), .individually_accessible(0));
  endfunction
endclass

`endif