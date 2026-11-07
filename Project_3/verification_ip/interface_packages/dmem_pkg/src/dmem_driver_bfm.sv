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
  endtask

  // -------------------------------------------------------------------
  // RESPONDER Task: Responds to DUT memory requests and captures next access
  // -------------------------------------------------------------------
  task respond_and_wait_for_next_transfer( 
    output dmem_initiator_s dmem_initiator_struct, 
    input  dmem_responder_s dmem_responder_struct 
  );
    wait (reset_i === 1'b0);

    // Step A: Complete current transfer if not the first call
    if (!first_transfer) begin
      // Drive response payload and handshake signal onto DUT input pins
      Data_dout_o     <= dmem_responder_struct.Data_dout;
      complete_data_o <= dmem_responder_struct.complete_data;

      @(posedge clock_i);

      // De-assert completion signal after 1 clock cycle handshake
      complete_data_o <= 1'b0;
      Data_dout_o     <= 16'h0000;
    end

    // Step B: Wait for DUT to issue the next Data Memory request
    // MemAccess block activates Data_rd_i (0 for Write, 1 for Read)
    while (Data_rd_i === 1'bz || $isunknown(Data_rd_i)) begin
      @(posedge clock_i);
    end

    // Step C: Sample request variables driven by DUT
    dmem_initiator_struct.Data_addr     = Data_addr_i;
    dmem_initiator_struct.Data_din      = Data_din_i;
    dmem_initiator_struct.Data_rd       = Data_rd_i;
    dmem_initiator_struct.D_macc        = D_macc_i;
    dmem_initiator_struct.Data_dout     = Data_dout_i;
    dmem_initiator_struct.complete_data = complete_data_i;

    first_transfer = 0;
  endtask

endinterface