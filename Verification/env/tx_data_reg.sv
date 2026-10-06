`ifndef TX_DATA_REG
`define TX_DATA_REG

import uvm_pkg::*;
`include "uvm_macros.svh"


class tx_data_reg extends uvm_reg;
  `uvm_object_utils(tx_data_reg)

  rand uvm_reg_field DATA;   // [31:0]

  function new(string name = "tx_data_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    DATA = uvm_reg_field::type_id::create("DATA");
    DATA.configure(.parent(this), .size(32), .lsb_pos(0), .access("WO"), .volatile(1), .reset('h0), .has_reset(1), .is_rand(1), .individually_accessible(1));
  endfunction
endclass

`endif