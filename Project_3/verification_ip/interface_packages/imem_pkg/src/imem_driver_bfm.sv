//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: 
//    This interface performs the imem signal driving.  It is
//     accessed by the uvm imem driver through a virtual interface
//     handle in the imem configuration.  It drives the singals passed
//     in through the port connection named bus of type imem_if.
//
//     Input signals from the imem_if are assigned to an internal input
//     signal with a _i suffix.  The _i signal should be used for sampling.
//
//     The input signal connections are as follows:
//       bus.signal -> signal_i 
//
//     This bfm drives signals with a _o suffix.  These signals
//     are driven onto signals within imem_if based on INITIATOR/RESPONDER and/or
//     ARBITRATION/GRANT status.  
//
//     The output signal connections are as follows:
//        signal_o -> bus.signal
//
//                                                                                           
//      Interface functions and tasks used by UVM components:
//
//             configure:
//                   This function gets configuration attributes from the
//                   UVM driver to set any required BFM configuration
//                   variables such as 'initiator_responder'.                                       
//                                                                                           
//             initiate_and_get_response:
//                   This task is used to perform signaling activity for initiating
//                   a protocol transfer.  The task initiates the transfer, using
//                   input data from the initiator struct.  Then the task captures
//                   response data, placing the data into the response struct.
//                   The response struct is returned to the driver class.
//
//             respond_and_wait_for_next_transfer:
//                   This task is used to complete a current transfer as a responder
//                   and then wait for the initiator to start the next transfer.
//                   The task uses data in the responder struct to drive protocol
//                   signals to complete the transfer.  The task then waits for 
//                   the next transfer.  Once the next transfer begins, data from
//                   the initiator is placed into the initiator struct and sent
//                   to the responder sequence for processing to determine 
//                   what data to respond with.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
import uvmf_base_pkg_hdl::*;
import imem_pkg_hdl::*;
`include "src/imem_macros.svh"

interface imem_driver_bfm 
  (imem_if bus);
  // The following pragma and additional ones in-lined further below are for running this BFM on Veloce
  // pragma attribute imem_driver_bfm partition_interface_xif

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

  // Config value to determine if this is an initiator or a responder 
  uvmf_initiator_responder_t initiator_responder;
  // Custom configuration variables.  
  // These are set using the configure function which is called during the UVM connect_phase

  tri clock_i;
  tri reset_i;
  tri fetch_ready_i;

  // Signal list (all signals are capable of being inputs and outputs for the sake
  // of supporting both INITIATOR and RESPONDER mode operation. Expectation is that 
  // directionality in the config file was from the point-of-view of the INITIATOR

  // INITIATOR mode input signals
  tri [15:0] PC_i;
  reg [15:0] PC_o = 'b0;
  tri  instrmem_rd_i;
  reg  instrmem_rd_o = 'b0;
  tri  I_macc_i;
  reg  I_macc_o = 'b0;

  // INITIATOR mode output signals
  tri [15:0] Instr_dout_i;
  reg [15:0] Instr_dout_o = 'b0;
  tri  complete_instr_i;
  reg  complete_instr_o = 'b0;

  // Bi-directional signals
  

  assign clock_i = bus.clock;
  assign reset_i = bus.reset;
  assign fetch_ready_i = bus.fetch_ready;

  //print a compile marker and the effective run-time argument from this bfm
  initial begin : stage26_compiled_mode_probe
    #1ns;
    $display("STAGE26_BFM_COMPILED mode=%0d trace=%0d version=26.1 ready=%b", 
             $test$plusargs("GUARD_IMEM_ACK"),
             $test$plusargs("TRACE_ACK_GUARD"), fetch_ready_i);
  end

  initial begin : stage27_bfm_mode_probe
    #1ns;
    $display("STAGE27_BFM_COMPILED accept_mode=%0d trace=%0d version=27.1",
      $test$plusargs("ACCEPT_IMEM_ACK"),
      $test$plusargs("TRACE_ACCEPT_IMEM"));
  end

  //stage30 optionally discards a pending response when a control-flow redirect
  //makes its requested pc obsolete, allowing the driver to service the new pc
  bit stage30_cancel_redirect_mode = 1'b0;
  integer stage30_cancel_count = 0;
  initial begin : stage30_redirect_mode_probe
    stage30_cancel_redirect_mode = $test$plusargs("CANCEL_REDIRECTED_IMEM");
    #1ns;
    $display("STAGE30_BFM_COMPILED cancel_mode=%0d accept_mode=%0d version=30.1",
             stage30_cancel_redirect_mode,
             $test$plusargs("ACCEPT_IMEM_ACK"));
  end

  // These are signals marked as 'input' by the config file, but the signals will be
  // driven by this BFM if put into RESPONDER mode (flipping all signal directions around)
  assign PC_i = bus.PC;
  assign bus.PC = (initiator_responder == INITIATOR) ? PC_o : 'bz;
  assign instrmem_rd_i = bus.instrmem_rd;
  assign bus.instrmem_rd = (initiator_responder == INITIATOR) ? instrmem_rd_o : 'bz;
  assign I_macc_i = bus.I_macc;
  assign bus.I_macc = (initiator_responder == INITIATOR) ? I_macc_o : 'bz;


  // These are signals marked as 'output' by the config file, but the outputs will
  // not be driven by this BFM unless placed in INITIATOR mode.

  //stage59:specification-contract instruction-memory responder
  //complete_instr means the instruction at the saved request pc is valid.
  //it is not qualified by private controller state or a guessed latency.
  bit stage59_spec_mode = 1'b1;
  bit stage59_rsp_valid = 1'b0;
  bit stage59_rsp_complete = 1'b0;
  bit stage59_first_transfer = 1'b1;
  logic [15:0] stage59_rsp_pc = 16'h0000;
  logic [15:0] stage59_pending_pc = 16'h0000;
  logic [15:0] stage59_rsp_data = 16'h0000;
  int unsigned stage59_request_count = 0;
  int unsigned stage59_ack_count = 0;
  int unsigned stage59_redirect_count = 0;
  initial begin
    stage59_spec_mode = !$test$plusargs("CTRL59_USE_LEGACY");
    $display("STAGE59_SPEC_MODE enabled=%0d version=59.1",stage59_spec_mode);
  end

  //stage61:public-port instruction memory handshake
  //a response is associated with exactly one captured request pc
  bit stage61_contract_mode = 1'b0;
  bit stage61_first_transfer = 1'b1;
  bit stage61_rsp_valid = 1'b0;
  bit stage61_rsp_complete = 1'b0;
  bit stage61_same_pc_block = 1'b0;
  logic [15:0] stage61_pending_pc = 16'h0000;
  logic [15:0] stage61_rsp_pc = 16'h0000;
  logic [15:0] stage61_rsp_data = 16'h0000;
  int unsigned stage61_request_count = 0;
  int unsigned stage61_present_count = 0;
  int unsigned stage61_sample_count = 0;
  int unsigned stage61_cancel_count = 0;
  int unsigned stage61_pair_error_count = 0;
  initial begin : stage61_select
    stage61_contract_mode = $test$plusargs("CTRL61_HANDSHAKE");
    #1ns;
    $display("STAGE61_MODE enabled=%0d version=61.1", stage61_contract_mode);
  end
  final begin : stage61_totals
    if (stage61_contract_mode)
      $display("STAGE61_TOTAL requests=%0d presented=%0d sampled=%0d cancelled=%0d pair_errors=%0d",
        stage61_request_count, stage61_present_count, stage61_sample_count,
        stage61_cancel_count, stage61_pair_error_count);
  end

  //stage63:registered instruction memory response, independent of the live pc
  bit stage63_sync_mode = 1'b0;
  bit stage63_pending = 1'b0;
  logic [15:0] stage63_pending_pc = '0;
  time stage63_request_time;
  logic [15:0] stage63_data = '0;
  bit stage63_valid = 1'b0;
  //stage64:retain an already returned instruction through a data-memory stall
  bit stage64_hold_mode = 1'b0;
  logic [15:0] stage64_response_pc = '0;
  initial begin
    stage64_hold_mode = $test$plusargs("CTRL64_HOLD_DURING_DMEM");
    $display("STAGE64_MODE hold=%0d",stage64_hold_mode);
  end
  int unsigned stage63_reads = 0;
  int unsigned stage63_returns = 0;
  initial begin
    stage63_sync_mode = $test$plusargs("CTRL63_SYNC_IMEM");
    $display("STAGE63_MODE sync=%0d",stage63_sync_mode);
  end
  final begin
    if (stage63_sync_mode)
      $display("STAGE63_TOTAL reads=%0d returned=%0d",stage63_reads,stage63_returns);
  end

  //stage65:the returned instruction is associated with its captured request pc
  assign bus.stage65_response_pc = stage64_response_pc;
  assign bus.stage65_response_pc_valid = (initiator_responder == RESPONDER &&
                                        stage63_sync_mode && reset_i === 1'b0 && stage63_valid);
  assign bus.Instr_dout = (initiator_responder == RESPONDER && stage63_sync_mode) ?
    //stage66:registered memory data changes only on a serviced read or reset
    ((reset_i === 1'b0) ? stage63_data : 16'h0000) :
    (initiator_responder == RESPONDER && stage61_contract_mode) ?
    ((reset_i === 1'b0 && stage61_rsp_valid && PC_i === stage61_rsp_pc) ?
       stage61_rsp_data : 16'h0000) :
    (initiator_responder == RESPONDER) ?
    (stage59_spec_mode ?
      ((reset_i === 1'b0 && stage59_rsp_valid && PC_i === stage59_rsp_pc) ? stage59_rsp_data : 16'h0000) :
      Instr_dout_o) : 'bz;
  assign Instr_dout_i = bus.Instr_dout;
  logic [15:0] last_request_pc = 16'h0000;
  //mask acknowledgments until a valid fetch is ready to accept them
  //the default mode retains the existing responder timing
  bit stage27_accept_mode = 1'b0;
  initial stage27_accept_mode = $test$plusargs("ACCEPT_IMEM_ACK");
  wire stage27_valid_fetch = (fetch_ready_i === 1'b1 &&
                                    instrmem_rd_i === 1'b1 &&
                                    (^PC_i !== 1'bx) &&
                                    PC_i === last_request_pc);
  //stage52:hold a fetch acknowledgment through the sampling edge
  //the original live-ready mask can withdraw ack when a branch stalls fetch
  bit stage52_latch_ack_mode = 1'b0;
  bit stage52_ack_armed = 1'b0;
  integer stage52_ack_arm_count = 0;
  initial begin : stage52_mode_probe
    stage52_latch_ack_mode = $test$plusargs("CTRL52_LATCH_ACK");
    #1ns;
    $display("STAGE52_ACK_MODE enabled=%0d version=52.1",stage52_latch_ack_mode);
  end

  //stage55:an isolated request/response transaction flow, disabled by default
  //this mode never derives an acknowledgement from dut internal stall_pipe
  bit stage55_clean_mode = 1'b0;
  bit stage55_ack_armed = 1'b0;
  bit stage55_first_transfer = 1'b1;
  logic [15:0] stage55_pending_pc = 16'h0000;
  int unsigned stage55_requests = 0;
  int unsigned stage55_acknowledgments = 0;
  int unsigned stage55_cancellations = 0;
//stage57:configurable pre-wait for a pending instruction response
//the existing two-cycle delay remains the default
int stage57_pre_wait_cycles = 2;
initial begin : stage57_mode_selection
  int requested_latency;
  if ($value$plusargs("CTRL57_PRE_WAIT_NEGEDGES=%d", requested_latency)) begin
    if (requested_latency >= 0 && requested_latency <= 2)
      stage57_pre_wait_cycles = requested_latency;
    else
      $fatal(1,"STAGE57_INVALID_LATENCY requested=%0d permitted=0,1,2",requested_latency);
  end
  #2ns;
  $display("STAGE57_LATENCY pre_wait_negedges=%0d version=57.1",stage57_pre_wait_cycles);
end
  initial begin : stage55_mode_selection
    stage55_clean_mode = $test$plusargs("CTRL55_CLEAN_IMEM");
    #1ns;
    $display("STAGE55_MODE clean=%0d version=55.1",stage55_clean_mode);
  end

  assign bus.complete_instr = (initiator_responder == RESPONDER && stage63_sync_mode) ?
    (reset_i === 1'b0 && stage63_valid) :
    (initiator_responder == RESPONDER && stage61_contract_mode) ?
    (reset_i === 1'b0 && stage61_rsp_valid && stage61_rsp_complete &&
     PC_i === stage61_rsp_pc) :
    (initiator_responder == RESPONDER && stage59_spec_mode) ?
    (reset_i === 1'b0 && stage59_rsp_valid && stage59_rsp_complete && PC_i === stage59_rsp_pc) :
    ((initiator_responder == RESPONDER) ?
      (stage55_clean_mode ?
        (stage55_ack_armed && complete_instr_o && PC_i === stage55_pending_pc) :
        (stage52_latch_ack_mode ?
          (complete_instr_o && stage52_ack_armed && PC_i === last_request_pc) :
          (stage27_accept_mode ? (complete_instr_o && stage27_valid_fetch) :
                                 complete_instr_o))) : 'bz);
  assign complete_instr_i = bus.complete_instr;

  //stage54:observe the memory-request signals on both sides of the clock edge
  //the monitor is passive, independent of the experimental capture option
  bit stage54_postedge_capture = 1'b0;
  integer stage54_edge_count = 0;
  integer stage54_capture_count = 0;
  initial begin : stage54_mode_probe
    stage54_postedge_capture = $test$plusargs("CTRL54_POSTEDGE_PC");
    #1ns;
    $display("STAGE54_MODE postedge_capture=%0d version=54.1",stage54_postedge_capture);
  end
  always @(posedge clock_i) begin : stage54_passive_edge_probe
    logic [15:0] edge_pre_pc;
    logic edge_pre_rd;
    logic edge_pre_ready;
    logic edge_pre_ack;
    if (stage54_edge_count < 115) begin
      edge_pre_pc = PC_i;
      edge_pre_rd = instrmem_rd_i;
      edge_pre_ready = fetch_ready_i;
      edge_pre_ack = complete_instr_i;
      #1ns;
      $display("STAGE54_EDGE n=%0d pre_pc=%04h post_pc=%04h pre_rd=%b post_rd=%b pre_ready=%b post_ready=%b pre_ack=%b post_ack=%b",
        stage54_edge_count,edge_pre_pc,PC_i,edge_pre_rd,instrmem_rd_i,
        edge_pre_ready,fetch_ready_i,edge_pre_ack,complete_instr_i);
      stage54_edge_count++;
    end
  end

  // Proxy handle to UVM driver
  imem_pkg::imem_driver   proxy;
  // pragma tbx oneway proxy.my_function_name_in_uvm_driver                 

  // ****************************************************************************
  // **************************************************************************** 
  // Macros that define structs located in imem_macros.svh
  // ****************************************************************************
  // Struct for passing configuration data from imem_driver to this BFM
  // ****************************************************************************
  `imem_CONFIGURATION_STRUCT
  // ****************************************************************************
  // Structs for INITIATOR and RESPONDER data flow
  //*******************************************************************
  // Initiator macro used by imem_driver and imem_driver_bfm
  // to communicate initiator driven data to imem_driver_bfm.           
  `imem_INITIATOR_STRUCT
    imem_initiator_s initiator_struct;
  // Responder macro used by imem_driver and imem_driver_bfm
  // to communicate Responder driven data to imem_driver_bfm.
  `imem_RESPONDER_STRUCT
    imem_responder_s responder_struct;

  // ****************************************************************************
