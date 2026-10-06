`ifndef ENV_SV
`define ENV_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_pkg::*; 
import reg_pkg::*; 



class spi_env extends uvm_env;
  `uvm_component_utils(spi_env)

  apb_agent       apb_agt;
  spi_agent       spi_agt;
  scoreboard      scb;
  ref_model       rm;
  spi_coverage    cov;

  spi_reg_block   reg_block;
  apb_reg_adapter adapter;

  virtual apb_if  apb_vif;
  virtual spi_if  spi_vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // interfaces (the agents also read the same keys themselves)
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", apb_vif))
      `uvm_fatal("ENV", "virtual apb_if not found in config_db (key: apb_vif)")
    if (!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", spi_vif))
      `uvm_fatal("ENV", "virtual spi_if not found in config_db (key: spi_vif)")

    apb_agt = apb_agent::type_id::create("apb_agt", this);
    spi_agt = spi_agent::type_id::create("spi_agt", this);
    scb     = scoreboard::type_id::create("scb", this);
    rm      = ref_model::type_id::create("rm", this);
    cov     = spi_coverage::type_id::create("cov", this);

    // register model
    reg_block = spi_reg_block::type_id::create("reg_block");
    reg_block.build();
    adapter = new("adapter");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // monitors -> scoreboard
    apb_agt.monitor.ap.connect(scb.apb_imp);
    spi_agt.monitor.ap.connect(scb.spi_imp);

    // monitors -> reference model
    apb_agt.monitor.ap.connect(rm.apb_imp);
    spi_agt.monitor.ap.connect(rm.spi_imp);

    // monitor -> coverage
    spi_agt.monitor.ap.connect(cov.analysis_export);

    // register model uses the APB sequencer
    reg_block.default_map.set_sequencer(apb_agt.sequencer, adapter);
    reg_block.default_map.set_auto_predict(1);
  endfunction

endclass

`endif