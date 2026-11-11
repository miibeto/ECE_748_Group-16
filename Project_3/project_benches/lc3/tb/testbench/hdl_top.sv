//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------                     
//               
// Description: This top level module instantiates all synthesizable
//    static content.  This and tb_top.sv are the two top level modules
//    of the simulation.  
//
//    This module instantiates the following:
//        DUT: The Design Under Test
//        Interfaces:  Signal bundles that contain signals connected to DUT
//        Driver BFM's: BFM's that actively drive interface signals
//        Monitor BFM's: BFM's that passively monitor interface signals
//
//----------------------------------------------------------------------

//----------------------------------------------------------------------
//

module hdl_top;

import lc3_parameters_pkg::*;
import uvmf_base_pkg_hdl::*;

  // pragma attribute hdl_top partition_module_xrtl                                            
// pragma uvmf custom clock_generator begin
  bit clk;
  // Instantiate a clk driver 
  // tbx clkgen
  initial begin
    clk = 0;
    #0ns;
    forever begin
      #5ns;
      clk = ~clk;
    end
  end
// pragma uvmf custom clock_generator end

// pragma uvmf custom reset_generator begin
  bit rst;
  // Instantiate a rst driver
  // tbx clkgen
  initial begin
    rst = 1; 
    #200ns;
    rst =  0; 
  end
