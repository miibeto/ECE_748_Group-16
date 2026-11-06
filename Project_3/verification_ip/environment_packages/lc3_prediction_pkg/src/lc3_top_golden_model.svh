// =========================================================================
// File Name   : lc3_top_golden_model.svh
// Description : Top-Level LC-3 Golden Model Function
//               Integrates controller, fetch, decode, execute, mem_access,
//               and writeback stage models into a single function step.
// =========================================================================

function bit lc3_top_golden_model
  (
    // DUT Inputs
    input  bit        complete_data,
    input  bit        complete_instr,
    input  bit [15:0] Instr_dout,
    input  bit [15:0] Data_dout,

    // DUT Outputs (Predicted)
    output bit [15:0] PC,
    output bit        instrmem_rd,
    output bit [15:0] Data_addr,
    output bit [15:0] Data_din,
    output bit        Data_rd
  );

  // -----------------------------------------------------------------------
  // Static Pipeline Register State (Preserved across function calls)
  // -----------------------------------------------------------------------
  // Decode Stage Pipeline Registers
  static bit [15:0] dec_ir          = 16'h0000;
  static bit [15:0] dec_npc_out     = 16'h3001;
  static bit [5:0]  dec_e_control   = 6'b000000;
  static bit [1:0]  dec_w_control   = 2'b00;
  static bit        dec_mem_control = 1'b0;

  // Execute Stage Pipeline Outputs & Signals
  static bit [15:0] exe_aluout          = 16'h0000;
  static bit [1:0]  exe_w_control_out   = 2'b00;
  static bit        exe_mem_control_out = 1'b0;
  static bit [15:0] exe_m_data          = 16'h0000;
  static bit [2:0]  exe_dr              = 3'b000;
  static bit [2:0]  exe_sr1             = 3'b000;
  static bit [2:0]  exe_sr2             = 3'b000;
  static bit [15:0] exe_ir_exec         = 16'h0000;
  static bit [2:0]  exe_nzp             = 3'b000;
  static bit [15:0] exe_pcout           = 16'h0000;

  // MemAccess Stage Output
  static bit [15:0] mem_memout          = 16'h0000;

  // Writeback Stage Outputs / Register File Outputs
  static bit [15:0] wb_vsr1             = 16'h0000;
  static bit [15:0] wb_vsr2             = 16'h0000;
  static bit [2:0]  wb_psr              = 3'b010; // Default Zero flag

  // Controller Control Signals
  bit        enable_updatePC;
  bit        enable_fetch;
  bit        enable_decode;
  bit        enable_execute;
  bit        enable_writeback;
  bit        bypass_alu_1;
  bit        bypass_alu_2;
  bit        bypass_mem_1;
  bit        bypass_mem_2;
  bit [1:0]  mem_state;
  bit        br_taken;

  // Fetch Stage Signals
  bit [15:0] fetch_npc;

  // Decode Stage Intermediate Outputs (Combinational)
  bit [15:0] next_ir;
  bit [15:0] next_npc_out;
  bit [5:0]  next_e_control;
  bit [1:0]  next_w_control;
  bit        next_mem_control;

  // -----------------------------------------------------------------------
  // 1. Controller Model Evaluation
  // -----------------------------------------------------------------------
  void'(controller_model(
    .complete_data    (complete_data),
    .complete_instr   (complete_instr),
    .IR               (dec_ir),
    .psr              (wb_psr),
    .IR_Exec          (exe_ir_exec),
    .IMem_dout        (Instr_dout),
    .NZP              (exe_nzp),
    .enable_updatePC  (enable_updatePC),
    .enable_fetch     (enable_fetch),
    .enable_decode    (enable_decode),
    .enable_execute   (enable_execute),
    .enable_writeback (enable_writeback),
    .bypass_alu_1     (bypass_alu_1),
    .bypass_alu_2     (bypass_alu_2),
    .bypass_mem_1     (bypass_mem_1),
    .bypass_mem_2     (bypass_mem_2),
    .mem_state        (mem_state),
    .br_taken         (br_taken)
  ));

  // -----------------------------------------------------------------------
  // 2. Fetch Stage Evaluation
  // -----------------------------------------------------------------------
  void'(fetch_model(
    .enable_updatePC  (enable_updatePC),
    .enable_fetch     (enable_fetch),
    .br_taken         (br_taken),
    .taddr            (exe_pcout),
    .npc              (fetch_npc),
    .pc               (PC),
    .instrmem_rd      (instrmem_rd)
  ));

  // -----------------------------------------------------------------------
  // 3. Decode Stage Evaluation (Combinational Decode of IMem_dout)
  // -----------------------------------------------------------------------
  void'(decode_model(
    .instr_dout       (Instr_dout),
    .npc_in           (fetch_npc),
    .ir               (next_ir),
    .npc_out          (next_npc_out),
    .e_control        (next_e_control),
    .w_control        (next_w_control),
    .mem_control      (next_mem_control)
  ));

  // -----------------------------------------------------------------------
  // 4. Execute Stage Evaluation
  // -----------------------------------------------------------------------
  void'(execute_model(
    .E_Control        (dec_e_control),
    .bypass_alu_1     (bypass_alu_1),
    .bypass_alu_2     (bypass_alu_2),
    .bypass_mem_1     (bypass_mem_1),
    .bypass_mem_2     (bypass_mem_2),
    .enable_execute   (enable_execute),
    .IR               (dec_ir),
    .npc_in           (dec_npc_out),
    .Mem_Control_in   (dec_mem_control),
    .W_Control_in     (dec_w_control),
    .Mem_Bypass_Val   (mem_memout),
    .VSR1             (wb_vsr1),
    .VSR2             (wb_vsr2),
    .aluout           (exe_aluout),
    .W_Control_out    (exe_w_control_out),
    .Mem_Control_out  (exe_mem_control_out),
    .M_Data           (exe_m_data),
    .dr               (exe_dr),
    .sr1              (exe_sr1),
    .sr2              (exe_sr2),
    .IR_Exec          (exe_ir_exec),
    .NZP              (exe_nzp),
    .pcout            (exe_pcout)
  ));

  // -----------------------------------------------------------------------
  // 5. Memory Access Stage Evaluation
  // -----------------------------------------------------------------------
  void'(mem_access_model(
    .M_Data           (exe_m_data),
    .M_Addr           (exe_pcout),
    .M_Control        (exe_mem_control_out),
    .mem_state        (mem_state),
    .DMem_dout        (Data_dout),
    .DMem_addr        (Data_addr),
    .DMem_din         (Data_din),
    .memout           (mem_memout),
    .DMem_rd          (Data_rd)
  ));

  // -----------------------------------------------------------------------
  // 6. Writeback Stage Evaluation (Async RegFile Read & Sync Update)
  // -----------------------------------------------------------------------
  void'(writeback_model(
    .aluout           (exe_aluout),
    .W_Control        (exe_w_control_out),
    .npc              (dec_npc_out),
    .pcout            (exe_pcout),
    .memout           (mem_memout),
    .enable_writeback (enable_writeback),
    .sr1              (exe_sr1),
    .sr2              (exe_sr2),
    .dr               (exe_dr),
    .vsr1             (wb_vsr1),
    .vsr2             (wb_vsr2),
    .psr              (wb_psr)
  ));

  // -----------------------------------------------------------------------
  // 7. Synchronous Pipeline Register Update
  // -----------------------------------------------------------------------
  if (enable_decode) begin
    dec_ir          = next_ir;
    dec_npc_out     = next_npc_out;
    dec_e_control   = next_e_control;
    dec_w_control   = next_w_control;
    dec_mem_control = next_mem_control;
  end

  return 0; // Success
endfunction