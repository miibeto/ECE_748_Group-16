//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
// File: imem_driver_bfm.sv
// Description: BFM driving and sampling Instruction Memory interface signals 
//              for LC-3 in RESPONDER mode.
//----------------------------------------------------------------------

import uvmf_base_pkg_hdl::*;
import imem_pkg_hdl::*;
`include "src/imem_macros.svh"

interface imem_driver_bfm 
  (
    imem_if bus,
    input tri enable_decode
  );

  // Config value to determine if this is an initiator or a responder 
  uvmf_initiator_responder_t initiator_responder;

  tri clock_i;
  tri reset_i;
  tri enable_decode_i;

  assign enable_decode_i = enable_decode;

  // Signal list
  // INITIATOR mode input signals (Sampled from DUT in RESPONDER mode)
  tri [15:0] PC_i;
  reg [15:0] PC_o = 'b0;
  tri        instrmem_rd_i;
  reg        instrmem_rd_o = 'b0;
  tri        I_macc_i;
  reg        I_macc_o = 'b0;

  // INITIATOR mode output signals (Driven to DUT in RESPONDER mode)
  tri [15:0] Instr_dout_i;
  reg [15:0] Instr_dout_o = 'b0;
  tri        complete_instr_i;
  reg        complete_instr_o = 'b0;

  assign clock_i = bus.clock;
  assign reset_i = bus.reset;

  // -------------------------------------------------------------------
  // FIXED SIGNAL DIRECTION ASSIGNMENTS FOR RESPONDER MODE
  // -------------------------------------------------------------------
  // 1. Sample request signals driven BY THE DUT during instruction fetch
  assign PC_i          = bus.PC;
  assign instrmem_rd_i = bus.instrmem_rd;
  assign I_macc_i      = bus.I_macc;

  // Drive fetch request pins ONLY if BFM is configured in INITIATOR mode
  assign bus.PC          = (initiator_responder == INITIATOR) ? PC_o          : 'bz;
  assign bus.instrmem_rd = (initiator_responder == INITIATOR) ? instrmem_rd_o : 'bz;
  assign bus.I_macc      = (initiator_responder == INITIATOR) ? I_macc_o      : 'bz;

  // 2. Drive instruction response pins TO THE DUT when BFM is configured in RESPONDER mode
  assign bus.Instr_dout     = (initiator_responder == RESPONDER) ? Instr_dout_o     : 'bz;
  assign bus.complete_instr = (initiator_responder == RESPONDER) ? complete_instr_o : 'bz;

  assign Instr_dout_i     = bus.Instr_dout;
  assign complete_instr_i = bus.complete_instr;

  // Proxy handle to UVM driver
  imem_pkg::imem_driver proxy;

  // Struct definitions
  `imem_CONFIGURATION_STRUCT
  `imem_INITIATOR_STRUCT
    imem_initiator_s initiator_struct;
  `imem_RESPONDER_STRUCT
    imem_responder_s responder_struct;

  // -------------------------------------------------------------------
  // Reset Condition Response
  // -------------------------------------------------------------------
  bit first_transfer = 1;

  always @(negedge reset_i) begin
    PC_o             <= 'b0;
    instrmem_rd_o    <= 'b0;
    I_macc_o         <= 'b0;
    Instr_dout_o     <= 'b0;
    complete_instr_o <= 'b0;
    first_transfer   <= 1'b1;
  end

  // Configuration task
  function void configure(imem_configuration_s imem_configuration_arg);
    initiator_responder = imem_configuration_arg.initiator_responder;
  endfunction

  // -------------------------------------------------------------------
  // INITIATOR Task (Unused in Responder mode)
  // -------------------------------------------------------------------
  task initiate_and_get_response( 
    input  imem_initiator_s imem_initiator_struct, 
    output imem_responder_s imem_responder_struct 
  );
    wait (reset_i === 1'b0);
    @(posedge clock_i);
  endtask

  // -------------------------------------------------------------------
  // RESPONDER Task: Responds to DUT fetch requests and captures next PC
  // -------------------------------------------------------------------
  task respond_and_wait_for_next_transfer( 
    output imem_initiator_s imem_initiator_struct, 
    input  imem_responder_s imem_responder_struct 
  );
  // // Step A: Respond to previous request if not reset / first call
  //   if (!first_transfer) begin
  //     @(posedge clock_i);
  //     // If DUT is actively requesting a read, drive instruction & keep complete_instr HIGH
  //     if (reset_i === 1'b0 && instrmem_rd_i === 1'b1) begin
  //       Instr_dout_o     <= imem_responder_struct.Instr_dout;
  //       complete_instr_o <= 1'b1;
  //     end else begin
  //       // If instrmem_rd dropped (pipeline stalled downstream), drop complete_instr
  //       complete_instr_o <= 1'b0;
  //       // Instr_dout_o     <= 16'h0000;
  //     end
  //   end

  //   // Step B: Wait for reset to drop AND for instrmem_rd to be active (1'b1)
  //   while (reset_i === 1'b1 || instrmem_rd_i !== 1'b1) begin
  //     complete_instr_o <= 1'b0; // Memory idle while fetch is disabled
  //     // Instr_dout_o     <= 16'h0000;
  //     @(posedge clock_i);
  //   end


  //   // Step C: Sample requested PC address driven by DUT
  //   imem_initiator_struct.PC             = PC_i;
  //   imem_initiator_struct.instrmem_rd    = instrmem_rd_i;
  //   imem_initiator_struct.I_macc         = I_macc_i;
  //   imem_initiator_struct.Instr_dout     = Instr_dout_i;
  //   imem_initiator_struct.complete_instr = complete_instr_i;

  //   first_transfer = 0;
    // while (reset_i === 1'b1) @(posedge clock_i);
    @(posedge clock_i);
    // Step A: Complete current fetch transfer if not the first call
    if (!first_transfer) begin
      // Drive requested instruction word and complete_instr handshake to DUT
      Instr_dout_o     <= imem_responder_struct.Instr_dout;
      complete_instr_o <= imem_responder_struct.complete_instr;

      @(posedge clock_i);

      // Reset handshake pulse after 1 clock cycle
      complete_instr_o <= 1'b0;
      //Instr_dout_o     <= 16'h0000;

    end

    // Step B: Wait for DUT Fetch Unit to assert instrmem_rd = 1
    while (reset_i === 1'b1 || instrmem_rd_i !== 1'b1) begin
      @(posedge clock_i);
    end

    //#1

    // Step C: Sample PC address and control signals driven by DUT
    imem_initiator_struct.PC             = PC_i;
    imem_initiator_struct.instrmem_rd    = instrmem_rd_i;
    imem_initiator_struct.I_macc         = I_macc_i;
    imem_initiator_struct.Instr_dout     = Instr_dout_i;
    imem_initiator_struct.complete_instr = complete_instr_i;

    first_transfer = 0;
  endtask

endinterface