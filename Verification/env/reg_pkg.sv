package reg_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // one file per register
  `include "ctrl_reg.sv"
  `include "status_reg.sv"
  `include "tx_data_reg.sv"
  `include "rx_data_reg.sv"
  `include "clk_div_reg.sv"
  `include "ss_ctrl_reg.sv"
  `include "int_en_reg.sv"
  `include "int_state_reg.sv"
  `include "delay_reg.sv"
  `include "spi_reg_block.sv"

endpackage : reg_pkg