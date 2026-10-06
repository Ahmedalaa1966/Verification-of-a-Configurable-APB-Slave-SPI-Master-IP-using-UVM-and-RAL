`ifndef REF_MODEL_SV
`define REF_MODEL_SV


import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_pkg::*; 


class ref_model extends uvm_component;
    `uvm_component_utils(ref_model)

    // Analysis imports from APB and SPI monitors
    uvm_analysis_imp_apb #(apb_seq_item, ref_model) apb_imp;
    uvm_analysis_imp_spi #(spi_seq_item, ref_model) spi_imp;

    // Analysis ports (predictions)
    uvm_analysis_port #(spi_seq_item) pred_port;
    uvm_analysis_port #(apb_seq_item) reg_pred_port;

    // ---- Mirrored register state ----
    logic        ctrl_en, ctrl_mstr, ctrl_lsb_first, ctrl_loopback;
    logic [1:0]  ctrl_mode, ctrl_width;
    logic [15:0] clk_div;
    logic [7:0]  delay_cfg;
    logic [3:0]  ss_en, ss_val;
    logic [4:0]  int_en, int_stat;

    // FIFO models
    logic [31:0] tx_fifo[$];
    logic [31:0] rx_fifo[$];

    localparam [31:0] RST_STATUS = 32'h0000_0014;   // TX_EMPTY + RX_EMPTY

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        apb_imp       = new("apb_imp", this);
        spi_imp       = new("spi_imp", this);
        pred_port     = new("pred_port", this);
        reg_pred_port = new("reg_pred_port", this);
        reset_state();
    endfunction

    function void reset_state();
        ctrl_en       = 0; ctrl_mstr      = 0;
        ctrl_mode     = 0; ctrl_lsb_first = 0;
        ctrl_loopback = 0; ctrl_width     = 0;
        clk_div       = 0; delay_cfg      = 0;
        ss_en = 0; ss_val = 0;
        int_en = 0; int_stat = 0;
        tx_fifo.delete(); rx_fifo.delete();
    endfunction

    // APB write handling - mirrors DUT register updates
    function void write_apb(apb_seq_item t);
        if (!t.pwrite) return;                       // reads handled separately
        case (t.paddr)
            8'h00: begin  // CTRL
                ctrl_width     = t.pwdata[7:6];
                ctrl_loopback  = t.pwdata[5];
                ctrl_lsb_first = t.pwdata[4];
                ctrl_mode      = t.pwdata[3:2];
                ctrl_mstr      = t.pwdata[1];
                if (ctrl_en && !t.pwdata[0]) begin   // EN going 0: flush FIFOs
                    tx_fifo.delete(); rx_fifo.delete();
                end
                ctrl_en = t.pwdata[0];
            end
            8'h08: begin  // TX_DATA write
                if (ctrl_en) begin
                    if (tx_fifo.size() < 8) begin
                        logic [31:0] masked;
                        case (ctrl_width)
                            2'b00:   masked = {24'b0, t.pwdata[7:0]};
                            2'b01:   masked = {16'b0, t.pwdata[15:0]};
                            default: masked = t.pwdata;
                        endcase
                        tx_fifo.push_back(masked);
                    end else begin
                        int_stat[2] = 1'b1;          // TX overflow
                    end
                end
            end
            8'h10: clk_div = t.pwdata[15:0];
            8'h14: begin ss_val = t.pwdata[7:4]; ss_en = t.pwdata[3:0]; end
            8'h18: int_en = t.pwdata[4:0];
            8'h1C: int_stat = int_stat & ~t.pwdata[4:0];   // W1C
            8'h20: delay_cfg = t.pwdata[7:0];
        endcase
    endfunction

    // Called when a SPI transfer completes
    function void write_spi(spi_seq_item t);
        spi_seq_item pred = new("pred");
        logic [31:0] expected_rx;
        int          nbits;

        nbits = (t.width_sel == 2'b00) ? 8 : (t.width_sel == 2'b01) ? 16 : 32;

        // Predict RX: loopback -> MOSI, else MISO captured from slave
        if (ctrl_loopback) expected_rx = t.mosi_data;
        else               expected_rx = t.miso_data;

        // Mask to width
        if (nbits < 32) expected_rx &= (32'h1 << nbits) - 1;

        pred.mosi_data = t.mosi_data;
        pred.miso_data = expected_rx;
        pred.mode      = t.mode;
        pred.width_sel = t.width_sel;
        pred.lsb_first = t.lsb_first;

        pred_port.write(pred);

        // Update RX FIFO model
        if (rx_fifo.size() < 8) rx_fifo.push_back(expected_rx);
        else                    int_stat[3] = 1'b1;   // RX overflow

        // TX drain model
        if (tx_fifo.size() > 0) void'(tx_fifo.pop_front());

        // TRANSFER_DONE interrupt
        int_stat[4] = 1'b1;
    endfunction

    function void write(apb_seq_item t);
        write_apb(t);
    endfunction

    function void process_spi(spi_seq_item t);
        write_spi(t);
    endfunction

endclass

`endif