// pragma uvmf custom reset_generator end

  // pragma uvmf custom module_item_additional begin
   // Testbench signals
   // Decode Stage
   tri enable_decode;
   tri [15:0] dout;
   tri [15:0] npc_in;
   tri [1:0] w_control;
   tri mem_control;
   tri [5:0] e_control;
   tri [15:0] ir;
   tri [15:0] npc_out;
   // Writeback Stage
   tri enable_writeback;
   tri [15:0] aluout;
   tri [15:0] memout;
   tri [15:0] pcout;
   tri [2:0] dr;
   tri [2:0] sr1;
   tri [2:0] sr2;
   tri [15:0] vsr1;
   tri [15:0] vsr2;
   tri [2:0] psr;
   // Memaccess Stage
   tri enable_memaccess;
   tri [1:0] mem_state;
   tri M_Control;
   tri [15:0] M_Data;
   tri [15:0] M_addr;
   tri [15:0] DMem_dout;
   tri [15:0] DMem_addr;
   tri DMem_rd;
   tri [15:0] DMem_din;
   // Control Stage
   tri complete_data;
   tri complete_instr;
   tri [15:0] IR;
   tri [15:0] IR_Exec;
   tri [15:0] IMem_dout;
   tri [2:0] NZP;
   tri br_taken;
   tri bypass_alu_1;
   tri bypass_alu_2;
   tri bypass_mem_1;
   tri bypass_mem_2;
   tri enable_updatePC;
   // Instruction Memory 
   tri [15:0] PC;
   tri instrmem_rd;
   tri I_macc;
   tri [15:0] Instr_dout;
   // Data Memory
   tri [15:0] Data_addr;
   tri [15:0] Data_din;
   tri Data_rd;
   tri D_macc;
   tri [15:0] Data_dout;
   // Unused Signals
   tri enable_fetch;
   tri enable_execute;

   // ------------------------------------------------------------------
   // DUT Internal Hierarchical Signal Taps
   // Used for waveform debugging
   // ------------------------------------------------------------------
   // Decode Sub-block Tap[cite: 12]
   // assign enable_decode    = dut.Ctrl.enable_decode;
   // assign dout             = Instr_dout;
   // assign npc_in           = dut.Fetch.npc_out;
   // assign w_control        = dut.Dec.W_Control;
   // assign mem_control      = dut.Dec.Mem_Control;
   // assign e_control        = dut.Dec.E_Control;
   // assign ir               = dut.Dec.IR;
   // assign npc_out          = dut.Dec.npc_out;

   // // Writeback Sub-block Tap[cite: 21]
   // assign enable_writeback = dut.Ctrl.enable_writeback;
   // assign aluout           = dut.Ex.aluout;
   // assign memout           = dut.MemAccess.memout;
   // assign pcout            = dut.Ex.pcout;
   // assign dr               = dut.Ex.dr;
   // assign sr1              = dut.Ex.sr1;
   // assign sr2              = dut.Ex.sr2;
   // assign vsr1             = dut.WB.d1;
   // assign vsr2             = dut.WB.d2;
   // assign psr              = dut.WB.psr;

   // // MemAccess Sub-block Tap[cite: 23, 25]
   //assign mem_state        = dut.Ctrl.mem_state;
   // assign M_Control        = dut.Ex.Mem_Control_out;
   // assign M_Data           = dut.Ex.M_Data;
   // assign M_addr           = dut.Ex.pcout;
   // assign DMem_dout        = Data_dout;
   // assign DMem_addr        = Data_addr;
   // assign DMem_rd          = Data_rd;
   // assign DMem_din         = Data_din;
   assign D_macc           = (dut.Ctrl.mem_state != 2'b11); // mem_state = 0, 1, 2 (Memory is being accessed)
   assign I_macc           = (dut.Ctrl.enable_fetch); // Mimic what enable_fetch is showing

   // // Control Sub-block Tap[cite: 25]
   // assign IR               = dut.Dec.IR;
   // assign IR_Exec          = dut.Ex.IR_Exec;
   // assign IMem_dout        = Instr_dout;
   // assign NZP              = dut.Ex.NZP;
   // assign br_taken         = dut.Ctrl.br_taken;
   // assign bypass_alu_1     = dut.Ctrl.bypass_alu_1;
   // assign bypass_alu_2     = dut.Ctrl.bypass_alu_2;
   // assign bypass_mem_1     = dut.Ctrl.bypass_mem_1;
   // assign bypass_mem_2     = dut.Ctrl.bypass_mem_2;
   // assign enable_updatePC  = dut.Ctrl.enable_updatePC;
   // assign enable_fetch     = dut.Ctrl.enable_fetch;
   // assign enable_execute   = dut.Ctrl.enable_execute;

  // pragma uvmf custom module_item_additional end

  // Instantiate the signal bundle, monitor bfm and driver bfm for each interface.
  // The signal bundle, _if, contains signals to be connected to the DUT.
  // The monitor, monitor_bfm, observes the bus, _if, and captures transactions.
  // The driver, driver_bfm, drives transactions onto the bus, _if.
  decode_in_if  decode_env_decode_in_agent_bus(
     // pragma uvmf custom decode_env_decode_in_agent_bus_connections begin
      .clock(clk),
      .reset(rst),
      .enable_decode(enable_decode),
      .dout(dout),
      .npc_in(npc_in)
     // pragma uvmf custom decode_env_decode_in_agent_bus_connections end
     );
  decode_out_if  decode_env_decode_out_agent_bus(
     // pragma uvmf custom decode_env_decode_out_agent_bus_connections begin
      .clock(clk),
      .reset(rst),
      .enable_decode(enable_decode),
      .w_control(w_control),
      .mem_control(mem_control),
      .e_control(e_control),
      .ir(ir),
      .npc_out(npc_out)
     // pragma uvmf custom decode_env_decode_out_agent_bus_connections end
     );
  writeback_in_if  writeback_env_writeback_in_agent_bus(
     // pragma uvmf custom writeback_env_writeback_in_agent_bus_connections begin
      .clock(clk),
      .reset(rst),
      .enable_writeback(enable_writeback),
      .aluout(aluout),
      .memout(memout),
      .pcout(pcout),
      .w_control(w_control),
      .dr(dr),
      .sr1(sr1),
      .sr2(sr2)
     // pragma uvmf custom writeback_env_writeback_in_agent_bus_connections end
     );
  writeback_out_if  writeback_env_writeback_out_agent_bus(
     // pragma uvmf custom writeback_env_writeback_out_agent_bus_connections begin
      .clock(clk),
      .reset(rst),
      .vsr1(vsr1),
      .vsr2(vsr2),
      .psr(psr)
     // pragma uvmf custom writeback_env_writeback_out_agent_bus_connections end
     );
  memaccess_in_if  memaccess_env_memaccess_in_agent_bus(
     // pragma uvmf custom memaccess_env_memaccess_in_agent_bus_connections begin
      .clock(clk),
      .reset(rst),
      .mem_state(mem_state),
      .M_Control(M_Control),
      .M_Data(M_Data),
      .M_addr(M_addr),
      .DMem_dout(DMem_dout)
     // pragma uvmf custom memaccess_env_memaccess_in_agent_bus_connections end
     );
  memaccess_out_if  memaccess_env_memaccess_out_agent_bus(
     // pragma uvmf custom memaccess_env_memaccess_out_agent_bus_connections begin
      .clock(clk),
      .reset(rst),
      .DMem_addr(DMem_addr),
      .DMem_rd(DMem_rd),
      .DMem_din(DMem_din),
      .memout(memout)
     // pragma uvmf custom memaccess_env_memaccess_out_agent_bus_connections end
     );
  control_in_if  control_env_control_in_agent_bus(
     // pragma uvmf custom control_env_control_in_agent_bus_connections begin
      .clock(clk),
      .reset(rst),
      .complete_data(complete_data),
      .complete_instr(complete_instr),
      .IR(IR),
      .psr(psr),
      .IR_Exec(IR_Exec),
      .IMem_dout(IMem_dout),
      .NZP(NZP)
     // pragma uvmf custom control_env_control_in_agent_bus_connections end
     );
  control_out_if  control_env_control_out_agent_bus(
     // pragma uvmf custom control_env_control_out_agent_bus_connections begin
      .clock(clk),
      .reset(rst),
      .enable_updatePC(enable_updatePC),
      .enable_fetch(enable_fetch),
      .enable_decode(enable_decode),
      .enable_execute(enable_execute),
      .enable_writeback(enable_writeback),
      .br_taken(br_taken),
      .bypass_alu_1(bypass_alu_1),
      .bypass_alu_2(bypass_alu_2),
      .bypass_mem_1(bypass_mem_1),
      .bypass_mem_2(bypass_mem_2),
      .mem_state(mem_state)
     // pragma uvmf custom control_env_control_out_agent_bus_connections end
     );
  imem_if  imem_agent_bus(
     // pragma uvmf custom imem_agent_bus_connections begin
      .clock(clk),
      .reset(rst),
      .PC(PC),
      .instrmem_rd(instrmem_rd),
      .I_macc(I_macc),
      .Instr_dout(Instr_dout),
      .complete_instr(complete_instr)
     // pragma uvmf custom imem_agent_bus_connections end
     );
  dmem_if  dmem_agent_bus(
     // pragma uvmf custom dmem_agent_bus_connections begin
      .clock(clk),
      .reset(rst),
      .Data_addr(Data_addr),
      .Data_din(Data_din),
      .Data_rd(Data_rd),
      .D_macc(D_macc),
      .Data_dout(Data_dout),
      .complete_data(complete_data)
     // pragma uvmf custom dmem_agent_bus_connections end
     );
 
  decode_in_monitor_bfm  decode_env_decode_in_agent_mon_bfm(decode_env_decode_in_agent_bus);
  decode_out_monitor_bfm  decode_env_decode_out_agent_mon_bfm(decode_env_decode_out_agent_bus);
  writeback_in_monitor_bfm  writeback_env_writeback_in_agent_mon_bfm(writeback_env_writeback_in_agent_bus);
  writeback_out_monitor_bfm  writeback_env_writeback_out_agent_mon_bfm(writeback_env_writeback_out_agent_bus);
  memaccess_in_monitor_bfm  memaccess_env_memaccess_in_agent_mon_bfm(memaccess_env_memaccess_in_agent_bus);
  memaccess_out_monitor_bfm  memaccess_env_memaccess_out_agent_mon_bfm(memaccess_env_memaccess_out_agent_bus);
  control_in_monitor_bfm  control_env_control_in_agent_mon_bfm(control_env_control_in_agent_bus);
  control_out_monitor_bfm  control_env_control_out_agent_mon_bfm(control_env_control_out_agent_bus);
  imem_monitor_bfm  imem_agent_mon_bfm(imem_agent_bus);
  dmem_monitor_bfm  dmem_agent_mon_bfm(dmem_agent_bus);
  imem_driver_bfm  imem_agent_drv_bfm(
      .bus          (imem_agent_bus),
      .enable_decode(enable_decode)
  );
  dmem_driver_bfm  dmem_agent_drv_bfm(dmem_agent_bus);

  // pragma uvmf custom dut_instantiation begin
  // UVMF_CHANGE_ME : Add DUT and connect to signals in _bus interfaces listed above
  // Instantiate your DUT here
  // These DUT's instantiated to show verilog and vhdl instantiation
  LC3 dut (
      .clock          (clk),
      .reset          (rst),
      .pc             (imem_agent_bus.PC),
      .instrmem_rd    (imem_agent_bus.instrmem_rd),
      .Instr_dout     (imem_agent_bus.Instr_dout),
      .complete_instr (imem_agent_bus.complete_instr),
      .complete_data  (dmem_agent_bus.complete_data),
      .Data_addr      (dmem_agent_bus.Data_addr),
      .Data_din       (dmem_agent_bus.Data_din),
      .Data_dout      (dmem_agent_bus.Data_dout),
      .Data_rd        (dmem_agent_bus.Data_rd)
   );
   // pragma uvmf custom dut_instantiation end

  initial begin      // tbx vif_binding_block 
    import uvm_pkg::uvm_config_db;
    // The monitor_bfm and driver_bfm for each interface is placed into the uvm_config_db.
    // They are placed into the uvm_config_db using the string names defined in the parameters package.
    // The string names are passed to the agent configurations by test_top through the top level configuration.
    // They are retrieved by the agents configuration class for use by the agent.
    uvm_config_db #( virtual decode_in_monitor_bfm  )::set( null , UVMF_VIRTUAL_INTERFACES , decode_env_decode_in_agent_BFM , decode_env_decode_in_agent_mon_bfm ); 
    uvm_config_db #( virtual decode_out_monitor_bfm  )::set( null , UVMF_VIRTUAL_INTERFACES , decode_env_decode_out_agent_BFM , decode_env_decode_out_agent_mon_bfm ); 
    uvm_config_db #( virtual writeback_in_monitor_bfm  )::set( null , UVMF_VIRTUAL_INTERFACES , writeback_env_writeback_in_agent_BFM , writeback_env_writeback_in_agent_mon_bfm ); 
    uvm_config_db #( virtual writeback_out_monitor_bfm  )::set( null , UVMF_VIRTUAL_INTERFACES , writeback_env_writeback_out_agent_BFM , writeback_env_writeback_out_agent_mon_bfm ); 
    uvm_config_db #( virtual memaccess_in_monitor_bfm  )::set( null , UVMF_VIRTUAL_INTERFACES , memaccess_env_memaccess_in_agent_BFM , memaccess_env_memaccess_in_agent_mon_bfm ); 
    uvm_config_db #( virtual memaccess_out_monitor_bfm  )::set( null , UVMF_VIRTUAL_INTERFACES , memaccess_env_memaccess_out_agent_BFM , memaccess_env_memaccess_out_agent_mon_bfm ); 
    uvm_config_db #( virtual control_in_monitor_bfm  )::set( null , UVMF_VIRTUAL_INTERFACES , control_env_control_in_agent_BFM , control_env_control_in_agent_mon_bfm ); 
    uvm_config_db #( virtual control_out_monitor_bfm  )::set( null , UVMF_VIRTUAL_INTERFACES , control_env_control_out_agent_BFM , control_env_control_out_agent_mon_bfm ); 
    uvm_config_db #( virtual imem_monitor_bfm  )::set( null , UVMF_VIRTUAL_INTERFACES , imem_agent_BFM , imem_agent_mon_bfm ); 
    uvm_config_db #( virtual dmem_monitor_bfm  )::set( null , UVMF_VIRTUAL_INTERFACES , dmem_agent_BFM , dmem_agent_mon_bfm ); 
    uvm_config_db #( virtual imem_driver_bfm  )::set( null , UVMF_VIRTUAL_INTERFACES , imem_agent_BFM , imem_agent_drv_bfm  );
    uvm_config_db #( virtual dmem_driver_bfm  )::set( null , UVMF_VIRTUAL_INTERFACES , dmem_agent_BFM , dmem_agent_drv_bfm  );
  end

endmodule

// pragma uvmf custom external begin
// pragma uvmf custom external end
