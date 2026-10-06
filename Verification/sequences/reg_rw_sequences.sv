`ifndef REG_RW_SEQUENCES_SV
`define REG_RW_SEQUENCES_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_seq_pkg::*;
import reg_pkg::*; 


class apb_reg_rw_seq extends apb_base_seq;
  `uvm_object_utils(apb_reg_rw_seq)

  spi_reg_block reg_block;   // set by the test

  function new(string name = "apb_reg_rw_seq");
    super.new(name);
  endfunction

 task reset_check();
    uvm_reg        regs[$];
    uvm_status_e   status;
    uvm_reg_data_t rdata;

    reg_block.get_registers(regs);
    foreach (regs[i]) begin
      regs[i].read(status, rdata, UVM_FRONTDOOR, .parent(this));
      if (rdata === regs[i].get_reset())
        `uvm_info("R2", $sformatf("PASS %s: reset value 0x%0h", regs[i].get_name(), rdata), UVM_LOW)
      else
        `uvm_error("R2", $sformatf("FAIL %s: got 0x%0h, expected 0x%0h",
                                   regs[i].get_name(), rdata, regs[i].get_reset()))
    end
  endtask

  // R1: write, read back, compare with the model
  task rw_check(uvm_reg r, bit [31:0] wdata);
    uvm_status_e   status;
    uvm_reg_data_t rdata, expected;

    r.write(status, wdata, UVM_FRONTDOOR, .parent(this));
    expected = r.get_mirrored_value();
    r.read(status, rdata, UVM_FRONTDOOR, .parent(this));

    if (rdata === expected)
      `uvm_info("R1", $sformatf("PASS %s: wrote 0x%0h, read 0x%0h", r.get_name(), wdata, rdata), UVM_LOW)
    else
      `uvm_error("R1", $sformatf("FAIL %s: wrote 0x%0h, got 0x%0h, expected 0x%0h",
                                 r.get_name(), wdata, rdata, expected))
  endtask

  task body();
    bit [31:0] patterns[4] = '{32'h5555_5555, 32'hAAAA_AAAA, 32'hFFFF_FFFF, 32'h0000_0000};

    reset_check();   // must be first, before any write

    foreach (patterns[i]) begin
      rw_check(reg_block.CLK_DIV, patterns[i]);
      rw_check(reg_block.SS_CTRL, patterns[i]);
      rw_check(reg_block.INT_EN,  patterns[i]);
      rw_check(reg_block.DELAY,   patterns[i]);
      rw_check(reg_block.CTRL,    patterns[i] & ~32'h1);   // EN=0 so no transfer starts
    end
  endtask
endclass

`endif