// pragma uvmf custom reset_condition_and_response begin
  // Always block used to return signals to reset value upon assertion of reset
  always @( posedge reset_i )
     begin
       // RESPONDER mode output signals
       PC_o <= 'b0;
       instrmem_rd_o <= 'b0;
       I_macc_o <= 'b0;
       // INITIATOR mode output signals
       Instr_dout_o <= 'b0;
       complete_instr_o <= 'b0;
       // Bi-directional signals
 
     end    
// pragma uvmf custom reset_condition_and_response end

  // pragma uvmf custom interface_item_additional begin
  // pragma uvmf custom interface_item_additional end

  //******************************************************************
  // The configure() function is used to pass agent configuration
  // variables to the driver BFM.  It is called by the driver within
  // the agent at the beginning of the simulation.  It may be called 
  // during the simulation if agent configuration variables are updated
  // and the driver BFM needs to be aware of the new configuration 
  // variables.
  //

  function void configure(imem_configuration_s imem_configuration_arg); // pragma tbx xtf  
    initiator_responder = imem_configuration_arg.initiator_responder;
  // pragma uvmf custom configure begin
  // pragma uvmf custom configure end
  endfunction                                                                             

// pragma uvmf custom initiate_and_get_response begin
// ****************************************************************************
// UVMF_CHANGE_ME
// This task is used by an initator.  The task first initiates a transfer then
// waits for the responder to complete the transfer.
    task initiate_and_get_response( 
       // This argument passes transaction variables used by an initiator
       // to perform the initial part of a protocol transfer.  The values
       // come from a sequence item created in a sequence.
       input imem_initiator_s imem_initiator_struct, 
       // This argument is used to send data received from the responder
       // back to the sequence item.  The sequence item is returned to the sequence.
       output imem_responder_s imem_responder_struct 
       );// pragma tbx xtf  
       // 
       // Members within the imem_initiator_struct:
       //   bit [15:0] PC ;
       //   bit instrmem_rd ;
       //   bit I_macc ;
       //   bit [15:0] Instr_dout ;
       //   bit complete_instr ;
       // Members within the imem_responder_struct:
       //   bit [15:0] PC ;
       //   bit instrmem_rd ;
       //   bit I_macc ;
       //   bit [15:0] Instr_dout ;
       //   bit complete_instr ;
       initiator_struct = imem_initiator_struct;
       //
       // Reference code;
       //    How to wait for signal value
       //      while (control_signal == 1'b1) @(posedge clock_i);
       //    
       //    How to assign a responder struct member, named xyz, from a signal.   
       //    All available initiator input and inout signals listed.
       //    Initiator input signals
       //      imem_responder_struct.xyz = PC_i;  //    [15:0] 
       //      imem_responder_struct.xyz = instrmem_rd_i;  //     
       //      imem_responder_struct.xyz = I_macc_i;  //     
       //    Initiator inout signals
       //    How to assign a signal from an initiator struct member named xyz.   
       //    All available initiator output and inout signals listed.
       //    Notice the _o.  Those are storage variables that allow for procedural assignment.
       //    Initiator output signals
       //      Instr_dout_o <= imem_initiator_struct.xyz;  //    [15:0] 
       //      complete_instr_o <= imem_initiator_struct.xyz;  //     
       //    Initiator inout signals
    // Initiate a transfer using the data received.
    @(posedge clock_i);
    @(posedge clock_i);
    // Wait for the responder to complete the transfer then place the responder data into 
    // imem_responder_struct.
    @(posedge clock_i);
    @(posedge clock_i);
    responder_struct = imem_responder_struct;
  endtask        
