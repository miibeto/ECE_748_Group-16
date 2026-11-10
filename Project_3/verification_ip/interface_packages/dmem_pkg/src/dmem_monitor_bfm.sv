//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: This interface performs the dmem signal monitoring.
//      It is accessed by the uvm dmem monitor through a virtual
//      interface handle in the dmem configuration.  It monitors the
//      signals passed in through the port connection named bus of
//      type dmem_if.
//
//     Input signals from the dmem_if are assigned to an internal input
//     signal with a _i suffix.  The _i signal should be used for sampling.
//
//     The input signal connections are as follows:
//       bus.signal -> signal_i 
//
//      Interface functions and tasks used by UVM components:
//             monitor(inout TRANS_T txn);
//                   This task receives the transaction, txn, from the
//                   UVM monitor and then populates variables in txn
//                   from values observed on bus activity.  This task
//                   blocks until an operation on the dmem bus is complete.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
import uvmf_base_pkg_hdl::*;
import dmem_pkg_hdl::*;
`include "src/dmem_macros.svh"


interface dmem_monitor_bfm 
  ( dmem_if  bus );
  // The pragma below and additional ones in-lined further down are for running this BFM on Veloce
  // pragma attribute dmem_monitor_bfm partition_interface_xif                                  

`ifndef XRTL
// This code is to aid in debugging parameter mismatches between the BFM and its corresponding agent.
// Enable this debug by setting UVM_VERBOSITY to UVM_DEBUG
// Setting UVM_VERBOSITY to UVM_DEBUG causes all BFM's and all agents to display their parameter settings.
// All of the messages from this feature have a UVM messaging id value of "CFG"
// The transcript or run.log can be parsed to ensure BFM parameter settings match its corresponding agents parameter settings.
import uvm_pkg::*;
`include "uvm_macros.svh"
initial begin : bfm_vs_agent_parameter_debug
  `uvm_info("CFG", 
      $psprintf("The BFM at '%m' has the following parameters: ", ),
      UVM_DEBUG)
end
`endif


  // Structure used to pass transaction data from monitor BFM to monitor class in agent.
`dmem_MONITOR_STRUCT
  dmem_monitor_s dmem_monitor_struct;

  // Structure used to pass configuration data from monitor class to monitor BFM.
 `dmem_CONFIGURATION_STRUCT
 

  // Config value to determine if this is an initiator or a responder 
  uvmf_initiator_responder_t initiator_responder;
  // Custom configuration variables.  
  // These are set using the configure function which is called during the UVM connect_phase

  tri clock_i;
  tri reset_i;
  tri [15:0] Data_addr_i;
  tri [15:0] Data_din_i;
  tri  Data_rd_i;
  tri  D_macc_i;
  tri [15:0] Data_dout_i;
  tri  complete_data_i;
  assign clock_i = bus.clock;
  assign reset_i = bus.reset;
  assign Data_addr_i = bus.Data_addr;
  assign Data_din_i = bus.Data_din;
  assign Data_rd_i = bus.Data_rd;
  assign D_macc_i = bus.D_macc;
  assign Data_dout_i = bus.Data_dout;
  assign complete_data_i = bus.complete_data;

  // Proxy handle to UVM monitor
  dmem_pkg::dmem_monitor  proxy;
  // pragma tbx oneway proxy.notify_transaction                 

  // pragma uvmf custom interface_item_additional begin
  // pragma uvmf custom interface_item_additional end
  
  //******************************************************************                         
  task wait_for_reset();// pragma tbx xtf  
    @(posedge clock_i) ;                                                                    
    do_wait_for_reset();                                                                   
  endtask                                                                                   

  // ****************************************************************************              
  task do_wait_for_reset(); 
  // pragma uvmf custom reset_condition begin
    // reset is active high, so wait for it to go back to 0 before we start
    wait ( reset_i === 1'b0 ) ;
    @(posedge clock_i) ;
  // pragma uvmf custom reset_condition end                                                                
  endtask    

  //******************************************************************                         
 
  task wait_for_num_clocks(input int unsigned count); // pragma tbx xtf 
    @(posedge clock_i);  
                                                                   
    repeat (count-1) @(posedge clock_i);                                                    
  endtask      

  //******************************************************************                         
  event go;                                                                                 
  function void start_monitoring();// pragma tbx xtf    
    -> go;
  endfunction                                                                               
  
  // ****************************************************************************              
  initial begin                                                                             
    @go;                                                                                   
    forever begin                                                                        
      @(posedge clock_i);  
      do_monitor( dmem_monitor_struct );
                                                                 
 
      proxy.notify_transaction( dmem_monitor_struct );
 
    end                                                                                    
  end                                                                                       

  //******************************************************************
  // The configure() function is used to pass agent configuration
  // variables to the monitor BFM.  It is called by the monitor within
  // the agent at the beginning of the simulation.  It may be called 
  // during the simulation if agent configuration variables are updated
  // and the monitor BFM needs to be aware of the new configuration 
  // variables.
  //
    function void configure(dmem_configuration_s dmem_configuration_arg); // pragma tbx xtf  
    initiator_responder = dmem_configuration_arg.initiator_responder;
  // pragma uvmf custom configure begin
  // pragma uvmf custom configure end
  endfunction   


  // ****************************************************************************  
            
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

// pragma uvmf custom external begin
// pragma uvmf custom external end

