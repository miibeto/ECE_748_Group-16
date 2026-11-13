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

  // ****************************************************************************              
  task do_wait_for_reset();
  // pragma uvmf custom reset_condition begin
    // LC3 reset is active-high. Wait for reset to deassert before monitoring.
    wait ( reset_i === 1'b0 ) ;
    @(posedge clock_i) ;
  // pragma uvmf custom reset_condition end
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
    //
    // Available struct members:
    //     //    imem_monitor_struct.PC
    //     //    imem_monitor_struct.instrmem_rd
    //     //    imem_monitor_struct.I_macc
    //     //    imem_monitor_struct.Instr_dout
    //     //    imem_monitor_struct.complete_instr
    //     //
    // Reference code;
    //    How to wait for signal value
    //      while (control_signal === 1'b1) @(posedge clock_i);
    //    
    //    How to assign a struct member, named xyz, from a signal.   
    //    All available input signals listed.
    //      imem_monitor_struct.xyz = PC_i;  //    [15:0] 
    //      imem_monitor_struct.xyz = instrmem_rd_i;  //     
    //      imem_monitor_struct.xyz = I_macc_i;  //     
    //      imem_monitor_struct.xyz = Instr_dout_i;  //    [15:0] 
    //      imem_monitor_struct.xyz = complete_instr_i;  //     
    // pragma uvmf custom do_monitor begin
    // Wait for a fetch request: instrmem_rd asserted by the DUT.
    // while (instrmem_rd_i !== 1'b1) @(posedge clock_i);
    // // Sample the request address on the cycle the read is asserted.
    // imem_monitor_struct.PC          = PC_i;
    // imem_monitor_struct.instrmem_rd = instrmem_rd_i;
    // imem_monitor_struct.I_macc      = I_macc_i;
    // // Wait for the responder to complete the transfer.
    // // Original completion wait:
    // // while (complete_instr_i !== 1'b1) @(posedge clock_i);
    // wait (complete_instr_i === 1'b1);
    // imem_monitor_struct.Instr_dout     = Instr_dout_i;
    // imem_monitor_struct.complete_instr = complete_instr_i;
    // // Wait for the completion pulse to deassert before starting the next
    // // transaction. Without this, the monitor can re-enter immediately while
    // // instrmem_rd_i and complete_instr_i are both still high.
    // while (complete_instr_i === 1'b1) @(posedge clock_i);
    do begin
      @(posedge clock_i);
    end while (reset_i === 1'b1 || complete_instr_i === 1'b0 || (instrmem_rd_i === 1'b0 && I_macc_i === 1'b0));

    // Sample valid instruction fetch bus values
    imem_monitor_struct.PC             = PC_i;
    imem_monitor_struct.instrmem_rd    = instrmem_rd_i;
    imem_monitor_struct.I_macc         = I_macc_i;
    imem_monitor_struct.Instr_dout     = Instr_dout_i;
    imem_monitor_struct.complete_instr = complete_instr_i;

    // pragma uvmf custom do_monitor end
  endtask         
  
 
endinterface