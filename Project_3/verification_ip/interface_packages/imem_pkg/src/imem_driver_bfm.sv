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

  // These are signals marked as 'input' by the config file, but the signals will be
  // driven by this BFM if put into RESPONDER mode (flipping all signal directions around)
  assign PC_i = bus.PC;
  assign bus.PC = (initiator_responder == RESPONDER) ? PC_o : 'bz;
  assign instrmem_rd_i = bus.instrmem_rd;
  assign bus.instrmem_rd = (initiator_responder == RESPONDER) ? instrmem_rd_o : 'bz;
  assign I_macc_i = bus.I_macc;
  assign bus.I_macc = (initiator_responder == RESPONDER) ? I_macc_o : 'bz;


  // These are signals marked as 'output' by the config file, but the outputs will
  // not be driven by this BFM unless placed in INITIATOR mode.
  assign bus.Instr_dout = (initiator_responder == INITIATOR) ? Instr_dout_o : 'bz;
  assign Instr_dout_i = bus.Instr_dout;
  assign bus.complete_instr = (initiator_responder == INITIATOR) ? complete_instr_o : 'bz;
  assign complete_instr_i = bus.complete_instr;

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
  always @( negedge reset_i )
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
// ****************************************************************************
// The first_transfer variable is used to prevent completing a transfer in the 
// first call to this task.  For the first call to this task, there is not
// current transfer to complete.
bit first_transfer=1;

// UVMF_CHANGE_ME
// This task is used by a responder.  The task first completes the current 
// transfer in progress then waits for the initiator to start the next transfer.
  task respond_and_wait_for_next_transfer( 
       // This argument is used to send data received from the initiator
       // back to the sequence item.  The sequence determines how to respond.
       output imem_initiator_s imem_initiator_struct, 
       // This argument passes transaction variables used by a responder
       // to complete a protocol transfer.  The values come from a sequence item.       
       input imem_responder_s imem_responder_struct 
       );// pragma tbx xtf   
  // Variables within the imem_initiator_struct:
  //   bit [15:0] PC ;
  //   bit instrmem_rd ;
  //   bit I_macc ;
  //   bit [15:0] Instr_dout ;
  //   bit complete_instr ;
  // Variables within the imem_responder_struct:
  //   bit [15:0] PC ;
  //   bit instrmem_rd ;
  //   bit I_macc ;
  //   bit [15:0] Instr_dout ;
  //   bit complete_instr ;
       // Reference code;
       //    How to wait for signal value
       //      while (control_signal == 1'b1) @(posedge clock_i);
       //    
       //    How to assign a initiator struct member, named xyz, from a signal.   
       //    All available responder input and inout signals listed.
       //    Responder input signals
       //      imem_initiator_struct.xyz = Instr_dout_i;  //    [15:0] 
       //      imem_initiator_struct.xyz = complete_instr_i;  //     
       //    Responder inout signals
       //    How to assign a signal, named xyz, from an responder struct member.   
       //    All available responder output and inout signals listed.
       //    Notice the _o.  Those are storage variables that allow for procedural assignment.
       //    Responder output signals
       //      PC_o <= imem_responder_struct.xyz;  //    [15:0] 
       //      instrmem_rd_o <= imem_responder_struct.xyz;  //     
       //      I_macc_o <= imem_responder_struct.xyz;  //     
       //    Responder inout signals
    
  @(posedge clock_i);
  if (!first_transfer) begin
    // Perform transfer response here.   
    // Reply using data recieved in the imem_responder_struct.
    @(posedge clock_i);
    // Reply using data recieved in the transaction handle.
    @(posedge clock_i);
  end
    // Wait for next transfer then gather info from intiator about the transfer.
    // Place the data into the imem_initiator_struct.
    @(posedge clock_i);
    @(posedge clock_i);
    first_transfer = 0;
  endtask
// pragma uvmf custom respond_and_wait_for_next_transfer end

 
endinterface

// pragma uvmf custom external begin
// pragma uvmf custom external end

