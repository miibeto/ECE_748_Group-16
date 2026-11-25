//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: 
//    This interface performs the dmem signal driving.  It is
//     accessed by the uvm dmem driver through a virtual interface
//     handle in the dmem configuration.  It drives the singals passed
//     in through the port connection named bus of type dmem_if.
//
//     Input signals from the dmem_if are assigned to an internal input
//     signal with a _i suffix.  The _i signal should be used for sampling.
//
//     The input signal connections are as follows:
//       bus.signal -> signal_i 
//
//     This bfm drives signals with a _o suffix.  These signals
//     are driven onto signals within dmem_if based on INITIATOR/RESPONDER and/or
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
import dmem_pkg_hdl::*;
`include "src/dmem_macros.svh"

interface dmem_driver_bfm 
  (dmem_if bus);
  // The following pragma and additional ones in-lined further below are for running this BFM on Veloce
  // pragma attribute dmem_driver_bfm partition_interface_xif

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

  // Signal list (all signals are capable of being inputs and outputs for the sake
  // of supporting both INITIATOR and RESPONDER mode operation. Expectation is that 
  // directionality in the config file was from the point-of-view of the INITIATOR

  // INITIATOR mode input signals
  tri [15:0] Data_addr_i;
  reg [15:0] Data_addr_o = 'b0;
  tri [15:0] Data_din_i;
  reg [15:0] Data_din_o = 'b0;
  tri  Data_rd_i;
  reg  Data_rd_o = 'b0;
  tri  D_macc_i;
  reg  D_macc_o = 'b0;

  // INITIATOR mode output signals
  tri [15:0] Data_dout_i;
  reg [15:0] Data_dout_o = 'b0;
  tri  complete_data_i;
  reg  complete_data_o = 'b0;

  // Bi-directional signals
  

  assign clock_i = bus.clock;
  assign reset_i = bus.reset;

  // These are signals marked as 'input' by the config file, but the signals will be
  // driven by this BFM if put into RESPONDER mode (flipping all signal directions around)
  assign Data_addr_i = bus.Data_addr;
  assign bus.Data_addr = (initiator_responder == INITIATOR) ? Data_addr_o : 'bz;
  assign Data_din_i = bus.Data_din;
  assign bus.Data_din = (initiator_responder == INITIATOR) ? Data_din_o : 'bz;
  assign Data_rd_i = bus.Data_rd;
  assign bus.Data_rd = (initiator_responder == INITIATOR) ? Data_rd_o : 'bz;
  assign D_macc_i = bus.D_macc;
  assign bus.D_macc = (initiator_responder == INITIATOR) ? D_macc_o : 'bz;


  // These are signals marked as 'output' by the config file, but the outputs will
  // not be driven by this BFM unless placed in INITIATOR mode.
  assign bus.Data_dout = (initiator_responder == RESPONDER) ? Data_dout_o : 'bz;
  assign Data_dout_i = bus.Data_dout;
  assign bus.complete_data = (initiator_responder == RESPONDER) ? complete_data_o : 'bz;
  assign complete_data_i = bus.complete_data;

  // Proxy handle to UVM driver
  dmem_pkg::dmem_driver   proxy;
  // pragma tbx oneway proxy.my_function_name_in_uvm_driver                 

  // ****************************************************************************
  // **************************************************************************** 
  // Macros that define structs located in dmem_macros.svh
  // ****************************************************************************
  // Struct for passing configuration data from dmem_driver to this BFM
  // ****************************************************************************
  `dmem_CONFIGURATION_STRUCT
  // ****************************************************************************
  // Structs for INITIATOR and RESPONDER data flow
  //*******************************************************************
  // Initiator macro used by dmem_driver and dmem_driver_bfm
  // to communicate initiator driven data to dmem_driver_bfm.           
  `dmem_INITIATOR_STRUCT
    dmem_initiator_s initiator_struct;
  // Responder macro used by dmem_driver and dmem_driver_bfm
  // to communicate Responder driven data to dmem_driver_bfm.
  `dmem_RESPONDER_STRUCT
    dmem_responder_s responder_struct;

  // ****************************************************************************
