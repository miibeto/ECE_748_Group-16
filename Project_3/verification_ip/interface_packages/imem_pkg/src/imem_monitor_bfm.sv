//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
import uvmf_base_pkg_hdl::*;
import imem_pkg_hdl::*;
`include "src/imem_macros.svh"

interface imem_monitor_bfm 
  ( imem_if bus );

`ifndef XRTL
import uvm_pkg::*;
`include "uvm_macros.svh"
initial begin : bfm_vs_agent_parameter_debug
  `uvm_info("CFG", 
      $psprintf("The BFM at '%m' has the following parameters: ", ),
      UVM_DEBUG)
end
`endif

  `imem_MONITOR_STRUCT
  imem_monitor_s imem_monitor_struct;

  `imem_CONFIGURATION_STRUCT

  uvmf_initiator_responder_t initiator_responder;

  tri clock_i;
  tri reset_i;
  tri [15:0] PC_i;
  tri        instrmem_rd_i;
  tri        I_macc_i;
  tri [15:0] Instr_dout_i;
  tri        complete_instr_i;

  assign clock_i          = bus.clock;
  assign reset_i          = bus.reset;
  assign PC_i             = bus.PC;
  assign instrmem_rd_i    = bus.instrmem_rd;
  assign I_macc_i         = bus.I_macc;
  assign Instr_dout_i     = bus.Instr_dout;
  assign complete_instr_i = bus.complete_instr;

  imem_pkg::imem_monitor proxy;

  task wait_for_reset();
    @(posedge clock_i);
    do_wait_for_reset();
  endtask

  task do_wait_for_reset(); 
    wait ( reset_i === 0 );
    @(posedge clock_i);
  endtask

  task wait_for_num_clocks(input int unsigned count);
    @(posedge clock_i);
    repeat (count-1) @(posedge clock_i);
  endtask

  event go;
  function void start_monitoring();
    -> go;
  endfunction

  initial begin
    @go;
    wait (reset_i === 1'b0);
    forever begin
      do_monitor( imem_monitor_struct );
      proxy.notify_transaction( imem_monitor_struct );
    end
  end

  function void configure(imem_configuration_s imem_configuration_arg);
    initiator_responder = imem_configuration_arg.initiator_responder;
  endfunction

  // Synchronize on valid instruction fetch completion
  task do_monitor(output imem_monitor_s imem_monitor_struct);
    // Always advance at least 1 clock cycle before checking completion status
    do begin
      @(posedge clock_i);
    end while (reset_i === 1'b1 || complete_instr_i === 1'b0 || (instrmem_rd_i === 1'b0 && I_macc_i === 1'b0));

    // Sample valid instruction fetch bus values
    imem_monitor_struct.PC             = PC_i;
    imem_monitor_struct.instrmem_rd    = instrmem_rd_i;
    imem_monitor_struct.I_macc         = I_macc_i;
    imem_monitor_struct.Instr_dout     = Instr_dout_i;
    imem_monitor_struct.complete_instr = complete_instr_i;
  endtask

endinterface