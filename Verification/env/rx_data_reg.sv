`ifndef RX_DATA_REG_SV
`define RX_DATA_REG_SV

import uvm_pkg::*;
`include "uvm_macros.svh"


class rx_data_reg extends uvm_reg;
  `uvm_object_utils(rx_data_reg)

  rand uvm_reg_field DATA;   // [31:0]

  function new(string name = "rx_data_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    DATA = uvm_reg_field::type_id::create("DATA");
    DATA.configure(.parent(this), .size(32), .lsb_pos(0), .access("RO"), .volatile(1), .reset('h0), .has_reset(1), .is_rand(0), .individually_accessible(1));
  endfunction
endclass
`endif