// pragma uvmf custom initiate_and_get_response end

// pragma uvmf custom respond_and_wait_for_next_transfer begin

  //stage59:the response is available as soon as the uvmf memory item is ready.
  //acceptance is defined by a rising clock edge with an active public read.
  //a pending response stays available throughout a memory stall.
  //stage61:one outstanding public-port request, one UVMF response item
  //request capture occurs after the previous sampled response is withdrawn
  //data/complete are presented before the next sampling posedge
  task stage61_respond_and_wait_for_next_transfer(
    output imem_initiator_s imem_initiator_struct,
    input imem_responder_s imem_responder_struct
  );
    bit sampled;
    imem_initiator_struct = '0;
    wait (reset_i === 1'b0);
    if (stage61_first_transfer) begin
      stage61_first_transfer = 1'b0;
      stage61_rsp_valid = 1'b0;
      stage61_same_pc_block = 1'b0;
    end else begin
      //responder_s contains PC; never deliver a payload for a different request
      if (imem_responder_struct.PC !== stage61_pending_pc ||
          imem_responder_struct.complete_instr !== 1'b1) begin
        stage61_pair_error_count++;
        $error("STAGE61_RESPONSE_PAIR expected_pc=%04h response_pc=%04h complete=%b",
          stage61_pending_pc, imem_responder_struct.PC,
          imem_responder_struct.complete_instr);
      end else if (PC_i !== stage61_pending_pc) begin
        //the old request was redirected before its UVM response arrived
        //cancel it immediately so the replacement PC can be captured now
        stage61_cancel_count++;
        stage61_same_pc_block = 1'b0;
        if (stage61_cancel_count <= 80)
          $display("STAGE61_CANCEL t=%0t old_pc=%04h now_pc=%04h reason=pre_present_redirect",
            $time, stage61_pending_pc, PC_i);
      end else begin
        stage61_rsp_pc = stage61_pending_pc;
        stage61_rsp_data = imem_responder_struct.Instr_dout;
        stage61_rsp_complete = imem_responder_struct.complete_instr;
        stage61_rsp_valid = 1'b1;
        stage61_present_count++;
        if (stage61_present_count <= 80)
          $display("STAGE61_PRESENT t=%0t pc=%04h data=%04h rd=%b",
            $time, stage61_rsp_pc, stage61_rsp_data, instrmem_rd_i);
        //sample at the next rising edge, with the response already stable
        //or cancel immediately if a redirect invalidates the pending address
        //a BR/JMP may deassert instrmem_rd after observing valid data
        begin : stage61_await_response_edge
          bit edge_happened;
          edge_happened = 1'b0;
          fork
            begin
              @(posedge clock_i);
              edge_happened = 1'b1;
            end
            begin
              wait (reset_i !== 1'b0 || PC_i !== stage61_rsp_pc);
            end
          join_any
          disable fork;
          sampled = edge_happened && (reset_i === 1'b0) &&
                    stage61_rsp_valid && PC_i === stage61_rsp_pc &&
                    stage61_rsp_complete;
        end
        if (sampled) begin
          stage61_sample_count++;
          if (stage61_sample_count <= 80)
            $display("STAGE61_SAMPLE t=%0t pc=%04h data=%04h rd=%b",
              $time, stage61_rsp_pc, stage61_rsp_data, instrmem_rd_i);
          //same-address repeated fetch requires new public request evidence
          stage61_same_pc_block = (instrmem_rd_i === 1'b1);
        end else begin
          stage61_cancel_count++;
          stage61_same_pc_block = 1'b0;
          if (stage61_cancel_count <= 80)
            $display("STAGE61_CANCEL t=%0t old_pc=%04h now_pc=%04h reset=%b",
              $time, stage61_rsp_pc, PC_i, reset_i);
        end
        //hold a sampled response through its edge; cancel stale responses now
        if (sampled)
          @(negedge clock_i);
        stage61_rsp_valid = 1'b0;
        stage61_rsp_complete = 1'b0;
      end
    end
    //return the very next public request immediately; no blind extra clock delay
    forever begin
      if (reset_i === 1'b1) begin
        stage61_rsp_valid = 1'b0;
        stage61_same_pc_block = 1'b0;
        wait (reset_i === 1'b0);
      end
      if (stage61_same_pc_block &&
          (instrmem_rd_i !== 1'b1 || PC_i !== stage61_rsp_pc))
        stage61_same_pc_block = 1'b0;
      if (!stage61_same_pc_block && reset_i === 1'b0 &&
          instrmem_rd_i === 1'b1 && (^PC_i !== 1'bx)) begin
        stage61_pending_pc = PC_i;
        imem_initiator_struct.PC = PC_i;
        imem_initiator_struct.instrmem_rd = 1'b1;
        imem_initiator_struct.I_macc = I_macc_i;
        imem_initiator_struct.Instr_dout = Instr_dout_i;
        imem_initiator_struct.complete_instr = complete_instr_i;
        stage61_request_count++;
        if (stage61_request_count <= 80)
          $display("STAGE61_REQUEST t=%0t pc=%04h rd=%b",
            $time, stage61_pending_pc, instrmem_rd_i);
        return;
      end
      @(negedge clock_i or posedge instrmem_rd_i or PC_i or posedge reset_i);
    end
  endtask

  task stage59_spec_respond_and_wait_for_next_transfer(
    output imem_initiator_s imem_initiator_struct,
    input imem_responder_s imem_responder_struct
  );
    bit accepted;
    bit redirected;
    imem_initiator_struct = '0;
    accepted = 1'b0;
    redirected = 1'b0;
    wait (reset_i === 1'b0);

    if (stage59_first_transfer) begin
      stage59_first_transfer = 1'b0;
      stage59_rsp_valid = 1'b0;
    end else begin
      stage59_rsp_pc = stage59_pending_pc;
      stage59_rsp_data = imem_responder_struct.Instr_dout;
      stage59_rsp_complete = imem_responder_struct.complete_instr;
      stage59_rsp_valid = 1'b0;
      if (stage59_rsp_complete !== 1'b1)
        $error("STAGE59_NO_COMPLETION pc=%04h; responder item must eventually complete",stage59_rsp_pc);
      //the specification says new instruction data is released only after
      //instrmem_rd is observed, not because a timer expired.
      wait (reset_i === 1'b1 || PC_i !== stage59_rsp_pc ||
            instrmem_rd_i === 1'b1);
      if (reset_i === 1'b0 && PC_i === stage59_rsp_pc &&
          instrmem_rd_i === 1'b1) begin
        //latch the permission to respond so that a control hazard cannot
        //revoke the memory completion combinationally before the clock edge.
        stage59_rsp_valid = 1'b1;
      end else begin
        redirected = 1'b1;
      end
      while (!redirected) begin
        @(posedge clock_i or posedge reset_i);
        if (reset_i === 1'b1) begin
          redirected = 1'b1;
          break;
        end
        if ((^PC_i !== 1'bx) && PC_i !== stage59_rsp_pc) begin
          redirected = 1'b1;
          stage59_redirect_count++;
          if (stage59_redirect_count <= 40)
            $display("STAGE59_REDIRECT t=%0t old=%04h new=%04h rd=%b",$time,stage59_rsp_pc,PC_i,instrmem_rd_i);
          break;
        end
        //a read was already observed and latched before this edge;
        //it may have deasserted as a consequence of control logic.
        if (stage59_rsp_valid && PC_i === stage59_rsp_pc &&
            stage59_rsp_complete === 1'b1) begin
          accepted = 1'b1;
          stage59_ack_count++;
          if (stage59_ack_count <= 80)
            $display("STAGE59_ACCEPT t=%0t pc=%04h instr=%04h rd=%b",$time,stage59_rsp_pc,stage59_rsp_data,instrmem_rd_i);
          break;
        end
      end
      //preserve the valid response through the sampling edge.
      //negedge is for drive/sampling separation, not a response-latency guess.
      @(negedge clock_i);
      stage59_rsp_valid = 1'b0;
      stage59_rsp_complete = 1'b0;
      if (reset_i === 1'b1)
        wait (reset_i === 1'b0);
      if (accepted) begin
        //do not respond twice to one continuously asserted read for the same pc.
        wait (reset_i === 1'b1 || instrmem_rd_i !== 1'b1 ||
              PC_i !== stage59_rsp_pc);
        if (reset_i === 1'b1)
          wait (reset_i === 1'b0);
      end
    end

    forever begin
      @(posedge clock_i);
      if (reset_i === 1'b0 && instrmem_rd_i === 1'b1 &&
          (^PC_i !== 1'bx)) begin
        stage59_pending_pc = PC_i;
        imem_initiator_struct.PC = PC_i;
        imem_initiator_struct.instrmem_rd = instrmem_rd_i;
        imem_initiator_struct.I_macc = I_macc_i;
        imem_initiator_struct.Instr_dout = Instr_dout_i;
        imem_initiator_struct.complete_instr = complete_instr_i;
        stage59_request_count++;
        if (stage59_request_count <= 80)
          $display("STAGE59_REQUEST t=%0t pc=%04h rd=%b",$time,stage59_pending_pc,instrmem_rd_i);
        return;
      end
    end
  endtask

  //stage55:complete alternative transaction-state implementation
  //the UVM driver invokes this once per responder sequence item.
  //the current call services the previous request, then returns the next request.
  task stage55_clean_respond_and_wait_for_next_transfer(
    output imem_initiator_s imem_initiator_struct,
    input imem_responder_s imem_responder_struct
  );
    bit response_completed;
    bit response_cancelled;
    imem_initiator_struct = '0;
    response_completed = 1'b0;
    response_cancelled = 1'b0;
    wait (reset_i === 1'b0);

    if (stage55_first_transfer) begin
      stage55_first_transfer = 1'b0;
      Instr_dout_o = 16'h0000;
      complete_instr_o = 1'b0;
      stage55_ack_armed = 1'b0;
    end else begin
      //preserve the existing memory latency for a fair baseline comparison
      repeat (stage57_pre_wait_cycles) @(negedge clock_i);
      while (reset_i === 1'b0) begin
        @(negedge clock_i);
        //the old outstanding response must not be delivered to a new PC
        if ((^PC_i !== 1'bx) &&
            PC_i !== stage55_pending_pc) begin
          response_cancelled = 1'b1;
          stage55_cancellations++;
          if (stage55_cancellations <= 64)
            $display("STAGE55_CANCEL t=%0t old_pc=%04h new_pc=%04h",
              $time,stage55_pending_pc,PC_i);
          break;
        end
        //only a live public fetch request can receive the response
        if (instrmem_rd_i === 1'b1 && PC_i === stage55_pending_pc) begin
          Instr_dout_o = imem_responder_struct.Instr_dout;
          complete_instr_o = imem_responder_struct.complete_instr;
          stage55_ack_armed = 1'b1;
          //data and completion are driven before the sampling posedge
          @(posedge clock_i);
          response_completed = (complete_instr_i === 1'b1);
          if (response_completed) begin
            stage55_acknowledgments++;
            if (stage55_acknowledgments <= 64)
              $display("STAGE55_ACK t=%0t pc=%04h data=%04h rd=%b count=%0d",
                $time,stage55_pending_pc,imem_responder_struct.Instr_dout,
                instrmem_rd_i,stage55_acknowledgments);
          end
          @(negedge clock_i);
          stage55_ack_armed = 1'b0;
          complete_instr_o = 1'b0;
          break;
        end
      end
      if (reset_i === 1'b1) begin
        stage55_ack_armed = 1'b0;
        complete_instr_o = 1'b0;
        Instr_dout_o = 16'h0000;
        wait (reset_i === 1'b0);
      end
      //a completed request must withdraw or change before another response
      //same-address requests remain possible after an observable read deassertion
      if (response_completed) begin
        while (reset_i === 1'b0 && instrmem_rd_i === 1'b1 &&
               PC_i === stage55_pending_pc)
          @(negedge clock_i);
      end
    end

    //capture the new request at a rising edge, as in the prior responder
    //never infer request identity solely from a changed PC value
    forever begin
      @(posedge clock_i);
      if (reset_i === 1'b0 && instrmem_rd_i === 1'b1 &&
          (^PC_i !== 1'bx)) begin
        stage55_pending_pc = PC_i;
        stage55_requests++;
        if (stage55_requests <= 64)
          $display("STAGE55_REQUEST t=%0t pc=%04h rd=%b count=%0d",
            $time,stage55_pending_pc,instrmem_rd_i,stage55_requests);
        imem_initiator_struct.PC = PC_i;
        imem_initiator_struct.instrmem_rd = instrmem_rd_i;
        imem_initiator_struct.I_macc = I_macc_i;
        imem_initiator_struct.Instr_dout = Instr_dout_i;
        imem_initiator_struct.complete_instr = complete_instr_i;
        return;
      end
    end
  endtask


//the imem responder must capture a pending fetch before a data-memory stall
//and must not complete that fetch until instrmem_rd is asserted again
bit first_transfer = 1'b1;
integer stage26_ack_issue_count = 0;
integer stage27_accept_count = 0;

  //sample the public memory request at the rising edge; the sequence computes
  //the response in zero simulation time. publish using nba so the previous
  //response remains stable for the dut sampling that same edge.
  //pc is the request address, not a live qualifier on the registered response.
  task stage63_respond_and_wait_for_next_transfer(
    output imem_initiator_s imem_initiator_struct,
    input imem_responder_s imem_responder_struct
  );
    imem_initiator_struct = '0;
    if (stage63_pending) begin
      if (reset_i !== 1'b0) begin
        stage63_valid <= 1'b0;
      end else begin
        if (imem_responder_struct.PC !== stage63_pending_pc ||
            imem_responder_struct.complete_instr !== 1'b1)
          $fatal(1,"STAGE63_RESPONSE_PAIR pc=%04h returned=%04h valid=%b",
                 stage63_pending_pc,imem_responder_struct.PC,
                 imem_responder_struct.complete_instr);
        if ($time != stage63_request_time)
          $fatal(1,"STAGE63_RESPONSE_LATENCY request=%0t response=%0t: synchronous service requires zero-time sequence",stage63_request_time,$time);
        stage64_response_pc <= stage63_pending_pc;
        stage63_data <= imem_responder_struct.Instr_dout;
        stage63_valid <= 1'b1;
        stage63_returns++;
        $display("STAGE63_RETURN t=%0t pc=%04h data=%04h",$time,
                 stage63_pending_pc,imem_responder_struct.Instr_dout);
      end
      stage63_pending = 1'b0;
    end
    forever begin
      @(posedge clock_i);
      if (reset_i !== 1'b0) begin
        stage63_valid <= 1'b0;
        stage63_data <= '0;
      end else if (instrmem_rd_i === 1'b1 && !$isunknown(PC_i)) begin
        stage63_pending_pc = PC_i;
        stage63_request_time = $time;
        stage63_pending = 1'b1;
        imem_initiator_struct.PC = PC_i;
        imem_initiator_struct.instrmem_rd = 1'b1;
        imem_initiator_struct.I_macc = I_macc_i;
        imem_initiator_struct.Instr_dout = Instr_dout_i;
        imem_initiator_struct.complete_instr = complete_instr_i;
        stage63_reads++;
        $display("STAGE63_READ t=%0t pc=%04h rd=1",$time,PC_i);
        return;
      end else if (stage64_hold_mode && stage63_valid &&
                   ((bus.data_mem_rd === 1'b0) || (bus.data_mem_rd === 1'b1))) begin
        //active public data-memory read/write: pipeline is frozen
        //do not erase a fetched instruction that decode has not advanced
        $display("STAGE64_HOLD t=%0t response_pc=%04h live_pc=%04h data=%04h data_rd=%b",
                 $time,stage64_response_pc,PC_i,stage63_data,bus.data_mem_rd);
      end else begin
        //stage66:expire validity without overwriting the registered word
        //complete_instr qualifies the data; no request means no new memory word
        stage63_valid <= 1'b0;
        if (stage63_valid)
          $display("STAGE66_IDLE_HOLD t=%0t response_pc=%04h data=%04h rd=%b",
                   $time,stage64_response_pc,stage63_data,instrmem_rd_i);
      end
    end
  endtask

  task respond_and_wait_for_next_transfer(
    output imem_initiator_s imem_initiator_struct,
    input imem_responder_s imem_responder_struct
  );// pragma tbx xtf
    if (stage63_sync_mode) begin
      stage63_respond_and_wait_for_next_transfer(imem_initiator_struct,imem_responder_struct);
      return;
    end
    if (stage61_contract_mode) begin
      stage61_respond_and_wait_for_next_transfer(
        imem_initiator_struct, imem_responder_struct);
      return;
    end
    if (stage59_spec_mode) begin
      stage59_spec_respond_and_wait_for_next_transfer(
        imem_initiator_struct, imem_responder_struct);
      return;
    end
    if (stage55_clean_mode) begin
      stage55_clean_respond_and_wait_for_next_transfer(
        imem_initiator_struct,imem_responder_struct);
      return;
    end
    imem_initiator_struct = '0;
    wait (reset_i === 1'b0);

    if (first_transfer) begin
      first_transfer = 1'b0;
      Instr_dout_o = 16'h0000;
      complete_instr_o = 1'b0;
    end else begin
      //maintain the existing two-falling-edge response latency
      //the pending pc was captured on the preceding rising edge
      @(negedge clock_i);
      @(negedge clock_i);

      //a data-memory access can temporarily disable instruction fetching
      //keep the response pending until this pc can actually accept it
      //the guarded run defers a pending response until the controller unstalls
      if ($test$plusargs("ACCEPT_IMEM_ACK")) begin
        wait (reset_i === 1'b1 ||
              (instrmem_rd_i === 1'b1 &&
               PC_i === last_request_pc));
      end else if ($test$plusargs("GUARD_IMEM_ACK")) begin
        wait (reset_i === 1'b1 ||
              (instrmem_rd_i === 1'b1 &&
               PC_i === last_request_pc &&
               fetch_ready_i === 1'b1));
      end else begin
        wait (reset_i === 1'b1 ||
              (instrmem_rd_i === 1'b1 && PC_i === last_request_pc));
      end

      if ($test$plusargs("TRACE_ACK_GUARD") &&
          stage26_ack_issue_count < 32) begin
        $display("STAGE26_ACK_RELEASE t=%0t guard=%0d ready=%b rd=%b pc=%04h req_pc=%04h ack_value=%b",
                 $time, $test$plusargs("GUARD_IMEM_ACK"),
                 fetch_ready_i, instrmem_rd_i, PC_i,
                 last_request_pc, imem_responder_struct.complete_instr);
        stage26_ack_issue_count = stage26_ack_issue_count + 1;
      end

      if (reset_i === 1'b1) begin
        Instr_dout_o = 16'h0000;
        complete_instr_o = 1'b0;
        wait (reset_i === 1'b0);
      end else begin
        //drive before the next rising edge and hold for a complete cycle
        if ($test$plusargs("ACCEPT_IMEM_ACK")) begin
          bit stage27_accepted;
          bit stage30_cancelled;
          integer stage27_hold_cycles;
          stage27_accepted = 1'b0;
          stage30_cancelled = 1'b0;
          stage27_hold_cycles = 0;
          //start an acknowledgement on a falling edge to avoid posedge races
          @(negedge clock_i);
          if (stage52_latch_ack_mode) begin
            //wait before exposing instruction data, then latch the grant
            //this avoids a combinational ack/fetch-ready feedback loop
            while (reset_i === 1'b0 && stage27_valid_fetch !== 1'b1)
              @(negedge clock_i);
            stage52_ack_armed = (reset_i === 1'b0 && stage27_valid_fetch === 1'b1);
            if (stage52_ack_arm_count < 30) begin
              $display("STAGE52_ACK_ARM t=%0t armed=%0d pc=%04h req=%04h rd=%b ready=%b data=%04h",
                $time,stage52_ack_armed,PC_i,last_request_pc,instrmem_rd_i,
                fetch_ready_i,imem_responder_struct.Instr_dout);
              stage52_ack_arm_count++;
            end
          end
          Instr_dout_o = imem_responder_struct.Instr_dout;
          complete_instr_o = imem_responder_struct.complete_instr;
          while (!stage27_accepted && !stage30_cancelled && reset_i === 1'b0) begin
            @(posedge clock_i);
            //a redirect can change pc while the previous response is pending
            //the old pc will never return, so release this response to service the new pc
            if (stage30_cancel_redirect_mode &&
                (^PC_i !== 1'bx) &&
                PC_i !== last_request_pc) begin
              stage30_cancelled = 1'b1;
              if (stage30_cancel_count < 32) begin
                $display("STAGE30_REDIRECT_CANCEL t=%0t old_pc=%04h new_pc=%04h rd=%b ready=%b held_cycles=%0d",
                  $time, last_request_pc, PC_i, instrmem_rd_i,
                  fetch_ready_i, stage27_hold_cycles);
                stage30_cancel_count++;
              end
            end else begin
              //qualified by the same readiness predicate as the bus output
              //sample acceptance once per rising clock edge
              stage27_accepted = (imem_responder_struct.complete_instr === 1'b1 &&
                (stage52_latch_ack_mode ?
                  (stage52_ack_armed && PC_i === last_request_pc) :
                  stage27_valid_fetch));
              if (!stage27_accepted) begin
                stage27_hold_cycles++;
                if ($test$plusargs("TRACE_ACCEPT_IMEM") &&
                    stage27_hold_cycles <= 4)
                  $display("STAGE27_HOLD t=%0t pc=%04h req=%04h rd=%b ready=%b cycles=%0d",
                    $time, PC_i, last_request_pc, instrmem_rd_i,
                    fetch_ready_i, stage27_hold_cycles);
              end else if ($test$plusargs("TRACE_ACCEPT_IMEM") &&
                           stage27_accept_count < 32) begin
                $display("STAGE27_ACCEPT t=%0t pc=%04h data=%04h held_cycles=%0d ready=%b",
                  $time, last_request_pc, imem_responder_struct.Instr_dout,
                  stage27_hold_cycles, fetch_ready_i);
                stage27_accept_count++;
              end
            end
          end
          @(negedge clock_i);
          complete_instr_o = 1'b0;
          stage52_ack_armed = 1'b0;
        end else begin
          Instr_dout_o = imem_responder_struct.Instr_dout;
          complete_instr_o = imem_responder_struct.complete_instr;
          @(posedge clock_i);
          @(negedge clock_i);
          complete_instr_o = 1'b0;
        end
      end

      //the lc3 may keep instrmem_rd high across consecutive pc values
      wait (reset_i === 1'b1 ||
            instrmem_rd_i === 1'b0 ||
            (instrmem_rd_i === 1'b1 &&
             (^PC_i !== 1'bx) &&
             PC_i !== last_request_pc));

      if (reset_i === 1'b1) begin
        Instr_dout_o = 16'h0000;
        complete_instr_o = 1'b0;
        wait (reset_i === 1'b0);
      end
    end

    //capture at the first valid rising edge, not a later falling edge
    //the falling-edge sampling in stage 8e missed pc=3005 as a store stalled
    do begin
      wait (reset_i === 1'b1 ||
            (instrmem_rd_i === 1'b1 && (^PC_i !== 1'bx)));
      if (reset_i === 1'b1)
        wait (reset_i === 1'b0);
      @(posedge clock_i);
      if (stage54_postedge_capture) begin
        //the design may update PC in the NBA region of this posedge
        //sampling one nanosecond afterward is an *experiment*, not default behavior
        #1ns;
      end
    end while (reset_i !== 1'b0 ||
               instrmem_rd_i !== 1'b1 ||
               (^PC_i === 1'bx));

    if (stage54_capture_count < 75) begin
      $display("STAGE54_REQUEST n=%0d mode=%0d pc=%04h rd=%b ready=%b ack=%b",
        stage54_capture_count,stage54_postedge_capture,PC_i,instrmem_rd_i,
        fetch_ready_i,complete_instr_i);
      stage54_capture_count++;
    end
    imem_initiator_struct.PC = PC_i;
    last_request_pc = PC_i;
    imem_initiator_struct.instrmem_rd = instrmem_rd_i;
    imem_initiator_struct.I_macc = I_macc_i;
    imem_initiator_struct.Instr_dout = Instr_dout_i;
    imem_initiator_struct.complete_instr = complete_instr_i;
  endtask
// pragma uvmf custom respond_and_wait_for_next_transfer end

 
endinterface

// pragma uvmf custom external begin
// pragma uvmf custom external end

