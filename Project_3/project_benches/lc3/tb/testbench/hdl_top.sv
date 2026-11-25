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

  //stage37 supports both flag and numeric plusarg forms
  //numeric values take precedence so an explicit =0 disables the mode
  integer stage37_ctrl32_mode;
  bit stage37_ctrl32_numeric_found;
  bit stage37_ctrl32_flag_found;
  initial begin : stage37_output_monitor_mode_bridge
    #2ns;
    stage37_ctrl32_mode = 0;
    stage37_ctrl32_numeric_found = $value$plusargs("CTRL32_EDGE_INSTR=%d", stage37_ctrl32_mode);
    stage37_ctrl32_flag_found = $test$plusargs("CTRL32_EDGE_INSTR");
    if (!stage37_ctrl32_numeric_found)
      stage37_ctrl32_mode = stage37_ctrl32_flag_found ? 1 : 0;
    control_env_control_out_agent_mon_bfm.stage35_preedge_mode = (stage37_ctrl32_mode == 1);
    $display("STAGE37_OUT_MODE flag=%0d numeric=%0d requested=%0d applied=%0d version=37.1",
      stage37_ctrl32_flag_found, stage37_ctrl32_numeric_found, stage37_ctrl32_mode,
      control_env_control_out_agent_mon_bfm.stage35_preedge_mode);
  end


  //independent executable build and argument probe
  initial begin : stage26_top_mode_probe
    #2ns;
    $display("STAGE26_TOP_COMPILED mode=%0d trace=%0d version=26.1",
             $test$plusargs("GUARD_IMEM_ACK"),
             $test$plusargs("TRACE_ACK_GUARD"));
  end

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
   wire imem_fetch_unstalled;
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
      .fetch_ready(imem_fetch_unstalled),
      .data_mem_rd(Data_rd),
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
  //diagnostic-only readiness; never drives an input of the lc3 dut
  //stage29 permits fetch acceptance outside active data-memory phases
  //this separates control-flow stalls from the memory stalls fixed in stage27
  wire stage29_active_mem_phase =
      (mem_state === 2'b01) || (mem_state === 2'b10);
  wire stage29_memory_only_ready_mode = $test$plusargs("MEMORY_ONLY_IMEM_READY");
  assign imem_fetch_unstalled = stage29_memory_only_ready_mode ?
      !stage29_active_mem_phase : (dut.Ctrl.stall_pipe === 1'b0);

  initial begin : stage29_ready_mode_marker
    #1ns;
    $display("STAGE29_READY_MODE mode=%0d accept=%0d version=29.1",
      $test$plusargs("MEMORY_ONLY_IMEM_READY"),
      $test$plusargs("ACCEPT_IMEM_ACK"));
  end

  integer stage29_jump_trace_count = 0;
  always @(negedge clk) begin : stage29_jump_readiness_trace
    if ($test$plusargs("TRACE_JUMP_READY") && rst === 1'b0 &&
        stage29_jump_trace_count < 70 &&
        (imem_agent_bus.PC >= 16'h3001) &&
        (imem_agent_bus.PC <= 16'h3009)) begin
      $display("STAGE29_JUMP t=%0t pc=%04h rd=%b ci=%b ack_pending=%b ready=%b stall=%b mem=%02b ir=%04h exec_ir=%04h fetch=%b decode=%b execute=%b updatepc=%b br=%b",
        $time, imem_agent_bus.PC, imem_agent_bus.instrmem_rd,
        imem_agent_bus.complete_instr, imem_agent_drv_bfm.complete_instr_o,
        imem_fetch_unstalled, dut.Ctrl.stall_pipe, mem_state,
        IR, IR_Exec, enable_fetch, enable_decode, enable_execute,
        enable_updatePC, br_taken);
      stage29_jump_trace_count++;
    end
  end
  //stage45: optional request qualifier derived from registered controller state.
  //the default is byte-for-byte the stage44 public-state qualifier.
  //modes 1/2 are protocol experiments, NOT request de-duplication.
  integer stage45_req_qualifier = 0;
  integer stage45_req_mode_arg = 0;
  bit stage45_req_mode_found = 0;
  wire stage45_current_active =
      (dut.Ctrl.mem_ctrl_Cstate === 2'b00) ||
      (dut.Ctrl.mem_ctrl_Cstate === 2'b01) ||
      (dut.Ctrl.mem_ctrl_Cstate === 2'b10);
  wire stage45_public_active = (mem_state !== 2'b11);
  wire stage45_state_equal = (dut.Ctrl.mem_ctrl_Cstate === mem_state);
  initial begin : stage45_read_mode
    #2ns;
    stage45_req_mode_found=$value$plusargs("DMEM_REQ_QUALIFIER=%d",stage45_req_mode_arg);
    if (stage45_req_mode_found) begin
      if (stage45_req_mode_arg < 0 || stage45_req_mode_arg > 2)
        $fatal(1,"STAGE45_BAD_ARG DMEM_REQ_QUALIFIER=%0d; use 0..2",stage45_req_mode_arg);
      stage45_req_qualifier=stage45_req_mode_arg;
    end
    $display("STAGE45_REQ_MODE mode=%0d found=%0d public=mem_state current=mem_ctrl_Cstate version=45.1",
      stage45_req_qualifier,stage45_req_mode_found);
  end
  assign D_macc = (stage45_req_qualifier == 0) ?
      stage45_public_active :
      (stage45_req_qualifier == 1) ?
      stage45_current_active :
      (stage45_current_active && stage45_public_active && stage45_state_equal);

  integer stage45_trace_count=0;
  always @(negedge clk) begin : stage45_request_boundary_trace
    if ($test$plusargs("TRACE45_REQ") && rst===1'b0 &&
        (stage45_public_active || stage45_current_active) &&
        stage45_trace_count < 80) begin
      stage45_trace_count++;
      $display("STAGE45_REQ_EDGE t=%0t n=%0d mode=%0d ie=%04h cs=%02b ns=%02b public=%02b equal=%0b public_active=%0b current_active=%0b selected=%0b addr=%04h rd=%b complete=%b",
        $time,stage45_trace_count,stage45_req_qualifier,IR_Exec,
        dut.Ctrl.mem_ctrl_Cstate,dut.Ctrl.mem_ctrl_Nstate,mem_state,
        stage45_state_equal,stage45_public_active,stage45_current_active,
        D_macc,Data_addr,Data_rd,complete_data);
    end
  end
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

  //stage39 passive rtl trace for request/ack and controller re-entry
  integer stage39_rtl_samples = 0;
  initial begin : stage39_mode_probe
    #2ns;
    $display("STAGE39_MODE enabled=%0d version=39.1", $test$plusargs("TRACE39_DMEM"));
  end
  always @(negedge clk) begin : stage39_rtl_trace
    if (rst === 1'b0 && $test$plusargs("TRACE39_DMEM") &&
        $time >= 470ns && $time <= 1480ns) begin
      stage39_rtl_samples = stage39_rtl_samples + 1;
      $display("STAGE39_RTL t=%0t n=%0d pc=%04h ir=%04h ie=%04h im=%04h pcout=%04h maddr=%04h mdata=%04h mctrl=%b ms=%02b cs=%02b ns=%02b req=%b addr=%04h din=%04h rd=%b cd=%b ci=%b stall=%b en=%05b",
        $time, stage39_rtl_samples, PC, IR, IR_Exec, IMem_dout,
        pcout, M_addr, M_Data, M_Control,
        mem_state, dut.Ctrl.mem_ctrl_Cstate, dut.Ctrl.mem_ctrl_Nstate,
        D_macc, Data_addr, Data_din, Data_rd, complete_data,
        complete_instr, dut.Ctrl.stall_pipe, dut.Ctrl.enables);
    end
  end

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

  //capture whether an instruction acknowledgement coincides with a stalled dut
  //the guarded responder mode is optional; this trace never changes behavior
  integer stage25_ack_count = 0;
  always @(posedge clk) begin
    if (rst === 1'b0 && $test$plusargs("TRACE_ACK_GUARD") &&
        stage25_ack_count < 120 && $time >= 350ns && $time <= 1900ns) begin
      if (imem_agent_bus.complete_instr === 1'b1 ||
          (imem_agent_bus.instrmem_rd === 1'b1 && dut.Ctrl.stall_pipe === 1'b1)) begin
        $display("IMEM_ACK_WINDOW t=%0t n=%0d pc=%04h rd=%b ci=%b ready=%b stall=%b mem=%02b ctrl=%05b ir=%04h i_data=%04h",
          $time, stage25_ack_count, imem_agent_bus.PC,
          imem_agent_bus.instrmem_rd, imem_agent_bus.complete_instr,
          imem_fetch_unstalled, dut.Ctrl.stall_pipe, mem_state,
          dut.Ctrl.state, dut.IR, imem_agent_bus.Instr_dout);
        if (imem_agent_bus.complete_instr === 1'b1 &&
            dut.Ctrl.stall_pipe === 1'b1)
          $display("IMEM_ACK_DURING_STALL t=%0t pc=%04h ir=%04h mem=%02b",
            $time, imem_agent_bus.PC, dut.IR, mem_state);
        stage25_ack_count = stage25_ack_count + 1;
      end
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

  //stage42 passive comparison of the public mem_state and internal controller registers
  integer stage42_edge_count = 0;
  integer stage42_ack_count = 0;
  integer stage42_held_ie_count = 0;
  initial begin : stage42_mode_marker
    #2ns;
    $display("STAGE42_RETIRE_MODE enabled=%0d version=42.1", $test$plusargs("TRACE42_RETIRE"));
  end

  always @(posedge clk) begin : stage42_edge_correlation
    logic [15:0] pre_ir, pre_ie, pre_pc, pre_pcout, pre_npc;
    logic [1:0] pre_mem, pre_cs, pre_ns;
    logic pre_ack, pre_macc, pre_stall;
    logic [4:0] pre_en;
    if (rst === 1'b0 && $test$plusargs("TRACE42_RETIRE") &&
        $time >= 395ns && $time <= 1450ns) begin
      //capture signals in the active region, before sequential NBA updates
      pre_ir=IR;
      pre_ie=IR_Exec;
      pre_pc=PC;
      pre_pcout=pcout;
      pre_npc=dut.npc_out_dec;
      pre_mem=mem_state;
      pre_cs=dut.Ctrl.mem_ctrl_Cstate;
      pre_ns=dut.Ctrl.mem_ctrl_Nstate;
      pre_ack=complete_data;
      pre_macc=D_macc;
      pre_stall=dut.Ctrl.stall_pipe;
      pre_en=dut.Ctrl.enables;
      //one ns after the rising edge, sequential updates have settled
      #1ns;
      if (pre_macc === 1'b1 || D_macc === 1'b1 ||
          pre_ack === 1'b1 || complete_data === 1'b1 ||
          pre_ie[15:12] === 4'he || IR_Exec[15:12] === 4'he ||
          (pre_pc >= 16'h3003 && pre_pc <= 16'h3006)) begin
        stage42_edge_count=stage42_edge_count+1;
        $display("STAGE42_EDGE t=%0t n=%0d pre:pc=%04h ir=%04h ie=%04h pout=%04h npc=%04h ms=%02b cs=%02b ns=%02b req=%b ack=%b stall=%b en=%05b | post:pc=%04h ir=%04h ie=%04h pout=%04h npc=%04h ms=%02b cs=%02b ns=%02b req=%b ack=%b stall=%b en=%05b",
          $time, stage42_edge_count,
          pre_pc, pre_ir, pre_ie, pre_pcout, pre_npc, pre_mem, pre_cs,
          pre_ns, pre_macc, pre_ack, pre_stall, pre_en,
          PC, IR, IR_Exec, pcout, dut.npc_out_dec,
          mem_state, dut.Ctrl.mem_ctrl_Cstate, dut.Ctrl.mem_ctrl_Nstate,
          D_macc, complete_data, dut.Ctrl.stall_pipe, dut.Ctrl.enables);
      end
      if (pre_ack === 1'b1) begin
        stage42_ack_count=stage42_ack_count+1;
        if (pre_ie === IR_Exec)
          stage42_held_ie_count=stage42_held_ie_count+1;
        $display("STAGE42_ACK t=%0t n=%0d ie_before=%04h ie_after=%04h held=%b cs_before=%02b cs_after=%02b ns_after=%02b ms_after=%02b req_after=%b pc_before=%04h pc_after=%04h",
          $time, stage42_ack_count, pre_ie, IR_Exec, pre_ie === IR_Exec,
          pre_cs, dut.Ctrl.mem_ctrl_Cstate, dut.Ctrl.mem_ctrl_Nstate,
          mem_state, D_macc, pre_pc, PC);
      end
      if (pre_ie[15:12] === 4'he || IR_Exec[15:12] === 4'he)
        $display("STAGE42_LEA t=%0t pre_ie=%04h post_ie=%04h pre_pc=%04h post_pc=%04h pre_pcout=%04h post_pcout=%04h pre_npc=%04h post_npc=%04h",
          $time, pre_ie, IR_Exec, pre_pc, PC, pre_pcout, pcout,
          pre_npc, dut.npc_out_dec);
    end
  end
  final begin : stage42_final_summary
    if ($test$plusargs("TRACE42_RETIRE"))
      $display("STAGE42_SUMMARY traced_edges=%0d ack_edges=%0d same_ir_exec_after_ack=%0d diagnostic_only=1",
        stage42_edge_count, stage42_ack_count, stage42_held_ie_count);
  end



  //directed, post-edge LEA datapath trace: no stimulus or DUT logic changed
  //npc_fetch and npc_decode identify where a one-word LEA discrepancy begins
  integer stage44_path_cycles=0;
  initial begin : stage44_mode
    #2ns;
    $display("STAGE44_PATH_MODE enabled=%0d version=44.1", $test$plusargs("TRACE44_PATH"));
  end
  always @(negedge clk) begin : stage44_lea_path
    if (rst === 1'b0 && $test$plusargs("TRACE44_PATH") &&
        $time >= 245ns && $time <= 700ns && stage44_path_cycles < 48) begin
      stage44_path_cycles=stage44_path_cycles+1;
      $display("STAGE44_PATH t=%0t n=%0d pc=%04h fetch_npc=%04h decode_npc=%04h ir=%04h ir_exec=%04h ci=%b cd=%b fd=%b de=%b ex=%b wb=%b pcout=%04h aluout=%04h dr=%0d wctl=%02b wb_dr_in=%04h vsr1=%04h vsr2=%04h mstate=%02b dm_addr=%04h dm_rd=%b",
        $time, stage44_path_cycles, PC, dut.npc_out_fetch, dut.npc_out_dec,
        IR, IR_Exec, complete_instr, complete_data, enable_fetch,
        enable_decode, enable_execute, enable_writeback,
        dut.pcout, dut.aluout, dut.dr, dut.W_Control_out,
        dut.WB.DR_in, dut.VSR1, dut.VSR2, dut.mem_state,
        Data_addr, Data_rd);
    end
  end

  //stage46: executed-instruction coverage is separate from completed fetch coverage.
  //sample a pending decode instruction only if execute actually latches it.
  bit stage46_exec_coverage_enabled=1'b0;
  bit stage46_trace_enabled=1'b0;
  bit [15:0] stage46_opcodes_seen='0;
  integer stage46_executed_count=0;
  integer stage46_rejected_count=0;

  covergroup stage46_exec_opcode_cg with function sample (bit [3:0] op);
    option.per_instance=1;
    executed_opcode: coverpoint op {
      bins br={4'h0};
      bins add={4'h1};
      bins ld={4'h2};
      bins st={4'h3};
      bins and_op={4'h5};
      bins ldr={4'h6};
      bins str={4'h7};
      bins not_op={4'h9};
      bins ldi={4'ha};
      bins sti={4'hb};
      bins jmp={4'hc};
      bins lea={4'he};
      illegal_bins unsupported={4'h4,4'h8,4'hd,4'hf};
    }
  endgroup
  stage46_exec_opcode_cg stage46_execute_coverage=new;

  function automatic integer stage46_supported_opcode_count();
    integer hits;
    integer k;
    hits=0;
    for(k=0;k<16;k=k+1) begin
      case(k)
        0,1,2,3,5,6,7,9,10,11,12,14: if (stage46_opcodes_seen[k]) hits=hits+1;
        default: begin end
      endcase
    end
    return hits;
  endfunction

  initial begin : stage46_execute_mode
    #2ns;
    stage46_exec_coverage_enabled=$test$plusargs("EXEC_COVERAGE");
    stage46_trace_enabled=$test$plusargs("TRACE46_EXEC");
    $display("STAGE46_EXEC_MODE enabled=%0d trace=%0d version=46.1",
      stage46_exec_coverage_enabled,stage46_trace_enabled);
  end

  always @(posedge clk) begin : stage46_execute_acceptance
    logic [15:0] sampled_ir;
    logic [15:0] sampled_npc;
    bit sample_pending;
    sampled_ir=IR;
    sampled_npc=npc_out;
    sample_pending=(rst===1'b0 && stage46_exec_coverage_enabled &&
                    enable_execute===1'b1 && (^IR !== 1'bx));
    if(sample_pending) begin
      //the dut registers ir_exec on this edge; wait only for nba settlement.
      #1ns;
      if(IR_Exec === sampled_ir) begin
        stage46_executed_count=stage46_executed_count+1;
        stage46_opcodes_seen[sampled_ir[15:12]]=1'b1;
        stage46_execute_coverage.sample(sampled_ir[15:12]);
        if(stage46_trace_enabled && stage46_executed_count<=110)
          $display("STAGE46_EXEC t=%0t n=%0d instr=%04h opcode=%1h decode_npc=%04h ir_exec=%04h",
            $time,stage46_executed_count,sampled_ir,sampled_ir[15:12],sampled_npc,IR_Exec);
      end else begin
        stage46_rejected_count=stage46_rejected_count+1;
        if(stage46_trace_enabled && stage46_rejected_count<=25)
          $display("STAGE46_EXEC_UNVERIFIED t=%0t count=%0d intended_ir=%04h actual_ir_exec=%04h",
            $time,stage46_rejected_count,sampled_ir,IR_Exec);
      end
    end
  end

  final begin : stage46_execute_summary
    if(stage46_exec_coverage_enabled)
      $display("STAGE46_EXEC_SUMMARY accepted=%0d unverified=%0d supported_unique=%0d/12 opcode_mask=%04h jmp_seen=%0d",
        stage46_executed_count,stage46_rejected_count,
        stage46_supported_opcode_count(),stage46_opcodes_seen,
        stage46_opcodes_seen[4'hc]);
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

