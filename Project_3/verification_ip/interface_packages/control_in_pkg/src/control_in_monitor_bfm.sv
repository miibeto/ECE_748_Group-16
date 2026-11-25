//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: This interface performs the control_in signal monitoring.
//      It is accessed by the uvm control_in monitor through a virtual
//      interface handle in the control_in configuration.  It monitors the
//      signals passed in through the port connection named bus of
//      type control_in_if.
//
//     Input signals from the control_in_if are assigned to an internal input
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
//                   blocks until an operation on the control_in bus is complete.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
import uvmf_base_pkg_hdl::*;
import control_in_pkg_hdl::*;
`include "src/control_in_macros.svh"


interface control_in_monitor_bfm 
  ( control_in_if  bus );
  // The pragma below and additional ones in-lined further down are for running this BFM on Veloce
  // pragma attribute control_in_monitor_bfm partition_interface_xif                                  

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
`control_in_MONITOR_STRUCT
  control_in_monitor_s control_in_monitor_struct;

  // Structure used to pass configuration data from monitor class to monitor BFM.
 `control_in_CONFIGURATION_STRUCT
 

  // Config value to determine if this is an initiator or a responder 
  uvmf_initiator_responder_t initiator_responder;
  // Custom configuration variables.  
  // These are set using the configure function which is called during the UVM connect_phase

  tri clock_i;
  tri reset_i;
  tri  complete_data_i;
  tri  complete_instr_i;
  tri [15:0] IR_i;
  tri [2:0] psr_i;
  tri [15:0] IR_Exec_i;
  tri [15:0] IMem_dout_i;
  tri [2:0] NZP_i;
  assign clock_i = bus.clock;
  assign reset_i = bus.reset;
  assign complete_data_i = bus.complete_data;
  assign complete_instr_i = bus.complete_instr;
  assign IR_i = bus.IR;
  assign psr_i = bus.psr;
  assign IR_Exec_i = bus.IR_Exec;
  assign IMem_dout_i = bus.IMem_dout;
  assign NZP_i = bus.NZP;

  // Proxy handle to UVM monitor
  control_in_pkg::control_in_monitor  proxy;
  // pragma tbx oneway proxy.notify_transaction                 

  // pragma uvmf custom interface_item_additional begin
  //stage38 keeps the stage32 completion-edge selection and varies input stage phase
  //phase 0 uses post-edge inputs, phase 1 pre-edge ir fields, phase 2 all pre-edge inputs
  integer stage38_input_phase = 0;
  bit stage38_phase_found = 0;
  bit stage32_instr_mode = 0;
  bit stage32_data_mode = 0;
  bit stage32_instr_numeric_found = 0;
  bit stage32_data_numeric_found = 0;
  integer stage32_instr_arg = 0;
  integer stage32_data_arg = 0;
  bit stage38_trace = 0;
  bit stage38_snapshot_valid = 0;
  int unsigned stage38_sample_count = 0;
  int unsigned stage38_instr_missing_on_fall = 0;
  int unsigned stage38_data_missing_on_fall = 0;

  logic stage38_complete_instr_pre;
  logic stage38_complete_data_pre;
  logic [15:0] stage38_ir_pre;
  logic [2:0] stage38_psr_pre;
  logic [15:0] stage38_ir_exec_pre;
  logic [15:0] stage38_imem_dout_pre;
  logic [2:0] stage38_nzp_pre;

  initial begin : stage38_mode_selection
    stage32_instr_numeric_found = $value$plusargs("CTRL32_EDGE_INSTR=%d", stage32_instr_arg);
    if (!stage32_instr_numeric_found)
      stage32_instr_arg = $test$plusargs("CTRL32_EDGE_INSTR") ? 1 : 0;
    stage32_data_numeric_found = $value$plusargs("CTRL32_EDGE_DATA=%d", stage32_data_arg);
    if (!stage32_data_numeric_found)
      stage32_data_arg = $test$plusargs("CTRL32_EDGE_DATA") ? 1 : 0;
    stage32_instr_mode = (stage32_instr_arg == 1);
    stage32_data_mode = (stage32_data_arg == 1);
    stage38_phase_found = $value$plusargs("CTRL38_INPUT_PHASE=%d", stage38_input_phase);
    if (!stage38_phase_found) stage38_input_phase = 0;
    if (stage38_input_phase < 0 || stage38_input_phase > 2) begin
      $error("STAGE38_BAD_PHASE value=%0d permitted=0,1,2", stage38_input_phase);
      stage38_input_phase = 0;
    end
    stage38_trace = $test$plusargs("TRACE_CTRL38");
    $display("STAGE38_IN_MODE phase=%0d phase_arg=%0d instr_mode=%0d data_mode=%0d version=38.1",
      stage38_input_phase, stage38_phase_found, stage32_instr_mode, stage32_data_mode);
  end

  //nonblocking assignment captures each value before the posedge nba region
  //the monitor consumes the stable snapshot at the following negedge
  always @(posedge clock_i) begin : stage38_capture_preedge
    stage38_complete_instr_pre <= complete_instr_i;
    stage38_complete_data_pre <= complete_data_i;
    stage38_ir_pre <= IR_i;
    stage38_psr_pre <= psr_i;
    stage38_ir_exec_pre <= IR_Exec_i;
    stage38_imem_dout_pre <= IMem_dout_i;
    stage38_nzp_pre <= NZP_i;
    stage38_snapshot_valid <= 1'b1;
  end
  // pragma uvmf custom interface_item_additional end
  
  //******************************************************************                         
  task wait_for_reset();// pragma tbx xtf  
    @(posedge clock_i) ;                                                                    
    do_wait_for_reset();                                                                   
  endtask                                                                                   

  // ****************************************************************************              
  task do_wait_for_reset(); 
  // pragma uvmf custom reset_condition begin
    wait ( reset_i === 0 ) ;                                                              
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
      do_monitor( control_in_monitor_struct );
                                                                 
 
      proxy.notify_transaction( control_in_monitor_struct );
 
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
    function void configure(control_in_configuration_s control_in_configuration_arg); // pragma tbx xtf  
    initiator_responder = control_in_configuration_arg.initiator_responder;
  // pragma uvmf custom configure begin
  // pragma uvmf custom configure end
  endfunction   


  // ****************************************************************************  
            
  task do_monitor(output control_in_monitor_s control_in_monitor_struct);
    //
    // Available struct members:
    //     //    control_in_monitor_struct.complete_data
    //     //    control_in_monitor_struct.complete_instr
    //     //    control_in_monitor_struct.IR
    //     //    control_in_monitor_struct.psr
    //     //    control_in_monitor_struct.IR_Exec
    //     //    control_in_monitor_struct.IMem_dout
    //     //    control_in_monitor_struct.NZP
    //     //
    // Reference code;
    //    How to wait for signal value
    //      while (control_signal === 1'b1) @(posedge clock_i);
    //    
    //    How to assign a struct member, named xyz, from a signal.   
    //    All available input signals listed.
    //      control_in_monitor_struct.xyz = complete_data_i;  //     
    //      control_in_monitor_struct.xyz = complete_instr_i;  //     
    //      control_in_monitor_struct.xyz = IR_i;  //    [15:0] 
    //      control_in_monitor_struct.xyz = psr_i;  //    [2:0] 
    //      control_in_monitor_struct.xyz = IR_Exec_i;  //    [15:0] 
    //      control_in_monitor_struct.xyz = IMem_dout_i;  //    [15:0] 
    //      control_in_monitor_struct.xyz = NZP_i;  //    [2:0] 
    // pragma uvmf custom do_monitor begin
    wait (reset_i === 1'b0);
    @(negedge clock_i);
    //the original stage32 behavior uses posedge completion pulses and postedge data
    control_in_monitor_struct.complete_data =
      (stage32_data_mode && stage38_snapshot_valid) ? stage38_complete_data_pre : complete_data_i;
    control_in_monitor_struct.complete_instr =
      (stage32_instr_mode && stage38_snapshot_valid) ? stage38_complete_instr_pre : complete_instr_i;
    if (stage38_input_phase >= 1 && stage38_snapshot_valid) begin
      control_in_monitor_struct.IR = stage38_ir_pre;
      control_in_monitor_struct.IR_Exec = stage38_ir_exec_pre;
    end else begin
      control_in_monitor_struct.IR = IR_i;
      control_in_monitor_struct.IR_Exec = IR_Exec_i;
    end
    if (stage38_input_phase == 2 && stage38_snapshot_valid) begin
      control_in_monitor_struct.psr = stage38_psr_pre;
      control_in_monitor_struct.IMem_dout = stage38_imem_dout_pre;
      control_in_monitor_struct.NZP = stage38_nzp_pre;
    end else begin
      control_in_monitor_struct.psr = psr_i;
      control_in_monitor_struct.IMem_dout = IMem_dout_i;
      control_in_monitor_struct.NZP = NZP_i;
    end
    stage38_sample_count++;
    if (stage38_complete_instr_pre && !complete_instr_i)
      stage38_instr_missing_on_fall++;
    if (stage38_complete_data_pre && !complete_data_i)
      stage38_data_missing_on_fall++;
    if (stage38_trace && stage38_sample_count <= 45)
      $display("STAGE38_SAMPLE t=%0t n=%0d phase=%0d ci=%b cd=%b ir_pre=%04h ir_post=%04h ie_pre=%04h ie_post=%04h psr_pre=%01h psr_post=%01h nzp_pre=%01h nzp_post=%01h",
        $time, stage38_sample_count, stage38_input_phase,
        control_in_monitor_struct.complete_instr, control_in_monitor_struct.complete_data,
        stage38_ir_pre, IR_i, stage38_ir_exec_pre, IR_Exec_i,
        stage38_psr_pre, psr_i, stage38_nzp_pre, NZP_i);
    // pragma uvmf custom do_monitor end
  endtask         
  
 
endinterface

// pragma uvmf custom external begin
// pragma uvmf custom external end

