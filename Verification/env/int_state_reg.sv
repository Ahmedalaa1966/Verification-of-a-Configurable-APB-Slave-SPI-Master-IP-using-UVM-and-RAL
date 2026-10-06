`ifndef INT_STATE_REG
`define INT_STATE_REG

import uvm_pkg::*;
`include "uvm_macros.svh"

class int_stat_reg extends uvm_reg;
  `uvm_object_utils(int_stat_reg)

  rand uvm_reg_field RSVD;           // [31:5]
  rand uvm_reg_field TRANSFER_DONE;  // [4]
  rand uvm_reg_field RX_OVF;         // [3]
  rand uvm_reg_field TX_OVF;         // [2]
  rand uvm_reg_field RX_FULL;        // [1]
  rand uvm_reg_field TX_EMPTY;       // [0]

  function new(string name = "int_stat_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    RSVD          = uvm_reg_field::type_id::create("RSVD");
    TRANSFER_DONE = uvm_reg_field::type_id::create("TRANSFER_DONE");
    RX_OVF        = uvm_reg_field::type_id::create("RX_OVF");
    TX_OVF        = uvm_reg_field::type_id::create("TX_OVF");
    RX_FULL       = uvm_reg_field::type_id::create("RX_FULL");
    TX_EMPTY      = uvm_reg_field::type_id::create("TX_EMPTY");

    // "W1C" = write-1-to-clear, volatile because hardware sets the bits
    RSVD.configure         (.parent(this), .size(27), .lsb_pos(5), .access("RO"),  .volatile(0), .reset('h0), .has_reset(1), .is_rand(0), .individually_accessible(0));
    TRANSFER_DONE.configure(.parent(this), .size(1),  .lsb_pos(4), .access("W1C"), .volatile(1), .reset('h0), .has_reset(1), .is_rand(1), .individually_accessible(0));
    RX_OVF.configure       (.parent(this), .size(1),  .lsb_pos(3), .access("W1C"), .volatile(1), .reset('h0), .has_reset(1), .is_rand(1), .individually_accessible(0));
    TX_OVF.configure       (.parent(this), .size(1),  .lsb_pos(2), .access("W1C"), .volatile(1), .reset('h0), .has_reset(1), .is_rand(1), .individually_accessible(0));
    RX_FULL.configure      (.parent(this), .size(1),  .lsb_pos(1), .access("W1C"), .volatile(1), .reset('h0), .has_reset(1), .is_rand(1), .individually_accessible(0));
    TX_EMPTY.configure     (.parent(this), .size(1),  .lsb_pos(0), .access("W1C"), .volatile(1), .reset('h0), .has_reset(1), .is_rand(1), .individually_accessible(0));
  endfunction
endclass

`endif