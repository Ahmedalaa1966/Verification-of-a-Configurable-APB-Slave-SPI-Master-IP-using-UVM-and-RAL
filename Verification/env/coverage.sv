`ifndef COVERAGE_SV
`define COVERAGE_SV


import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_pkg::*; 

class spi_coverage extends uvm_subscriber #(spi_seq_item);
  `uvm_component_utils(spi_coverage)

  uvm_analysis_imp_apb #(apb_seq_item, spi_coverage) apb_export;   // APB items (SPI items come through the subscriber's own export)
  ref_model model;                                                 // set in the env, used for FIFO occupancy

  // values sampled by the covergroups
  logic [1:0]  cv_mode, cv_width;
  logic        cv_lsb_first;
  logic [7:0]  cv_addr;
  logic        cv_write;
  logic [15:0] cv_clk_div;
  logic [7:0]  cv_delay;
  logic [4:0]  cv_int_stat;
  int          cv_tx_count, cv_rx_count;

  // ===== SPI mode x width x bit order (24 bins) =====
  covergroup cg_spi_config;
    option.per_instance = 1;
    cp_mode  : coverpoint cv_mode      { bins mode0 = {0}; bins mode1 = {1}; bins mode2 = {2}; bins mode3 = {3}; }
    cp_width : coverpoint cv_width     { bins w8 = {0}; bins w16 = {1}; bins w32 = {2}; }
    cp_order : coverpoint cv_lsb_first { bins msb_first = {0}; bins lsb_first = {1}; }
    cx_all   : cross cp_mode, cp_width, cp_order;
  endgroup

  // ===== APB register x read/write =====
  covergroup cg_apb_regs;
    option.per_instance = 1;
    cp_reg : coverpoint cv_addr {
      bins ctrl = {8'h00};     bins status  = {8'h04};  bins tx_data = {8'h08};
      bins rx_data = {8'h0C};  bins clk_div = {8'h10};  bins ss_ctrl = {8'h14};
      bins int_en = {8'h18};   bins int_stat = {8'h1C}; bins delay_r = {8'h20};
    }
    cp_op : coverpoint cv_write { bins wr = {1}; bins rd = {0}; }
    cx_reg_op : cross cp_reg, cp_op;
  endgroup

  // ===== CLK_DIV corners =====
  covergroup cg_clk_div;
    option.per_instance = 1;
    cp_div : coverpoint cv_clk_div {
      bins div0 = {0};  bins div1 = {1};  bins div2 = {2};  bins div3 = {3};
      bins div255 = {16'h00FF};  bins div65535 = {16'hFFFF};
      bins div_mid = {[4:254]};  bins div_large = {[256:65534]};
    }
  endgroup

  // ===== DELAY =====
  covergroup cg_delay;
    option.per_instance = 1;
    cp_delay : coverpoint cv_delay {
      bins delay0 = {0};  bins delay1 = {1};
      bins delay_mid = {[2:127]};  bins delay_large = {[128:255]};
    }
  endgroup

  // ===== FIFO occupancy =====
  covergroup cg_fifo_occ;
    option.per_instance = 1;
    cp_tx : coverpoint cv_tx_count { bins empty = {0}; bins one = {1}; bins mid = {[2:6]}; bins seven = {7}; bins full = {8}; }
    cp_rx : coverpoint cv_rx_count { bins empty = {0}; bins one = {1}; bins mid = {[2:6]}; bins seven = {7}; bins full = {8}; }
  endgroup

  // ===== Interrupt status bits seen set =====
  covergroup cg_interrupts;
    option.per_instance = 1;
    cp_tx_empty : coverpoint cv_int_stat[0] { bins set = {1}; }
    cp_rx_full  : coverpoint cv_int_stat[1] { bins set = {1}; }
    cp_tx_ovf   : coverpoint cv_int_stat[2] { bins set = {1}; }
    cp_rx_ovf   : coverpoint cv_int_stat[3] { bins set = {1}; }
    cp_txdone   : coverpoint cv_int_stat[4] { bins set = {1}; }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_spi_config = new();
    cg_apb_regs   = new();
    cg_clk_div    = new();
    cg_delay      = new();
    cg_fifo_occ   = new();
    cg_interrupts = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_export = new("apb_export", this);
  endfunction

  // SPI item arrives (subscriber write)
  function void write(spi_seq_item t);
    cv_mode      = t.mode;
    cv_width     = t.width_sel;
    cv_lsb_first = t.lsb_first;
    cg_spi_config.sample();
  endfunction

  // APB item arrives
  function void write_apb(apb_seq_item t);
    cv_addr  = t.paddr;
    cv_write = t.pwrite;
    cg_apb_regs.sample();

    if (model != null) begin
      cv_tx_count = model.tx_fifo.size();
      cv_rx_count = model.rx_fifo.size();
      cg_fifo_occ.sample();
    end

    if (t.pwrite && t.paddr == 8'h10) begin
      cv_clk_div = t.pwdata[15:0];
      cg_clk_div.sample();
    end
    if (t.pwrite && t.paddr == 8'h20) begin
      cv_delay = t.pwdata[7:0];
      cg_delay.sample();
    end
    if (!t.pwrite && t.paddr == 8'h1C) begin
      cv_int_stat = t.prdata[4:0];
      cg_interrupts.sample();
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("SPI config : %.1f%%", cg_spi_config.get_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("APB regs   : %.1f%%", cg_apb_regs.get_coverage()),   UVM_NONE)
    `uvm_info("COV", $sformatf("CLK_DIV    : %.1f%%", cg_clk_div.get_coverage()),    UVM_NONE)
    `uvm_info("COV", $sformatf("DELAY      : %.1f%%", cg_delay.get_coverage()),      UVM_NONE)
    `uvm_info("COV", $sformatf("FIFO occ   : %.1f%%", cg_fifo_occ.get_coverage()),   UVM_NONE)
    `uvm_info("COV", $sformatf("Interrupts : %.1f%%", cg_interrupts.get_coverage()), UVM_NONE)
  endfunction

endclass

`endif