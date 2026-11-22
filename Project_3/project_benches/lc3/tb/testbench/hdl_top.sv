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
   tri [1:0] w_control_wb;
   tri [15:0] npc_wb;
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
      .npc(npc_wb),
      .w_control(w_control_wb),
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
  imem_driver_bfm  imem_agent_drv_bfm(imem_agent_bus);
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

  //tie off unused memory qualifier inputs so monitor values are known
  assign I_macc = 1'b0;
  assign D_macc = (mem_state !== 2'b11); //testbench-only memory access valid qualifier
  // pragma uvmf custom dut_observation_wiring begin
  // common memory and decode signals
  assign dout           = imem_agent_bus.Instr_dout;
  assign npc_in         = dut.npc_out_fetch;
  assign w_control      = dut.W_Control;
  assign mem_control    = dut.Mem_Control;
  assign e_control      = dut.E_Control;
  assign ir             = dut.IR;
  assign npc_out        = dut.npc_out_dec;

  // controller inputs and outputs
  assign IR             = dut.IR;
  assign IR_Exec        = dut.IR_Exec;
  assign IMem_dout      = imem_agent_bus.Instr_dout;
  assign NZP            = dut.NZP;
  assign enable_updatePC  = dut.enable_updatePC;
  assign enable_fetch     = dut.enable_fetch;
  assign enable_decode    = dut.enable_decode;
  assign enable_execute   = dut.enable_execute;
  assign enable_writeback = dut.enable_writeback;
  assign br_taken         = dut.br_taken;
  assign bypass_alu_1     = dut.bypass_alu_1;
  assign bypass_alu_2     = dut.bypass_alu_2;
  assign bypass_mem_1     = dut.bypass_mem_1;
  assign bypass_mem_2     = dut.bypass_mem_2;
  assign mem_state        = dut.mem_state;

  // writeback inputs and outputs
  assign aluout       = dut.aluout;
  assign memout       = dut.memout;
  assign pcout        = dut.pcout;
  assign npc_wb       = dut.npc_out_dec;
  assign w_control_wb = dut.W_Control_out;
  assign dr           = dut.dr;
  assign sr1          = dut.sr1;
  assign sr2          = dut.sr2;
  assign vsr1         = dut.VSR1;
  assign vsr2         = dut.VSR2;
  assign psr          = dut.psr;
  //memory access input signals from the execute stage and data memory response
  assign M_Control = dut.Mem_Control_out;
  assign M_Data = dut.M_Data;
  assign M_addr = dut.pcout;
  assign DMem_dout = dmem_agent_bus.Data_dout;

  //memory access output signals observed on the dut data-memory ports
  assign DMem_addr = dmem_agent_bus.Data_addr;
  assign DMem_rd = dmem_agent_bus.Data_rd;
  assign DMem_din = dmem_agent_bus.Data_din;
  // pragma uvmf custom dut_observation_wiring end

  //temporary fetch diagnostic; remove after the handshake is confirmed
  integer imem_diag_count = 0;
  always @(negedge clk) begin
    if (rst === 1'b0 && imem_diag_count < 24) begin
      $display("IMEM_DIAG t=%0t pc=%04h rd=%b bus_done=%b dut_done=%b bfm_done=%b bus_data=%04h bfm_data=%04h fetch=%b update_pc=%b decode=%b",
        $time,
        imem_agent_bus.PC,
        imem_agent_bus.instrmem_rd,
        imem_agent_bus.complete_instr,
        dut.complete_instr,
        imem_agent_drv_bfm.complete_instr_o,
        imem_agent_bus.Instr_dout,
        imem_agent_drv_bfm.Instr_dout_o,
        dut.enable_fetch,
        dut.enable_updatePC,
        dut.enable_decode
      );
      imem_diag_count = imem_diag_count + 1;
    end
  end


  //temporary trace: sample dut control signals each falling clock edge
  integer control_rtl_trace_count = 0;
  always @(negedge clk) begin
    if (rst === 1'b0 && control_rtl_trace_count < 36) begin
      $display("CTRL_RTL_DIAG t=%0t n=%0d ci=%b cd=%b ir=%04h ie=%04h id=%04h psr=%01h nzp=%01h pc=%b f=%b d=%b e=%b w=%b br=%b ba1=%b ba2=%b bm1=%b bm2=%b ms=%01h",
        $time, control_rtl_trace_count,
        complete_instr, complete_data, IR, IR_Exec, IMem_dout, psr, NZP,
        enable_updatePC, enable_fetch, enable_decode, enable_execute,
        enable_writeback, br_taken, bypass_alu_1, bypass_alu_2,
        bypass_mem_1, bypass_mem_2, mem_state);
      control_rtl_trace_count = control_rtl_trace_count + 1;
    end
  end

  //temporary controller-pipeline diagnostic; remove after model alignment review
  integer control_pipeline_trace_count = 0;
  always @(negedge clk) begin
    if (rst === 1'b0 && control_pipeline_trace_count < 36) begin
      $display("CTRL_PIPE_DIAG t=%0t n=%0d ci=%b pc=%04h ir=%04h ie=%04h ctrl_en=%05b ctrl_prev=%05b ctrl_state=%05b ctrl_next=%05b ctrl_stall=%b ctrl_bubbles=%03b ctrl_mem_current=%02b ctrl_mem_next=%02b d=%b e=%b w=%b",
        $time, control_pipeline_trace_count,
        complete_instr, imem_agent_bus.PC, IR, IR_Exec,
        dut.Ctrl.enables,
        dut.Ctrl.prev_enables,
        dut.Ctrl.state,
        dut.Ctrl.next_state,
        dut.Ctrl.stall_pipe,
        dut.Ctrl.bubble_count,
        dut.Ctrl.mem_ctrl_Cstate,
        dut.Ctrl.mem_ctrl_Nstate,
        enable_decode, enable_execute, enable_writeback);
      control_pipeline_trace_count = control_pipeline_trace_count + 1;
    end
  end

  //temporary data-memory handshake trace; remove after stage8d diagnosis
  always @(negedge clk) begin
    if (rst === 1'b0 && $time >= 330ns && $time <= 610ns) begin
      #1ns;
      $display("DMEM_DIAG t=%0t pc=%04h ifetch=%b ci=%b ms=%02b macc=%b addr=%04h din=%04h rd=%b bfm_done=%b bus_done=%b dut_done=%b bfm_dout=%04h bus_dout=%04h stall=%b ctrl_en=%05b d=%b e=%b w=%b",
        $time,
        imem_agent_bus.PC,
        imem_agent_bus.instrmem_rd,
        imem_agent_bus.complete_instr,
        mem_state,
        dmem_agent_bus.D_macc,
        dmem_agent_bus.Data_addr,
        dmem_agent_bus.Data_din,
        dmem_agent_bus.Data_rd,
        dmem_agent_drv_bfm.complete_data_o,
        dmem_agent_bus.complete_data,
        dut.complete_data,
        dmem_agent_drv_bfm.Data_dout_o,
        dmem_agent_bus.Data_dout,
        dut.Ctrl.stall_pipe,
        dut.Ctrl.enables,
        enable_decode,
        enable_execute,
        enable_writeback);
    end
  end

  //diagnostic-only: observe the active writeback operands and outputs
  integer wb_dut_diag_count = 0;
  always @(negedge clk) begin
    if (rst === 1'b0 && wb_dut_diag_count < 100) begin
      $display("WB_DUT_DIAG t=%0t n=%0d wr=%b wc=%0d dr=%0d sr1=%0d sr2=%0d alu=%04h mem=%04h pc=%04h npc=%04h dut_dr_in=%04h vsr1=%04h vsr2=%04h psr=%0h cd=%b ms=%02b data_addr=%04h data_rd=%b data_dout=%04h",
        $time, wb_dut_diag_count, enable_writeback, w_control_wb,
        dr, sr1, sr2, aluout, memout, pcout, npc_wb,
        dut.WB.DR_in, vsr1, vsr2, psr, complete_data, mem_state,
        Data_addr, Data_rd, Data_dout);
      wb_dut_diag_count = wb_dut_diag_count + 1;
    end
  end

  //indirect diagnostics are opt-in with +TRACE_INDIRECT.
  //these monitors do not drive the dut or its interfaces.
  integer indirect_trace_count = 0;
  always @(negedge clk) begin
    if ($test$plusargs("TRACE_INDIRECT") && rst === 1'b0 &&
        indirect_trace_count < 100 && $time >= 330ns && $time <= 1900ns) begin
      #1ns;
      $display("INDIRECT_DIAG t=%0t n=%0d pc=%04h ifetch=%b ci=%b ir=%04h ire=%04h ms=%02b macc=%b addr=%04h rd=%b din=%04h dout=%04h bdone=%b ddone=%b stall=%b en=%05b ctrl_c=%05b ctrl_n=%05b mem_c=%02b mem_n=%02b",
        $time, indirect_trace_count, imem_agent_bus.PC,
        imem_agent_bus.instrmem_rd, imem_agent_bus.complete_instr,
        IR, IR_Exec, mem_state, dmem_agent_bus.D_macc,
        dmem_agent_bus.Data_addr, dmem_agent_bus.Data_rd,
        dmem_agent_bus.Data_din, dmem_agent_bus.Data_dout,
        dmem_agent_drv_bfm.complete_data_o, dut.complete_data,
        dut.Ctrl.stall_pipe, dut.Ctrl.enables,
        dut.Ctrl.state, dut.Ctrl.next_state,
        dut.Ctrl.mem_ctrl_Cstate, dut.Ctrl.mem_ctrl_Nstate);
      indirect_trace_count = indirect_trace_count + 1;
    end
  end

  //sample each acknowledgement at its leading edge. Unlike the generated
  //dmem monitor, this diagnostic does not require macc to remain asserted.
  integer raw_ack_count = 0;
  always @(posedge dmem_agent_bus.complete_data) begin
    if ($test$plusargs("TRACE_INDIRECT") && rst === 1'b0 && raw_ack_count < 80) begin
      $display("DMEM_RAW_ACK t=%0t n=%0d pc=%04h addr=%04h rd=%b din=%04h dout=%04h ms=%02b",
        $time, raw_ack_count, imem_agent_bus.PC,
        dmem_agent_bus.Data_addr, dmem_agent_bus.Data_rd,
        dmem_agent_bus.Data_din, dmem_agent_bus.Data_dout, mem_state);
      raw_ack_count = raw_ack_count + 1;
    end
  end

  //a repeated completed fetch at the same pc is suspicious for a sequential
  //indirect smoke program; report the symptom without terminating simulation.
  logic [15:0] indirect_prev_pc = 16'hffff;
  integer indirect_same_pc = 0;
  always @(posedge imem_agent_bus.complete_instr) begin
    if ($test$plusargs("TRACE_INDIRECT") && rst === 1'b0) begin
      if (imem_agent_bus.PC === indirect_prev_pc)
        indirect_same_pc = indirect_same_pc + 1;
      else
        indirect_same_pc = 1;
      indirect_prev_pc = imem_agent_bus.PC;
      if (indirect_same_pc == 4)
        $display("INDIRECT_REPEAT_PC t=%0t pc=%04h repeated_fetches=%0d",
          $time, imem_agent_bus.PC, indirect_same_pc);
    end
  end

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

