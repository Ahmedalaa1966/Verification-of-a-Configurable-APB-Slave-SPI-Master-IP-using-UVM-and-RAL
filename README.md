# Verification of a Configurable APB-Slave SPI Master IP using UVM and RAL

A UVM and RAL (Register Abstraction Layer) verification environment for an APB-slave SPI master IP. The IP supports all four SPI modes, 8/16/32-bit transfers, four slave selects, dual 8-deep FIFOs, a programmable clock divider and interrupts.

## 1. Overview

The SPI Master Controller is a synthesizable IP block that implements an industry-standard Serial Peripheral Interface (SPI) master with a 32-bit AMBA APB v2.0 slave interface for configuration and data access. The block is designed for single-clock, synchronous, active-low-reset operation and is the verification target for the Spring 2026 Digital Design Verification course final project.

### 1.1 Key Features

- APB v2.0 slave interface: 32-bit data, byte-addressable register file
- All four SPI modes (CPOL x CPHA)
- Programmable transfer width: 8, 16 or 32 bits
- Up to 4 independent active-low slave selects (`SS_n[3:0]`)
- Separate 8-deep TX and RX FIFOs with full/empty and overflow status
- Programmable SCLK divider: `SCLK = PCLK / (2 x (DIV+1))`, `DIV` in [0, 65535]
- Programmable bit ordering (MSB-first or LSB-first)
- Loopback mode (MOSI driven back onto MISO internally) for self-test
- Programmable inter-transfer delay (0-255 SCLK half-cycles)
- Five maskable interrupts with sticky W1C status
- Synchronous active-low reset (`PRESETn`)

## 2. Verification Environment

The testbench drives the IP through its APB interface, using RAL for register access, and observes the SPI side with its own agent. A reference model predicts the expected behaviour and the scoreboard compares it against the observed results.

| Component | Files | Role |
|-----------|-------|------|
| **APB agent** | `apb_agent`, `apb_driver`, `apb_monitor`, `apb_sequencer`, `apb_seq_item` | Drives and monitors the APB configuration and data interface. |
| **SPI agent** | `spi_agent`, `spi_driver`, `spi_monitor`, `spi_sequencer`, `spi_seq_item` | Models the SPI slave side and observes SPI transfers. |
| **RAL model** | `spi_reg_block`, `reg_pkg`, `apb_reg_adaptor`, one file per register | Register abstraction layer with an adaptor that converts register accesses to APB transactions. |
| **Reference model** | `ref_model` | Predicts the expected behaviour of the IP. |
| **Scoreboard** | `scoreboard` | Compares the observed behaviour against the reference model. |
| **Coverage** | `coverage` | Functional coverage collection. |
| **Environment** | `env`, `apb_pkg`, `spi_pkg` | Builds and connects all components. |

### Register model

The RAL model has one class per register, grouped in `spi_reg_block`:

| Register class | Purpose |
|----------------|---------|
| `ctrl_reg` | Main control (SPI mode, transfer width, bit order, loopback and so on) |
| `clk_div_reg` | SCLK divider |
| `delay_reg` | Inter-transfer delay |
| `ss_ctrl_reg` | Slave-select control |
| `status_reg` | FIFO status (full, empty, overflow) and transfer status |
| `tx_data_reg` | TX FIFO write port |
| `rx_data_reg` | RX FIFO read port |
| `int_en_reg` | Interrupt enable mask |
| `int_state_reg` | Sticky W1C interrupt status |

## 3. Tests and Sequences

| Test | Purpose |
|------|---------|
| `base_test` | Base class: builds the environment and sets up common configuration |
| `reg_rw_test` | Register read/write checks through RAL |
| `spi_idle_test` | Idle behaviour after reset |
| `spi_req_tests` | SPI transfer tests (also run as `spi_ctrl`, `spi_fifo`, `spi_irq`, `spi_misc` and `spi_timing` in the coverage runs) |

Sequences are in `Verification/sequences/`: `apb_base_sequence`, `reg_rw_sequences`, `spi_base_sequence`, `spi_idle_sequence` and `spi_req_sequences`, collected in `spi_sequence_pkg`.

## 4. Project Structure

```
Verification-of-a-Configurable-APB-Slave-SPI-Master-IP-using-UVM-and-RAL/
├── README.md
├── golden_rtl/                   # Design under test
│   ├── apb_regfile.sv            # APB register file
│   ├── spi_core.sv               # SPI core (shift logic, FIFOs, clock divider)
│   └── spi_master.sv             # Top level of the SPI master IP
├── harness/                      # DUT harness
├── Verification/
│   ├── env/                      # Agents, RAL model, reference model, scoreboard, coverage, env
│   │   ├── apb_agent.sv
│   │   ├── apb_driver.sv
│   │   ├── apb_monitor.sv
│   │   ├── apb_pkg.sv
│   │   ├── apb_reg_adaptor.sv
│   │   ├── apb_seq_item.sv
│   │   ├── apb_sequencer.sv
│   │   ├── spi_agent.sv
│   │   ├── spi_driver.sv
│   │   ├── spi_monitor.sv
│   │   ├── spi_pkg.sv
│   │   ├── spi_seq_item.sv
│   │   ├── spi_sequencer.sv
│   │   ├── reg_pkg.sv
│   │   ├── spi_reg_block.sv
│   │   ├── ctrl_reg.sv
│   │   ├── clk_div_reg.sv
│   │   ├── delay_reg.sv
│   │   ├── ss_ctrl_reg.sv
│   │   ├── status_reg.sv
│   │   ├── tx_data_reg.sv
│   │   ├── rx_data_reg.sv
│   │   ├── int_en_reg.sv
│   │   ├── int_state_reg.sv
│   │   ├── ref_model.sv
│   │   ├── scoreboard.sv
│   │   ├── coverage.sv
│   │   └── env.sv
│   ├── sequences/
│   │   ├── apb_base_sequence.sv
│   │   ├── reg_rw_sequences.sv
│   │   ├── spi_base_sequence.sv
│   │   ├── spi_idle_sequence.sv
│   │   ├── spi_req_sequences.sv
│   │   └── spi_sequence_pkg.sv
│   ├── tb/
│   │   └── tb_top.sv             # Testbench top
│   └── tests/
│       ├── base_test.sv
│       ├── reg_rw_test.sv
│       ├── spi_idle_test.sv
│       ├── spi_req_tests.sv
│       └── test_pkg.sv
└── coverage/                     # Coverage databases and reports
    ├── merged.ucdb               # Merged coverage database
    ├── report.txt                # Merged coverage report
    └── spi_<test>_test.ucdb / spi_<test>_test_report.txt
        # one pair per test: ctrl, fifo, idle, irq, misc, reg_rw, req, timing
```

## 5. How to Run

1. Compile `golden_rtl/`, the harness and the `Verification/` packages in this order: `apb_pkg`, `spi_pkg`, `reg_pkg`, `spi_sequence_pkg`, `test_pkg`, then `tb_top.sv`.
2. Run a test with `+UVM_TESTNAME=<test_name>`.
3. To collect coverage, save the database per test (`.ucdb`), then merge the databases into `coverage/merged.ucdb` and generate the report.



## 7. Tools

SystemVerilog, UVM, UVM RAL, QuestaSim
