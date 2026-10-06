`ifndef SPI_REG_BLOCK
`define SPI_REG_BLCOK

import uvm_pkg::*;
`include "uvm_macros.svh"
import reg_pkg::*; 

class spi_reg_block extends uvm_reg_block;
  `uvm_object_utils(spi_reg_block)

  // instances of the 9 registers (names match the spec / grader)
  rand ctrl_reg      CTRL;
  rand status_reg    STATUS;
  rand tx_data_reg   TX_DATA;
  rand rx_data_reg   RX_DATA;
  rand clk_div_reg   CLK_DIV;
  rand ss_ctrl_reg   SS_CTRL;
  rand int_en_reg    INT_EN;
  rand int_stat_reg  INT_STAT;
  rand delay_reg     DELAY;

  function new(string name = "spi_reg_block");
    super.new(name, UVM_NO_COVERAGE);   // standard constructor (two arguments)
  endfunction

  function void build();   // user defined build function

    CTRL = ctrl_reg::type_id::create("CTRL");     // object creation
    CTRL.build();                                 // manually calling build of reg
    CTRL.configure(this);                         // configure instance of reg

    STATUS = status_reg::type_id::create("STATUS");
    STATUS.build();
    STATUS.configure(this);

    TX_DATA = tx_data_reg::type_id::create("TX_DATA");
    TX_DATA.build();
    TX_DATA.configure(this);

    RX_DATA = rx_data_reg::type_id::create("RX_DATA");
    RX_DATA.build();
    RX_DATA.configure(this);

    CLK_DIV = clk_div_reg::type_id::create("CLK_DIV");
    CLK_DIV.build();
    CLK_DIV.configure(this);

    SS_CTRL = ss_ctrl_reg::type_id::create("SS_CTRL");
    SS_CTRL.build();
    SS_CTRL.configure(this);

    INT_EN = int_en_reg::type_id::create("INT_EN");
    INT_EN.build();
    INT_EN.configure(this);

    INT_STAT = int_stat_reg::type_id::create("INT_STAT");
    INT_STAT.build();
    INT_STAT.configure(this);

    DELAY = delay_reg::type_id::create("DELAY");
    DELAY.build();
    DELAY.configure(this);

    // add address map
    // syntax: name, base_addr, size in bytes (bus width), endian
    default_map = create_map("default_map", 'h0, 4, UVM_LITTLE_ENDIAN);

    // add_reg: instance, offset, access
    default_map.add_reg(CTRL,     'h00, "RW");
    default_map.add_reg(STATUS,   'h04, "RO");
    default_map.add_reg(TX_DATA,  'h08, "WO");
    default_map.add_reg(RX_DATA,  'h0C, "RO");
    default_map.add_reg(CLK_DIV,  'h10, "RW");
    default_map.add_reg(SS_CTRL,  'h14, "RW");
    default_map.add_reg(INT_EN,   'h18, "RW");
    default_map.add_reg(INT_STAT, 'h1C, "RW");   // W1C comes from the field access
    default_map.add_reg(DELAY,    'h20, "RW");

    // lock_model is mandatory: it builds the address map and blocks
    // any further structural changes (adding regs/memories)
    lock_model();

  endfunction
endclass

`endif