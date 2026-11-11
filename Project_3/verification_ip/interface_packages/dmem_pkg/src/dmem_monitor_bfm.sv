//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
import uvmf_base_pkg_hdl::*;
import dmem_pkg_hdl::*;
`include "src/dmem_macros.svh"

interface dmem_monitor_bfm 
  ( dmem_if bus );

`ifndef XRTL
import uvm_pkg::*;
`include "uvm_macros.svh"
initial begin : bfm_vs_agent_parameter_debug
  `uvm_info("CFG", 
      $psprintf("The BFM at '%m' has the following parameters: ", ),
      UVM_DEBUG)
end
`endif

  `dmem_MONITOR_STRUCT
  dmem_monitor_s dmem_monitor_struct;

  `dmem_CONFIGURATION_STRUCT

  uvmf_initiator_responder_t initiator_responder;

  tri clock_i;
  tri reset_i;
  tri [15:0] Data_addr_i;
  tri [15:0] Data_din_i;
  tri [15:0] Data_dout_i;
  tri        Data_rd_i;
  tri        D_macc_i;
  tri        complete_data_i;

  assign clock_i         = bus.clock;
  assign reset_i         = bus.reset;
  assign Data_addr_i     = bus.Data_addr;
  assign Data_din_i      = bus.Data_din;
  assign Data_dout_i     = bus.Data_dout;
  assign Data_rd_i       = bus.Data_rd;
  assign D_macc_i        = bus.D_macc;
  assign complete_data_i = bus.complete_data;

  dmem_pkg::dmem_monitor proxy;

  task wait_for_reset();
    @(posedge clock_i);
    do_wait_for_reset();
  endtask

  task do_wait_for_reset(); 
  // pragma uvmf custom reset_condition begin
    // reset is active high, so wait for it to go back to 0 before we start
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
      do_monitor( dmem_monitor_struct );
      proxy.notify_transaction( dmem_monitor_struct );
    end
  end

  function void configure(dmem_configuration_s dmem_configuration_arg);
    initiator_responder = dmem_configuration_arg.initiator_responder;
  endfunction

  // Synchronize on valid data memory completion
  task do_monitor(output dmem_monitor_s dmem_monitor_struct);
    //
    // Available struct members:
    //     //    dmem_monitor_struct.Data_addr
    //     //    dmem_monitor_struct.Data_din
    //     //    dmem_monitor_struct.Data_rd
    //     //    dmem_monitor_struct.D_macc
    //     //    dmem_monitor_struct.Data_dout
    //     //    dmem_monitor_struct.complete_data
    //     //
    // Reference code;
    //    How to wait for signal value
    //      while (control_signal === 1'b1) @(posedge clock_i);
    //    
    //    How to assign a struct member, named xyz, from a signal.   
    //    All available input signals listed.
    //      dmem_monitor_struct.xyz = Data_addr_i;  //    [15:0] 
    //      dmem_monitor_struct.xyz = Data_din_i;  //    [15:0] 
    //      dmem_monitor_struct.xyz = Data_rd_i;  //     
    //      dmem_monitor_struct.xyz = D_macc_i;  //     
    //      dmem_monitor_struct.xyz = Data_dout_i;  //    [15:0] 
    //      dmem_monitor_struct.xyz = complete_data_i;  //     
    // pragma uvmf custom do_monitor begin
    // wait until the DUT actually asserts a request, then grab the fields
    while (D_macc_i !== 1'b1) @(posedge clock_i);
    dmem_monitor_struct.Data_addr = Data_addr_i;
    dmem_monitor_struct.Data_din  = Data_din_i;
    dmem_monitor_struct.Data_rd   = Data_rd_i;
    dmem_monitor_struct.D_macc    = D_macc_i;

    // the driver bfm doesn't respond until one cycle later (that's just how
    // we set up the memory model), so we need to wait a cycle and then grab
    // the response so this shows up as one full request+response txn
    @(posedge clock_i);
    while (complete_data_i !== 1'b1) @(posedge clock_i);
    dmem_monitor_struct.Data_dout     = Data_dout_i;
    dmem_monitor_struct.complete_data = complete_data_i;
    // pragma uvmf custom do_monitor end
  endtask         
  
 
endinterface