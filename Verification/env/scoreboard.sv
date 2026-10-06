`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV



import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_pkg::*; 




class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    uvm_analysis_imp_apb #(apb_seq_item, scoreboard) apb_imp;
    uvm_analysis_imp_spi #(spi_seq_item, scoreboard) spi_imp;

    // Shadow TX FIFO for bus-listening
    logic [31:0] tx_shadow_fifo[$];

    // Register offsets
    localparam [7:0] OFF_CTRL     = 8'h00;
    localparam [7:0] OFF_STATUS   = 8'h04;
    localparam [7:0] OFF_TX_DATA  = 8'h08;
    localparam [7:0] OFF_RX_DATA  = 8'h0C;
    localparam [7:0] OFF_CLK_DIV  = 8'h10;
    localparam [7:0] OFF_SS_CTRL  = 8'h14;
    localparam [7:0] OFF_INT_EN   = 8'h18;
    localparam [7:0] OFF_INT_STAT = 8'h1C;
    localparam [7:0] OFF_DELAY    = 8'h20;

    // Shadow register state
    logic [31:0] shadow_ctrl     = 32'h0;
    logic [31:0] shadow_clk_div  = 32'h0;
    logic [31:0] shadow_ss_ctrl  = 32'h0;
    logic [31:0] shadow_int_en   = 32'h0;
    logic [31:0] shadow_delay    = 32'h0;
    logic [4:0]  shadow_int_stat = 5'h0;

    // RX FIFO model (predicted values the APB should return)
    logic [31:0] rx_expected[$];

    spi_seq_item spi_seen[$];
    int error_count = 0;
    int check_count = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        apb_imp = new("apb_imp", this);
        spi_imp = new("spi_imp", this);
    endfunction

    function void reset_expected_state();
        shadow_ctrl     = 32'h0;
        shadow_clk_div  = 32'h0;
        shadow_ss_ctrl  = 32'h0;
        shadow_int_en   = 32'h0;
        shadow_delay    = 32'h0;
        shadow_int_stat = 5'h0;
        rx_expected.delete();
        spi_seen.delete();
        tx_shadow_fifo.delete();
        `uvm_info("SB", "Scoreboard internal state hard-reset.", UVM_MEDIUM)
    endfunction

    // number of data bits for the CTRL width code
    function int get_nbits(bit [1:0] w);
        case (w)
            2'b00:   return 8;
            2'b01:   return 16;
            default: return 32;
        endcase
    endfunction

    // ---- APB transaction processing ----------------------------------------
    function void write_apb(apb_seq_item t);
        if (t.pwrite) process_write(t);
        else          process_read(t);
    endfunction

    function void process_write(apb_seq_item t);
        case (t.paddr)
            OFF_CTRL:     shadow_ctrl     = {24'h0, t.pwdata[7:0]};
            OFF_CLK_DIV:  shadow_clk_div  = {16'h0, t.pwdata[15:0]};
            OFF_SS_CTRL:  shadow_ss_ctrl  = {24'h0, t.pwdata[7:0]};
            OFF_INT_EN:   shadow_int_en   = {27'h0, t.pwdata[4:0]};
            OFF_DELAY:    shadow_delay    = {24'h0, t.pwdata[7:0]};
            OFF_INT_STAT: shadow_int_stat = shadow_int_stat & ~t.pwdata[4:0];

            OFF_TX_DATA: begin
                // Only push if SPI is enabled AND the FIFO is not full (depth < 8)
                if (shadow_ctrl[0] == 1'b1 && tx_shadow_fifo.size() < 8)
                    tx_shadow_fifo.push_back(t.pwdata);
                else
                    `uvm_info("SB", "TX write dropped by Scoreboard (SPI Disabled OR FIFO Full)", UVM_HIGH)
            end
        endcase
    endfunction

    function void process_read(apb_seq_item t);
        check_count++;
        case (t.paddr)
            OFF_CTRL, OFF_CLK_DIV, OFF_SS_CTRL, OFF_INT_EN, OFF_DELAY: begin
                logic [31:0] expected_val;
                if      (t.paddr == OFF_CTRL)    expected_val = shadow_ctrl;
                else if (t.paddr == OFF_CLK_DIV) expected_val = shadow_clk_div;
                else if (t.paddr == OFF_SS_CTRL) expected_val = shadow_ss_ctrl;
                else if (t.paddr == OFF_INT_EN)  expected_val = shadow_int_en;
                else                             expected_val = shadow_delay;

                if (t.prdata !== expected_val) begin
                    `uvm_error("SB", $sformatf("[SCOREBOARD_ERROR] Reg 0x%02h readback mismatch. Exp: 0x%08h, Act: 0x%08h", t.paddr, expected_val, t.prdata))
                    `uvm_info("DIAGNOSIS", "--> BUG DETECTED (Req R1/R2): APB Read/Write or Reset logic is broken for this register.", UVM_NONE)
                end
            end

            OFF_RX_DATA: begin
                if (rx_expected.size() > 0) begin
                    logic [31:0] exp_rx = rx_expected.pop_front();
                    if (t.prdata !== exp_rx) begin
                        error_count++;
                        `uvm_error("SB", $sformatf("[SCOREBOARD_ERROR] SPI Data mismatch. Exp: 0x%08h, Act: 0x%08h", exp_rx, t.prdata))

                        // --- DIAGNOSTIC ENGINE ---
                        if (t.prdata == 0 && exp_rx != 0)
                            `uvm_info("DIAGNOSIS", "--> BUG DETECTED (Req R9/R10): RTL output all zeros. TX/RX FIFO dropped the data or shift register is stuck.", UVM_NONE)
                        else if ((t.prdata << 1) == exp_rx || (t.prdata >> 1) == exp_rx)
                            `uvm_info("DIAGNOSIS", "--> BUG DETECTED (Req R7): Data is shifted by 1 bit. SPI Core counter logic is stopping 1 cycle early/late.", UVM_NONE)
                        else
                            `uvm_info("DIAGNOSIS", "--> BUG DETECTED (Req R6): Data corrupted. Possible LSB/MSB shift order inversion or FIFO ordering bug.", UVM_NONE)
                    end else
                        `uvm_info("SB", $sformatf("RX_DATA MATCH: 0x%08h", t.prdata), UVM_HIGH)
                end
            end
        endcase
    endfunction

    // ---- SPI transaction processing ----------------------------------------
    function void write_spi(spi_seq_item t);
        logic [31:0] tx_expected;
        logic [31:0] rx_predicted;
        int          nbits = get_nbits(t.width_sel);

        // 1. VERIFY TRANSMIT (MOSI vs shadow FIFO), not in loopback
        if (!shadow_ctrl[5]) begin
            if (tx_shadow_fifo.size() > 0) begin
                tx_expected = tx_shadow_fifo.pop_front();
                if (nbits < 32) tx_expected &= ((32'h1 << nbits) - 1);

                if (t.mosi_data !== tx_expected)
                    `uvm_error("SB", $sformatf("[SCOREBOARD_ERROR] MOSI Data mismatch! Exp: 0x%08h, Act: 0x%08h", tx_expected, t.mosi_data))
            end else
                `uvm_error("SB", "[SCOREBOARD_ERROR] SPI Activity detected, but TX FIFO shadow is empty!")
        end

        // 2. PREDICT RECEIVE
        rx_predicted = t.miso_data;
        if (nbits < 32) rx_predicted &= ((32'h1 << nbits) - 1);

        // Loopback: the data sent is also what is received
        if (shadow_ctrl[5])
            rx_predicted = t.mosi_data & ((nbits == 32) ? 32'hFFFF_FFFF : ((32'h1 << nbits) - 1));

        rx_expected.push_back(rx_predicted);
    endfunction

    // ---- Simulation banner -------------------------------------------------
    function void report_phase(uvm_phase phase);
        uvm_report_server server = uvm_report_server::get_server();

        if (server.get_severity_count(UVM_ERROR) > 0 || server.get_severity_count(UVM_FATAL) > 0 || error_count > 0) begin
            `uvm_info("DEFENSE", "===============================================================", UVM_NONE)
            `uvm_info("DEFENSE", " RTL BUG DETECTED IN THIS SIMULATION ", UVM_NONE)
            `uvm_info("DEFENSE", "Scroll up and look for the 'DIAGNOSIS' tag to see the exact bug.", UVM_NONE)
            `uvm_info("DEFENSE", "===============================================================", UVM_NONE)
        end else begin
            `uvm_info("DEFENSE", "===============================================================", UVM_NONE)
            `uvm_info("DEFENSE", " RTL PASSED ALL CHECKS (GOLDEN DESIGN) ", UVM_NONE)
            `uvm_info("DEFENSE", "===============================================================", UVM_NONE)
        end
    endfunction
endclass

`endif