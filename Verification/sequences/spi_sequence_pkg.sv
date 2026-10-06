
package spi_seq_pkg;

  import uvm_pkg::*;
  import spi_pkg::*;

  // base sequences first, then anything that extends them
  `include "apb_base_sequence.sv"
  `include "spi_base_sequence.sv"
  `include "spi_idle_sequence.sv"
  `include "spi_req_sequences.sv"

endpackage : spi_seq_pkg