//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: This interface contains the writeback_in interface signals.
//      It is instantiated once per writeback_in bus.  Bus Functional Models, 
//      BFM's named writeback_in_driver_bfm, are used to drive signals on the bus.
//      BFM's named writeback_in_monitor_bfm are used to monitor signals on the 
//      bus. This interface signal bundle is passed in the port list of
//      the BFM in order to give the BFM access to the signals in this
//      interface.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
// This template can be used to connect a DUT to these signals
//
// .dut_signal_port(writeback_in_bus.aluout), // Agent inout 
// .dut_signal_port(writeback_in_bus.memout), // Agent inout 
// .dut_signal_port(writeback_in_bus.pcout), // Agent inout 
// .dut_signal_port(writeback_in_bus.w_control), // Agent inout 
// .dut_signal_port(writeback_in_bus.dr), // Agent inout 
// .dut_signal_port(writeback_in_bus.sr1), // Agent inout 
// .dut_signal_port(writeback_in_bus.sr2), // Agent inout 
// .dut_signal_port(writeback_in_bus.enable_writeback), // Agent inout 

import uvmf_base_pkg_hdl::*;
import writeback_in_pkg_hdl::*;

interface  writeback_in_if 

  (
  input tri clock, 
  input tri reset,
  inout tri [15:0] aluout,
  inout tri [15:0] memout,
  inout tri [15:0] pcout,
  inout tri [1:0] w_control,
  inout tri [2:0] dr,
  inout tri [2:0] sr1,
  inout tri [2:0] sr2,
  inout tri  enable_writeback
  );

modport monitor_port 
  (
  input clock,
  input reset,
  input aluout,
  input memout,
  input pcout,
  input w_control,
  input dr,
  input sr1,
  input sr2,
  input enable_writeback
  );

modport initiator_port 
  (
  input clock,
  input reset,
  inout aluout,
  inout memout,
  inout pcout,
  inout w_control,
  inout dr,
  inout sr1,
  inout sr2,
  inout enable_writeback
  );

modport responder_port 
  (
  input clock,
  input reset,  
  inout aluout,
  inout memout,
  inout pcout,
  inout w_control,
  inout dr,
  inout sr1,
  inout sr2,
  inout enable_writeback
  );
  

// pragma uvmf custom interface_item_additional begin
// pragma uvmf custom interface_item_additional end

endinterface

// pragma uvmf custom external begin
// pragma uvmf custom external end