// pragma uvmf custom reset_condition_and_response begin
  // Always block used to return signals to reset value upon assertion of reset
  always @( posedge reset_i )
     begin
       // RESPONDER mode output signals
       Data_addr_o <= 'b0;
       Data_din_o <= 'b0;
       Data_rd_o <= 'b0;
       D_macc_o <= 'b0;
       // INITIATOR mode output signals
       Data_dout_o <= 'b0;
       complete_data_o <= 'b0;
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

  function void configure(dmem_configuration_s dmem_configuration_arg); // pragma tbx xtf  
    initiator_responder = dmem_configuration_arg.initiator_responder;
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
       input dmem_initiator_s dmem_initiator_struct, 
       // This argument is used to send data received from the responder
       // back to the sequence item.  The sequence item is returned to the sequence.
       output dmem_responder_s dmem_responder_struct 
       );// pragma tbx xtf  
       // 
       // Members within the dmem_initiator_struct:
       //   bit [15:0] Data_addr ;
       //   bit [15:0] Data_din ;
       //   bit Data_rd ;
       //   bit D_macc ;
       //   bit [15:0] Data_dout ;
       //   bit complete_data ;
       // Members within the dmem_responder_struct:
       //   bit [15:0] Data_addr ;
       //   bit [15:0] Data_din ;
       //   bit Data_rd ;
       //   bit D_macc ;
       //   bit [15:0] Data_dout ;
       //   bit complete_data ;
       initiator_struct = dmem_initiator_struct;
       //
       // Reference code;
       //    How to wait for signal value
       //      while (control_signal == 1'b1) @(posedge clock_i);
       //    
       //    How to assign a responder struct member, named xyz, from a signal.   
       //    All available initiator input and inout signals listed.
       //    Initiator input signals
       //      dmem_responder_struct.xyz = Data_addr_i;  //    [15:0] 
       //      dmem_responder_struct.xyz = Data_din_i;  //    [15:0] 
       //      dmem_responder_struct.xyz = Data_rd_i;  //     
       //      dmem_responder_struct.xyz = D_macc_i;  //     
       //    Initiator inout signals
       //    How to assign a signal from an initiator struct member named xyz.   
       //    All available initiator output and inout signals listed.
       //    Notice the _o.  Those are storage variables that allow for procedural assignment.
       //    Initiator output signals
       //      Data_dout_o <= dmem_initiator_struct.xyz;  //    [15:0] 
       //      complete_data_o <= dmem_initiator_struct.xyz;  //     
       //    Initiator inout signals
    // Initiate a transfer using the data received.
    @(posedge clock_i);
    @(posedge clock_i);
    // Wait for the responder to complete the transfer then place the responder data into 
    // dmem_responder_struct.
    @(posedge clock_i);
    @(posedge clock_i);
    responder_struct = dmem_responder_struct;
  endtask        
// pragma uvmf custom initiate_and_get_response end

// pragma uvmf custom respond_and_wait_for_next_transfer begin
//the responder owns data_dout and complete_data; the dut owns address/data/rd
//stage39 passive driver transaction tracing
integer stage39_dmem_request_count=0;
integer stage39_dmem_ack_count=0;
bit stage39_dmem_trace=1'b0;
int stage40_ack_hold_cycles=1;
int stage41_response_delay_cycles=0;
bit stage43_zero_wait = 1'b0;
int stage43_zero_wait_arg = 0;
int stage41_response_delay_arg=0;
int stage40_ack_arg=0;
initial begin : stage39_dmem_mode
  stage39_dmem_trace=$test$plusargs("TRACE39_DMEM");
  $display("STAGE39_BFM_MODE enabled=%0d version=39.1", stage39_dmem_trace);
  if ($value$plusargs("DMEM_ACK_HOLD_CYCLES=%d", stage40_ack_arg)) begin
    if (stage40_ack_arg >= 1 && stage40_ack_arg <= 5)
      stage40_ack_hold_cycles=stage40_ack_arg;
    else
      $display("STAGE40_ACK_BAD_ARG requested=%0d using=1 valid_range=1..5", stage40_ack_arg);
  end
  $display("STAGE40_ACK_MODE hold_cycles=%0d version=40.1", stage40_ack_hold_cycles);
  if ($value$plusargs("DMEM_RESPONSE_DELAY_CYCLES=%d", stage41_response_delay_arg)) begin
    if (stage41_response_delay_arg >= 0 && stage41_response_delay_arg <= 5)
      stage41_response_delay_cycles=stage41_response_delay_arg;
    else
      $display("STAGE41_DELAY_BAD_ARG requested=%0d using=0 valid_range=0..5", stage41_response_delay_arg);
  end
  $display("STAGE41_DELAY_MODE delay_cycles=%0d ack_hold_cycles=%0d version=41.1",
    stage41_response_delay_cycles, stage40_ack_hold_cycles);
  if ($value$plusargs("DMEM_ZERO_WAIT=%d", stage43_zero_wait_arg)) begin
    if (stage43_zero_wait_arg == 0 || stage43_zero_wait_arg == 1)
      stage43_zero_wait = (stage43_zero_wait_arg == 1);
    else
      $fatal(1, "STAGE43_BAD_ARG DMEM_ZERO_WAIT=%0d; expected 0 or 1", stage43_zero_wait_arg);
  end else if ($test$plusargs("DMEM_ZERO_WAIT")) begin
    stage43_zero_wait = 1'b1;
  end
  if (stage43_zero_wait && (stage40_ack_hold_cycles != 1 || stage41_response_delay_cycles != 0))
    $fatal(1, "STAGE43_INCOMPATIBLE zero_wait requires hold=1 and delay=0");
  $display("STAGE43_DMEM_MODE zero_wait=%0d hold=%0d delay=%0d version=43.1",
      stage43_zero_wait, stage40_ack_hold_cycles, stage41_response_delay_cycles);
end

