package spi_test_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import reg_pkg::*;
  import spi_pkg::*;
  import spi_seq_pkg::*;

  `include "../sequences/reg_rw_sequences.sv"
  `include "base_test.sv"
  `include "reg_rw_test.sv"
  `include "spi_idle_test.sv"
  `include "spi_req_tests.sv"

endpackage : spi_test_pkg