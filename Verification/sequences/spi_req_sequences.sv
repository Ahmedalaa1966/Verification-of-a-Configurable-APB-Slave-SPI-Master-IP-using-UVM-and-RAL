`ifndef SPI_REQ_SEQUENCES_SV
`define SPI_REQ_SEQUENCES_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_seq_pkg::*;
import reg_pkg::*; 


class spi_req_seq extends apb_base_seq;
  spi_reg_block  reg_block;      // set by the test
  virtual spi_if vif;            // set by the test

  localparam int ST_BUSY = 0, ST_TX_FULL = 1, ST_TX_EMPTY = 2, ST_RX_FULL = 3,
                 ST_RX_EMPTY = 4, ST_TX_OVF = 5, ST_RX_OVF = 6;
  localparam int I_TXE = 0, I_RXF = 1, I_TXO = 2, I_RXO = 3, I_DONE = 4;   // INT_STAT bits

  function new(string name = "spi_req_seq");
    super.new(name);
  endfunction

  task wr(uvm_reg r, bit [31:0] v);
    uvm_status_e s;
    r.write(s, v);
  endtask

  task rd(uvm_reg r, output bit [31:0] v);
    uvm_status_e   s;
    uvm_reg_data_t d;
    r.read(s, d);
    v = d;
  endtask

  function void chk(bit ok, string id, string msg);
    if (ok) `uvm_info(id, {"PASS: ", msg}, UVM_LOW)
    else    `uvm_error(id, {"FAIL: ", msg})
  endfunction

  function bit [31:0] mask(bit [1:0] w);
    return (w == 0) ? 32'hFF : (w == 1) ? 32'hFFFF : 32'hFFFF_FFFF;
  endfunction

  // wait until BUSY=0 and the TX FIFO is empty
  task wait_done();
    bit [31:0] s;
    repeat (2) rd(reg_block.STATUS, s);
    repeat (20000) begin
      rd(reg_block.STATUS, s);
      if (!s[ST_BUSY] && s[ST_TX_EMPTY]) break;
    end
  endtask
endclass


