`ifndef APB_SEQUENCER_SV
`define APB_SEQUENCER_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_pkg::*; 


class apb_sequencer extends uvm_sequencer #(apb_seq_item);
  `uvm_component_utils(apb_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    `uvm_info("TYPE", $sformatf("sequencer REQ type = %s", $typename(REQ)), UVM_NONE)
  endfunction

  virtual function void send_request(uvm_sequence_base sequence_ptr,
                                   uvm_sequence_item t,
                                   bit rerandomize = 0);
  `uvm_info("TYPE", $sformatf("incoming item type = %s, from sequence type = %s",
                              $typename(t), sequence_ptr.get_type_name()), UVM_NONE)
  super.send_request(sequence_ptr, t, rerandomize);
endfunction

endclass

`endif