`ifndef BASE_TEST_SV
`define BASE_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_test_pkg::*;



class spi_base_test extends uvm_test;
  `uvm_component_utils(spi_base_test)

  spi_env env;

  function new(string name = "spi_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = spi_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

  // derived tests override this with their scenario
  virtual task run_scenario();
  endtask

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    wait (env.apb_vif.presetn === 1'b1);        // wait for reset release
    repeat (5) @(posedge env.apb_vif.pclk);
    run_scenario();
    repeat (20) @(posedge env.apb_vif.pclk);   // let the last transfer reach the monitors
    phase.drop_objection(this);
  endtask

  // grader contract: exactly one [TEST_PASSED] or [TEST_FAILED] line per test
  function void report_phase(uvm_phase phase);
    uvm_report_server svr = uvm_report_server::get_server();
    int errs = svr.get_severity_count(UVM_ERROR) + svr.get_severity_count(UVM_FATAL);
    super.report_phase(phase);
    if (errs == 0) $display("[TEST_PASSED] %s", get_type_name());
    else           $display("[TEST_FAILED] %s errors=%0d", get_type_name(), errs);
  endfunction

endclass
`endif 