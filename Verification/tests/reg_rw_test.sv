`ifndef REG_RW_TEST_SV
`define REG_RW_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_test_pkg::*;
import spi_seq_pkg::*;

class spi_reg_rw_test extends spi_base_test;
  `uvm_component_utils(spi_reg_rw_test)

  function new(string name = "spi_reg_rw_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_scenario();
    apb_reg_rw_seq seq = apb_reg_rw_seq::type_id::create("seq");
    seq.reg_block = env.reg_block;     // hand the RAL model to the sequence
    seq.start(env.apb_agt.sequencer);
  endtask

endclass

`endif