bit first_transfer=1;
logic [15:0] last_request_addr=16'h0000;
logic [15:0] last_request_data=16'h0000;
logic last_request_rd=1'b0;

  task respond_and_wait_for_next_transfer(
    output dmem_initiator_s dmem_initiator_struct,
    input dmem_responder_s dmem_responder_struct
  );// pragma tbx xtf
    dmem_initiator_struct='0;
    wait (reset_i === 1'b0);

    if (first_transfer) begin
      first_transfer=0;
      Data_dout_o=16'h0000;
      complete_data_o=1'b0;
    end else begin
      //drive the response before a rising dut clock and hold across that edge
      //capture a brief request-idle interval while the response is asserted
      //the dut may deassert and reassert d_macc before this task re-arms
      begin
        bit request_went_idle;
        request_went_idle=1'b0;
        //stage41 response-latency experiment: keep ack width and response data unchanged
        //wait extra full cycles before driving the completion pulse
        //zero-wait responds during the same low-clock phase as request acceptance
        //the driver still provides exactly one complete_data pulse spanning a rising edge
        if (!stage43_zero_wait) begin
          repeat (stage41_response_delay_cycles) @(negedge clock_i);
          @(negedge clock_i);
        end
        if (stage41_response_delay_cycles > 0 &&
            (D_macc_i !== 1'b1 ||
             Data_addr_i !== last_request_addr ||
             Data_rd_i !== last_request_rd ||
             (last_request_rd === 1'b0 && Data_din_i !== last_request_data))) begin
          $display("STAGE41_REQUEST_CHANGED t=%0t addr_old=%04h addr_now=%04h rd_old=%b rd_now=%b req=%b",
            $time, last_request_addr, Data_addr_i, last_request_rd, Data_rd_i, D_macc_i);
        end
        Data_dout_o=dmem_responder_struct.Data_dout;
        complete_data_o=dmem_responder_struct.complete_data;
        if (stage39_dmem_trace && complete_data_o === 1'b1) begin
          stage39_dmem_ack_count=stage39_dmem_ack_count+1;
          $display("STAGE39_BFM_ACK t=%0t n=%0d addr=%04h din=%04h rd=%b data=%04h req=%b",
            $time, stage39_dmem_ack_count, last_request_addr,
            last_request_data, last_request_rd, Data_dout_o, D_macc_i);
        end
        //stage40 experimental acknowledgment stretch; default 1 preserves stage39
        repeat (stage40_ack_hold_cycles) begin
          @(posedge clock_i);
          if (D_macc_i !== 1'b1)
            request_went_idle=1'b1;
          @(negedge clock_i);
          if (D_macc_i !== 1'b1)
            request_went_idle=1'b1;
        end
        complete_data_o=1'b0;
        if (stage39_dmem_trace) begin
          $display("STAGE39_BFM_ACK_END t=%0t n=%0d addr=%04h request_idle=%b req_now=%b",
            $time, stage39_dmem_ack_count,
            last_request_addr, request_went_idle, D_macc_i);
          $display("STAGE40_ACK_END t=%0t n=%0d hold_cycles=%0d req_now=%b",
            $time, stage39_dmem_ack_count, stage40_ack_hold_cycles, D_macc_i);
        end

        //do not mistake a returned-high request for an unbroken old request
        if (!request_went_idle) begin
          wait (D_macc_i !== 1'b1 ||
                Data_addr_i !== last_request_addr ||
                Data_rd_i !== last_request_rd ||
                (last_request_rd === 1'b0 && Data_din_i !== last_request_data) ||
                reset_i === 1'b1);
        end
      end
      if (reset_i === 1'b1) begin
        complete_data_o=1'b0;
        Data_dout_o=16'h0000;
        wait (reset_i === 1'b0);
      end
    end

    //D_macc is a testbench-generated valid qualifier from mem_state
    //Data_rd=1: read, Data_rd=0: write
    wait (D_macc_i === 1'b1 &&
          (Data_rd_i === 1'b0 || Data_rd_i === 1'b1) &&
          (^Data_addr_i !== 1'bx));
    @(negedge clock_i);
    dmem_initiator_struct.Data_addr=Data_addr_i;
    dmem_initiator_struct.Data_din=Data_din_i;
    dmem_initiator_struct.Data_rd=Data_rd_i;
    dmem_initiator_struct.D_macc=D_macc_i;
    dmem_initiator_struct.Data_dout=Data_dout_i;
    dmem_initiator_struct.complete_data=complete_data_i;
    last_request_addr=Data_addr_i;
    last_request_data=Data_din_i;
    last_request_rd=Data_rd_i;
    if (stage39_dmem_trace) begin
      stage39_dmem_request_count=stage39_dmem_request_count+1;
      $display("STAGE39_BFM_REQ t=%0t n=%0d addr=%04h din=%04h rd=%b req=%b",
        $time, stage39_dmem_request_count, last_request_addr,
        last_request_data, last_request_rd, D_macc_i);
    end
  endtask
// pragma uvmf custom respond_and_wait_for_next_transfer end

 
endinterface

// pragma uvmf custom external begin
// pragma uvmf custom external end

