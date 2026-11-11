//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
// File: dmem_driver_bfm.sv
// Description: BFM driving and sampling Data Memory interface signals 
//              for LC-3 in RESPONDER mode.
//----------------------------------------------------------------------

import uvmf_base_pkg_hdl::*;
import dmem_pkg_hdl::*;
`include "src/dmem_macros.svh"

interface dmem_driver_bfm 
  (dmem_if bus);

  // Config value to determine if this is an initiator or a responder 
  uvmf_initiator_responder_t initiator_responder;

  tri clock_i;
  tri reset_i;

  // Signal list
  // INITIATOR mode input signals (Sampled from DUT in RESPONDER mode)
  tri [15:0] Data_addr_i;
  reg [15:0] Data_addr_o = 'b0;
  tri [15:0] Data_din_i;
  reg [15:0] Data_din_o = 'b0;
  tri        Data_rd_i;
  reg        Data_rd_o = 'b0;
  tri        D_macc_i;
  reg        D_macc_o = 'b0;

  // INITIATOR mode output signals (Driven to DUT in RESPONDER mode)
  tri [15:0] Data_dout_i;
  reg [15:0] Data_dout_o = 'b0;
  tri        complete_data_i;
  reg        complete_data_o = 'b0;

  assign clock_i = bus.clock;
  assign reset_i = bus.reset;

  // -------------------------------------------------------------------
  // FIXED SIGNAL DIRECTION ASSIGNMENTS FOR RESPONDER MODE
  // -------------------------------------------------------------------
  // 1. Sample signals driven BY THE DUT during loads/stores
  assign Data_addr_i = bus.Data_addr;
  assign Data_din_i  = bus.Data_din;
  assign Data_rd_i   = bus.Data_rd;
  assign D_macc_i    = bus.D_macc;

  // Drive request pins ONLY if BFM is configured in INITIATOR mode
  assign bus.Data_addr = (initiator_responder == INITIATOR) ? Data_addr_o : 'bz;
  assign bus.Data_din  = (initiator_responder == INITIATOR) ? Data_din_o  : 'bz;
  assign bus.Data_rd   = (initiator_responder == INITIATOR) ? Data_rd_o   : 'bz;
  assign bus.D_macc    = (initiator_responder == INITIATOR) ? D_macc_o    : 'bz;

  // 2. Drive response pins TO THE DUT when BFM is configured in RESPONDER mode
  assign bus.Data_dout     = (initiator_responder == RESPONDER) ? Data_dout_o     : 'bz;
  assign bus.complete_data = (initiator_responder == RESPONDER) ? complete_data_o : 'bz;

  assign Data_dout_i     = bus.Data_dout;
  assign complete_data_i = bus.complete_data;

  // Proxy handle to UVM driver
  dmem_pkg::dmem_driver proxy;

  // Struct definitions
  `dmem_CONFIGURATION_STRUCT
  `dmem_INITIATOR_STRUCT
    dmem_initiator_s initiator_struct;
  `dmem_RESPONDER_STRUCT
    dmem_responder_s responder_struct;

  // -------------------------------------------------------------------
  // Reset Condition Response
  // -------------------------------------------------------------------
  bit first_transfer = 1;

  function bit request_is_valid();
    return (Data_addr_i !== 16'h0000 &&
            Data_addr_i !== 16'hzzzz &&
            !$isunknown(Data_addr_i) &&
            (Data_rd_i === 1'b0 || Data_rd_i === 1'b1));
  endfunction

  always @(negedge reset_i) begin
    Data_addr_o     <= 'b0;
    Data_din_o      <= 'b0;
    Data_rd_o       <= 'b0;
    D_macc_o        <= 'b0;
    Data_dout_o     <= 'b0;
    complete_data_o <= 'b0;
    first_transfer  <= 1'b1;
  end

  // Configuration task
  function void configure(dmem_configuration_s dmem_configuration_arg);
    initiator_responder = dmem_configuration_arg.initiator_responder;
  endfunction

  // -------------------------------------------------------------------
  // INITIATOR Task (Unused in Responder mode)
  // -------------------------------------------------------------------
  task initiate_and_get_response( 
    input  dmem_initiator_s dmem_initiator_struct, 
    output dmem_responder_s dmem_responder_struct 
  );
    wait (reset_i === 1'b0);
    @(posedge clock_i);
    responder_struct = dmem_responder_struct;
  endtask        
// pragma uvmf custom initiate_and_get_response end

// pragma uvmf custom respond_and_wait_for_next_transfer begin
// ****************************************************************************
// The first_transfer variable is used to prevent completing a transfer in the 
// first call to this task.  For the first call to this task, there is not
// current transfer to complete.

// UVMF_CHANGE_ME
// This task is used by a responder.  The task first completes the current 
// transfer in progress then waits for the initiator to start the next transfer.
  task respond_and_wait_for_next_transfer(
       // This argument is used to send data received from the initiator
       // back to the sequence item.  The sequence determines how to respond.
       output dmem_initiator_s dmem_initiator_struct,
       // This argument passes transaction variables used by a responder
       // to complete a protocol transfer.  The values come from a sequence item.
       input dmem_responder_s dmem_responder_struct
       );// pragma tbx xtf
  // Variables within the dmem_initiator_struct:
  //   bit [15:0] Data_addr ;
  //   bit [15:0] Data_din ;
  //   bit Data_rd ;
  //   bit D_macc ;
  //   bit [15:0] Data_dout ;
  //   bit complete_data ;
  // Variables within the dmem_responder_struct:
  //   bit [15:0] Data_addr ;
  //   bit [15:0] Data_din ;
  //   bit Data_rd ;
  //   bit D_macc ;
  //   bit [15:0] Data_dout ;
  //   bit complete_data ;
    if (!first_transfer) begin
      // drive out the response for the last request we got (the sequence
      // already computed this and put it in dmem_responder_struct), hold it
      // for one cycle then drop complete_data again
      Data_dout_o     <= dmem_responder_struct.Data_dout;
      complete_data_o <= dmem_responder_struct.complete_data;
      @(posedge clock_i);
      complete_data_o <= 1'b0;
    end
    // now wait for the DUT to actually make a new request and grab it
    while (D_macc_i !== 1'b1) @(posedge clock_i);
    dmem_initiator_struct.Data_addr = Data_addr_i;
    dmem_initiator_struct.Data_din  = Data_din_i;
    dmem_initiator_struct.Data_rd   = Data_rd_i;
    dmem_initiator_struct.D_macc    = D_macc_i;
    first_transfer = 0;
  endtask

endinterface