// ================= R9..R15: FIFOs =================
class spi_fifo_seq extends spi_req_seq;
  `uvm_object_utils(spi_fifo_seq)
  function new(string name = "spi_fifo_seq"); super.new(name); endfunction

  task body();
    bit [31:0] s, v;
    int        first_full = 0;

    wr(reg_block.CLK_DIV, 255);          // slow, so the TX FIFO fills up
    wr(reg_block.CTRL, 32'h23);          // loopback, master, enable, 8-bit, mode 0

    for (int i = 1; i <= 8; i++) begin   // R9, R11: fill the TX FIFO in order
      wr(reg_block.TX_DATA, 32'h11 * i);
      rd(reg_block.STATUS, s);
      if (s[ST_TX_FULL] && first_full == 0) first_full = i;
    end
    chk(first_full == 8, "R11", $sformatf("TX_FULL asserted on write #%0d (expected 8)", first_full));

    wr(reg_block.TX_DATA, 32'hEE);       // R13: write while TX_FULL is discarded
    rd(reg_block.STATUS, s);   chk(s[ST_TX_OVF], "R13", "STATUS.TX_OVF set");
    rd(reg_block.INT_STAT, v); chk(v[I_TXO],     "R13", "INT_STAT[TX_OVF] set");
    wr(reg_block.INT_STAT, 32'h1F);

    wr(reg_block.CLK_DIV, 0);            // the running word keeps its slow DIV (R25), the rest go fast
    wait_done();
    rd(reg_block.STATUS, s);
    chk(s[ST_RX_FULL] && !s[ST_RX_EMPTY], "R12", "RX_FULL after 8 received words");

    wr(reg_block.TX_DATA, 32'h99);       // R14: transfer completes while RX_FULL
    wait_done();
    rd(reg_block.STATUS, s);   chk(s[ST_RX_OVF], "R14", "STATUS.RX_OVF set");
    rd(reg_block.INT_STAT, v); chk(v[I_RXO],     "R14", "INT_STAT[RX_OVF] set");
    wr(reg_block.INT_STAT, 32'h1F);

    for (int i = 1; i <= 8; i++) begin   // R10: FIFO order; 0x99 was discarded, 0xEE never sent
      rd(reg_block.RX_DATA, v);
      chk(v == 32'h11 * i, "R10", $sformatf("RX word %0d = 0x%0h (expected 0x%0h)", i, v, 32'h11 * i));
    end
    rd(reg_block.STATUS, s);   chk(s[ST_RX_EMPTY], "R10", "RX FIFO empty after 8 reads");

    rd(reg_block.RX_DATA, v);  chk(v == 0, "R15", "RX_DATA read while empty returns 0");
    rd(reg_block.INT_STAT, v); chk(!v[I_RXO], "R15", "empty read did not set RX_OVF");
  endtask
endclass


// ================= R16..R18: interrupts =================
class spi_irq_seq extends spi_req_seq;
  `uvm_object_utils(spi_irq_seq)
  function new(string name = "spi_irq_seq"); super.new(name); endfunction

  task body();
    bit [31:0] stat, s0, s1, s2, s;
    bit [4:0]  ens[4] = '{5'h00, 5'h10, 5'h0F, 5'h1F};
    bit [7:0]  res = 0;
    bit        seen0 = 0, bad = 0;

    wr(reg_block.INT_EN, 0);
    wr(reg_block.CLK_DIV, 0);
    wr(reg_block.CTRL, 32'h23);
    wr(reg_block.TX_DATA, 32'hA5);
    wait_done();

    rd(reg_block.INT_STAT, stat);        // R16: status is captured even with INT_EN = 0
    chk(stat[I_DONE], "R16", "INT_STAT[DONE] set while INT_EN=0");

    foreach (ens[i]) begin               // R16: IRQ = |(INT_STAT & INT_EN)
      wr(reg_block.INT_EN, ens[i]);
      repeat (3) @(posedge vif.pclk);
      rd(reg_block.INT_STAT, stat);
      chk(vif.irq === (|(stat[4:0] & ens[i])), "R16",
          $sformatf("IRQ=%0b with INT_STAT=0x%0h INT_EN=0x%0h", vif.irq, stat, ens[i]));
    end

    wr(reg_block.INT_EN, 0);             // R17: W1C
    rd(reg_block.INT_STAT, s0);
    wr(reg_block.INT_STAT, 0);
    rd(reg_block.INT_STAT, s1); chk(s1 == s0, "R17", "writing 0 changes nothing");
    wr(reg_block.INT_STAT, 32'h10);
    rd(reg_block.INT_STAT, s2); chk(s2 == (s0 & ~32'h10), "R17", "writing 1 clears only that bit");

    for (int k = 0; k < 8; k++) begin    // R18: W1C right around the event (best effort)
      int edges = 0, clks = 0;
      bit prev;
      wr(reg_block.INT_STAT, 32'h1F);
      prev = vif.sclk;
      fork wr(reg_block.TX_DATA, 32'hA5); join_none
      while (edges < 16 && clks < 2000) begin
        @(posedge vif.pclk);
        clks++;
        if (vif.sclk !== prev) edges++;
        prev = vif.sclk;
      end
      repeat (k) @(posedge vif.pclk);
      wr(reg_block.INT_STAT, 32'h10);
      rd(reg_block.INT_STAT, s);
      res[k] = s[I_DONE];
      wait_done();
    end
    for (int k = 0; k < 8; k++) begin
      if (!res[k]) seen0 = 1; else if (seen0) bad = 1;
    end
    chk(!bad, "R18", $sformatf("DONE bit after W1C at +0..+7 clocks = %b (must be 1s then 0s)", res));
  endtask
endclass


// ================= R3, R19, R20, R25: control =================
class spi_ctrl_seq extends spi_req_seq;
  `uvm_object_utils(spi_ctrl_seq)
  function new(string name = "spi_ctrl_seq"); super.new(name); endfunction

  task body();
    bit [31:0] s, v, data;
    bit [7:0]  ss;
    bit [3:0]  exp;
    bit [1:0]  w;
    int        bad;

    // R3: EN=0 -> SCLK at CPOL, SS_n high even with SS_CTRL asserting all, FIFOs stay empty
    for (int m = 0; m < 4; m++) begin
      bad = 0;
      wr(reg_block.SS_CTRL, 32'h0F);
      wr(reg_block.CTRL, (m << 2) | 32'h22);              // EN=0, master, loopback
      wr(reg_block.TX_DATA, 32'hA5);                      // must be dropped
      repeat (60) begin
        @(posedge vif.pclk);
        if (vif.sclk !== m[1] || vif.ss_n !== 4'hF) bad++;
      end
      rd(reg_block.STATUS, s);
      chk(bad == 0, "R3", $sformatf("mode %0d: SCLK at CPOL and SS_n high with EN=0", m));
      chk(s[ST_TX_EMPTY] && s[ST_RX_EMPTY] && !s[ST_BUSY], "R3", $sformatf("mode %0d: FIFOs empty, not busy", m));
    end

    // R20: SS_n[i] = !SS_EN[i] | SS_VAL[i]   (SS_EN = SS_CTRL[3:0], SS_VAL = SS_CTRL[7:4])
    wr(reg_block.CTRL, 32'h23);
    bad = 0;
    for (int i = 0; i < 256; i++) begin
      ss = i;
      wr(reg_block.SS_CTRL, ss);
      repeat (2) @(posedge vif.pclk);
      exp = ~ss[3:0] | ss[7:4];
      if (vif.ss_n !== exp) bad++;
    end
    chk(bad == 0, "R20", "SS_n follows SS_CTRL for all 256 values");

    bad = 0;
    wr(reg_block.SS_CTRL, 32'h05);                         // SS_n must not move during a transfer
    exp = ~4'h5 | 4'h0;
    wr(reg_block.CLK_DIV, 1);
    wr(reg_block.TX_DATA, 32'hA5);
    repeat (100) begin
      @(posedge vif.pclk);
      if (vif.ss_n !== exp) bad++;
    end
    wait_done();
    chk(bad == 0, "R20", "SS_n not driven by the IP during a transfer");
    wr(reg_block.SS_CTRL, 0);
    rd(reg_block.RX_DATA, v);

    // R19: loopback, RX = TX for every width
    data = 32'hA5C3_1E87;
    for (int i = 0; i < 3; i++) begin
      w = i;
      wr(reg_block.CLK_DIV, 1);
      wr(reg_block.CTRL, {24'b0, w, 1'b1, 1'b0, 2'b00, 1'b1, 1'b1});
      wr(reg_block.TX_DATA, data);
      wait_done();
      rd(reg_block.RX_DATA, v);
      chk(v == (data & mask(w)), "R19", $sformatf("width_sel %0d: RX 0x%0h, expected 0x%0h", w, v, data & mask(w)));
    end

    // R25: change DIV / MODE / WIDTH / LSB while a transfer runs -> that transfer is unchanged
    wr(reg_block.CLK_DIV, 255);
    wr(reg_block.CTRL, 32'h63);                            // 16-bit, loopback, mode 0, MSB first
    wr(reg_block.TX_DATA, 32'hA5C3);
    wr(reg_block.CLK_DIV, 0);
    wr(reg_block.CTRL, 32'h3F);                            // 8-bit, loopback, mode 3, LSB first
    wait_done();
    rd(reg_block.RX_DATA, v);
    chk(v == 32'hA5C3, "R25", $sformatf("config held for the running transfer: RX 0x%0h (expected 0xA5C3)", v));
  endtask
endclass


// ================= R21, R23: delay, reserved offsets =================
class spi_misc_seq extends spi_req_seq;
  `uvm_object_utils(spi_misc_seq)
  function new(string name = "spi_misc_seq"); super.new(name); endfunction

  // two queued 8-bit words, DIV=1: returns the largest gap between SCLK edges
  task gap_run(int d, output int maxgap);
    int        edges = 0, clks = 0, last = -1;
    bit        prev;
    bit [31:0] v;

    maxgap = 0;
    wr(reg_block.DELAY, d);
    wr(reg_block.CLK_DIV, 1);
    wr(reg_block.CTRL, 32'h23);
    prev = vif.sclk;
    fork
      begin
        wr(reg_block.TX_DATA, 32'hA5);
        wr(reg_block.TX_DATA, 32'h5A);
      end
      begin
        while (edges < 32 && clks < 3000) begin
          @(posedge vif.pclk);
          clks++;
          if (vif.sclk !== prev) begin
            edges++;
            if (last >= 0 && clks - last > maxgap) maxgap = clks - last;
            last = clks;
          end
          prev = vif.sclk;
        end
      end
    join
    wait_done();
    rd(reg_block.RX_DATA, v);
    rd(reg_block.RX_DATA, v);
  endtask

  task body();
    int        g0, g1;
    bit [31:0] v, ctrl_v;
    bit [7:0]  rsv[5] = '{8'h24, 8'h28, 8'h3C, 8'h40, 8'hFC};

    // R21: DELAY = 10 half-cycles adds 10 x (DIV+1) = 20 PCLK between consecutive words
    gap_run(0,  g0);
    gap_run(10, g1);
    chk(g1 - g0 == 20, "R21", $sformatf("gap grew by %0d PCLK for DELAY=10 (expected 20)", g1 - g0));
    wr(reg_block.DELAY, 0);

    // R23: reserved offsets read 0, writes are ignored (and do not alias onto real registers)
    wr(reg_block.CLK_DIV, 32'h1234);
    wr(reg_block.CTRL, 32'h20);
    foreach (rsv[i]) write_reg(rsv[i], 32'hFFFF_FFFF);
    foreach (rsv[i]) begin
      read_reg(rsv[i], v);
      chk(v == 0, "R23", $sformatf("offset 0x%0h reads 0", rsv[i]));
    end
    rd(reg_block.CLK_DIV, v);   chk(v == 32'h1234, "R23", "CLK_DIV unchanged by reserved writes");
    rd(reg_block.CTRL, ctrl_v); chk(ctrl_v == 32'h20, "R23", "CTRL unchanged by reserved writes");
  endtask
endclass

`endif