package spi_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

    `uvm_analysis_imp_decl(_apb)
  `uvm_analysis_imp_decl(_spi)


  `include "apb_seq_item.sv"
  `include "apb_sequencer.sv"
  `include "apb_driver.sv"
  `include "apb_monitor.sv"
  `include "apb_agent.sv"
  `include "apb_reg_adaptor.sv"
  `include "spi_seq_item.sv"
  `include "spi_sequencer.sv"
  `include "spi_driver.sv"
  `include "spi_monitor.sv"
  `include "spi_agent.sv"
  //`include "spi_reg_block.sv"
  `include "ref_model.sv"
  `include "scoreboard.sv"
  `include "coverage.sv"
  `include "env.sv"


endpackage : spi_pkg