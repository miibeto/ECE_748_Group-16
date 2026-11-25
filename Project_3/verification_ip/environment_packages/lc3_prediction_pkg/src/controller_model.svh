function void decode_lc3_insn
  (
    input bit [15:0] insn,
    output decoded_insn_t decode_insn
  );

  //stage49:optional branch-never control-hazard experiment
  //the default preserves the supplied reference model exactly
  static bit stage49_mode_ready = 0;
  static int stage49_brnever_nop = 0;
  static int stage49_brnever_traces = 0;
  if (!stage49_mode_ready) begin
    void'($value$plusargs("CTRL49_BRNEVER_NOP=%d", stage49_brnever_nop));
    if ((stage49_brnever_nop != 0) && (stage49_brnever_nop != 1)) begin
      $error("STAGE49_BAD_MODE mode=%0d permitted=0,1", stage49_brnever_nop);
      stage49_brnever_nop = 0;
    end
    stage49_mode_ready = 1;
    $display("STAGE49_BR_MODE branch_never_as_noncontrol=%0d version=49.1", stage49_brnever_nop);
  end

  decode_insn.opcode = opcode_t'(insn[15:12]);

  case (decode_insn.opcode)

    ADD, AND: begin
      decode_insn.optype = ALU;
      decode_insn.mod_cf = 1;
      decode_insn.use_cf = 0;
      decode_insn.use_dr = 1;
      decode_insn.use_sr1 = 1;
      decode_insn.use_sr2 = !insn[5];
      decode_insn.use_imm = insn[5];
      decode_insn.dr = insn[11:9];
      decode_insn.sr1 = insn[8:6];
      decode_insn.sr2 = insn[2:0];
      decode_insn.imm_ext = {{11{insn[4]}}, insn[4:0]};
    end

    NOT: begin
      decode_insn.optype = ALU;
      decode_insn.mod_cf = 1;
      decode_insn.use_cf = 0;
      decode_insn.use_dr = 1;
      decode_insn.use_sr1 = 1;
      decode_insn.use_sr2 = 0;
      decode_insn.use_imm = 0;
      decode_insn.dr = insn[11:9];
      decode_insn.sr1 = insn[8:6];
      decode_insn.sr2 = 0;
      decode_insn.imm_ext = 0;
    end

    BR: begin
      //a mask of 000 is architecturally never taken
      //mode 1 tests whether the rtl treats this case as a non-control operation
      if ((stage49_brnever_nop == 1) && (insn[11:9] == 3'b000))
        decode_insn.optype = ALU;
      else
        decode_insn.optype = CONTROL;
      decode_insn.mod_cf = 0;
      decode_insn.use_cf = (stage49_brnever_nop == 1 && insn[11:9] == 3'b000) ? 0 : 1;
      if ((insn[11:9] == 3'b000) && (stage49_brnever_traces < 14)) begin
        $display("STAGE49_BRNEVER_DECODE t=%0t insn=%04h noncontrol=%0d",
          $time, insn, (stage49_brnever_nop == 1));
        stage49_brnever_traces++;
      end
      decode_insn.use_dr = 0;
      decode_insn.use_sr1 = 0;
      decode_insn.use_sr2 = 0;
      decode_insn.use_imm = 1;
      decode_insn.dr = insn[11:9];
      decode_insn.sr1 = 0;
      decode_insn.sr2 = 0;
      decode_insn.imm_ext = {{7{insn[8]}}, insn[8:0]};
    end

    JMP: begin
      decode_insn.optype = CONTROL;
      decode_insn.mod_cf = 0;
      decode_insn.use_cf = 0;
      decode_insn.use_dr = 0;
      decode_insn.use_sr1 = 1;
      decode_insn.use_sr2 = 0;
      decode_insn.use_imm = 0;
      decode_insn.dr = 0;
      decode_insn.sr1 = insn[8:6];
      decode_insn.sr2 = 0;
      decode_insn.imm_ext = {{7{insn[8]}}, insn[8:0]};
    end

    JSR: begin
      decode_insn.optype = CONTROL;
      decode_insn.mod_cf = 0;
      decode_insn.use_cf = 0;
      decode_insn.use_dr = 1;
      decode_insn.use_sr1 = !insn[11];
      decode_insn.use_sr2 = 0;
      decode_insn.use_imm = insn[11];
      decode_insn.dr = 3'd7;
      decode_insn.sr1 = insn[8:6];
      decode_insn.sr2 = 0;
      decode_insn.imm_ext = {{5{insn[10]}}, insn[10:0]};
    end

    LD, LDI: begin
      decode_insn.optype = MEMORY;
      decode_insn.mod_cf = 1;
      decode_insn.use_cf = 0;
      decode_insn.use_dr = 1;
      decode_insn.use_sr1 = 0;
      decode_insn.use_sr2 = 0;
      decode_insn.use_imm = 1;
      decode_insn.dr = insn[11:9];
      decode_insn.sr1 = 0;
      decode_insn.sr2 = 0;
      decode_insn.imm_ext = {{7{insn[8]}}, insn[8:0]};
    end

    LDR: begin
      decode_insn.optype = MEMORY;
      decode_insn.mod_cf = 1;
      decode_insn.use_cf = 0;
      decode_insn.use_dr = 1;
      decode_insn.use_sr1 = 1;
      decode_insn.use_sr2 = 0;
      decode_insn.use_imm = 1;
      decode_insn.dr = insn[11:9];
      decode_insn.sr1 = insn[8:6];
      decode_insn.sr2 = 0;
      decode_insn.imm_ext = {{10{insn[5]}}, insn[5:0]};
    end

    LEA: begin
      decode_insn.optype = ALU;
      decode_insn.mod_cf = 1;
      decode_insn.use_cf = 0;
      decode_insn.use_dr = 1;
      decode_insn.use_sr1 = 0;
      decode_insn.use_sr2 = 0;
      decode_insn.use_imm = 1;
      decode_insn.dr = insn[11:9];
      decode_insn.sr1 = 0;
      decode_insn.sr2 = 0;
      decode_insn.imm_ext = {{7{insn[8]}}, insn[8:0]};
    end

    RTI: begin
      decode_insn.optype = PRIVILEGE;
      decode_insn.mod_cf = 0;
      decode_insn.use_cf = 0;
      decode_insn.use_dr = 1;
      decode_insn.use_sr1 = 0;
      decode_insn.use_sr2 = 0;
      decode_insn.use_imm = 0;
      decode_insn.dr = 3'd6;
      decode_insn.sr1 = 0;
      decode_insn.sr2 = 0;
      decode_insn.imm_ext = 0;
    end

    ST, STI: begin
      decode_insn.optype = MEMORY;
      decode_insn.mod_cf = 0;
      decode_insn.use_cf = 0;
      decode_insn.use_dr = 0;
      decode_insn.use_sr1 = 0;
      decode_insn.use_sr2 = 1;
      decode_insn.use_imm = 1;
      decode_insn.dr = 0;
      decode_insn.sr1 = 0;
      decode_insn.sr2 = insn[11:9];
      decode_insn.imm_ext = {{7{insn[8]}}, insn[8:0]};
    end

    STR: begin
      decode_insn.optype = MEMORY;
      decode_insn.mod_cf = 0;
      decode_insn.use_cf = 0;
      decode_insn.use_dr = 0;
      decode_insn.use_sr1 = 1;
      decode_insn.use_sr2 = 1;
      decode_insn.use_imm = 1;
      decode_insn.dr = 0;
      decode_insn.sr1 = insn[8:6];
      decode_insn.sr2 = insn[11:9];
      decode_insn.imm_ext = {{7{insn[8]}}, insn[8:0]};
    end

    TRAP: begin
      decode_insn.optype = PRIVILEGE;
      decode_insn.mod_cf = 0;
      decode_insn.use_cf = 0;
      decode_insn.use_dr = 1;
      decode_insn.use_sr1 = 0;
      decode_insn.use_sr2 = 0;
      decode_insn.use_imm = 1;
      decode_insn.dr = 3'd7;
      decode_insn.sr1 = 0;
      decode_insn.sr2 = 0;
      decode_insn.imm_ext = {{8{1'b0}}, insn[7:0]};
    end

    RESERVED: begin
      assert(0);
    end

  endcase;

endfunction : decode_lc3_insn

// The controller_model function models the behavior of the controller unit
// The return value indicates model results status: 0 success, 1 failure
function bit controller_model
  (
    input bit complete_data,
    input bit complete_instr,
    input bit [15: 0] IR,
    input bit [2: 0] psr,
    input bit [15: 0] IR_Exec,
    input bit [15: 0] IMem_dout,
    input bit [2: 0] NZP,
    output bit enable_updatePC,
    output bit enable_fetch,
    output bit enable_decode,
    output bit enable_execute,
    output bit enable_writeback,
    output bit bypass_alu_1,
    output bit bypass_alu_2,
    output bit bypass_mem_1,
    output bit bypass_mem_2,
    output bit [1: 0] mem_state,
    output bit br_taken
  );

  typedef enum bit[2: 0] {
            MEM_STATE_INIT = 3'b011,
            MEM_STATE_RD = 3'b000,
            MEM_STATE_WR = 3'b010,
            MEM_STATE_RD_IND = 3'b001,
            MEM_STATE_WR_IND = 3'b101
          } mem_st_t;

  /*
  *
  * What are the FE1 and FE2 stage?
  *
  * The entire Fetch stage is actually comprised by two sub stage:
  *   - Fetch 1: Generating next PC using signals enable_updatePC and br_taken
  *   - Fetch 2: Requesting Instruction from IMem at the PC generated by Fetch 1
  *
  * This is because the IMem has at least one cycle delay
  *
  */
  static bit has_been_reset = 0;
  //stage65:the startup diagram shows pc advancement before decode admission
  static bit stage65_first_pc_advance = 0;
  static bit fe1_out_valid = 0;
  static bit fe2_out_valid = 0;
  static bit dec_out_valid = 0;
  static bit exe_out_valid = 0;
  static mem_st_t mem_state_internal = MEM_STATE_INIT;
//stage50:passive branch validity and control-path state trace
static bit stage50_probe_ready = 0;
static int stage50_probe_on = 0;
static int unsigned stage50_probe_index = 0;
bit stage50_pre_fe1;
bit stage50_pre_fe2;
bit stage50_pre_dec;
bit stage50_pre_exe;
bit stage50_pre_reset;

  //stage62:qualify instruction availability without destroying saved fetch state
  bit fetch_instruction_ready;
  bit next_fe1_out_valid;
  bit next_fe2_out_valid;
  bit next_dec_out_valid;
  bit next_exe_out_valid;

  bit is_pipeline_mem_stall;
  bit is_pipeline_has_branch;
  bit is_branch_taken;
  bit is_branch_resolved;
  bit is_insn_need_wtb;

  decoded_insn_t insn_fe2_out;
  decoded_insn_t insn_dec_out;
  decoded_insn_t insn_exe_out;

  //*********** Generate internal control signals ****************************//
  //qualify current instruction data with complete_instr; retain the saved fetch slot
  //during a data-memory stall, so a later response can still advance to decode
if (!stage50_probe_ready) begin
  void'($value$plusargs("TRACE50_BRANCH=%d",stage50_probe_on));
  stage50_probe_ready=1;
  if (stage50_probe_on != 0)
    $display("STAGE50_MODEL_MODE trace=%0d version=50.1",stage50_probe_on);
end
stage50_pre_fe1=fe1_out_valid;
stage50_pre_fe2=fe2_out_valid;
stage50_pre_dec=dec_out_valid;
stage50_pre_exe=exe_out_valid;
stage50_pre_reset=has_been_reset;
  fetch_instruction_ready = fe2_out_valid & complete_instr & stage65_first_pc_advance;

  // Decode the instruction in different stage
  decode_lc3_insn(IMem_dout, insn_fe2_out);
  decode_lc3_insn(IR, insn_dec_out);
  decode_lc3_insn(IR_Exec, insn_exe_out);

  is_branch_taken = 0;
  is_branch_resolved = 0;
  is_insn_need_wtb = 0;
  // Post-Execution behavior
  if (exe_out_valid) begin
    // - For all instructions that needs writeback stage
    is_insn_need_wtb = insn_exe_out.use_dr;

    // - For Control-type instruction
    if (insn_exe_out.optype == CONTROL) begin
      // Control-type instruction will use its writeback cycle to update the
      // new fetch PC (which is maintained in the FE1 stage)
      is_branch_taken = (psr & NZP) != 0;
      is_branch_resolved = 1;
    end

    // - For Memory-type instruction
    case (mem_state_internal)
      MEM_STATE_INIT: begin
        if ((insn_exe_out.opcode == LDR) || ( insn_exe_out.opcode == LD )) begin
          mem_state_internal = MEM_STATE_RD;
        end
        else if ((insn_exe_out.opcode == STR) || (insn_exe_out.opcode == ST)) begin
          mem_state_internal = MEM_STATE_WR;
        end
        else if (insn_exe_out.opcode == LDI) begin
          mem_state_internal = MEM_STATE_RD_IND;
        end
        else if (insn_exe_out.opcode == STI) begin
          mem_state_internal = MEM_STATE_WR_IND;
        end
      end

      MEM_STATE_RD: begin
        if (complete_data) begin
          mem_state_internal = MEM_STATE_INIT;
        end
      end

      MEM_STATE_WR: begin
        if (complete_data) begin
          mem_state_internal = MEM_STATE_INIT;
        end
      end

      MEM_STATE_RD_IND: begin
        if (complete_data) begin
          mem_state_internal = MEM_STATE_RD;
        end
      end

      MEM_STATE_WR_IND: begin
        if (complete_data) begin
          mem_state_internal = MEM_STATE_WR;
        end
      end

      default:
        assert(0);

    endcase
  end

  // When the MEM stage is activated, the entire pipeline is frozen.
  is_pipeline_mem_stall = mem_state_internal != MEM_STATE_INIT;
  // Is a control-type instruction get into the pipeline, the pipeline will
  // keep fetching bubbles until the branch target is resolved
  is_pipeline_has_branch = (
                           (fetch_instruction_ready && insn_fe2_out.optype == CONTROL) ||
                           (dec_out_valid && insn_dec_out.optype == CONTROL) ||
                           (exe_out_valid && insn_exe_out.optype == CONTROL)
                         );
  // Befoe the branch is resolved, the PC output of FE1 stage is invalid
  next_fe1_out_valid = is_pipeline_mem_stall ? fe1_out_valid :
                       (!is_pipeline_has_branch || is_branch_resolved);
  // If there is a branch in the pipeline, the pipeline should stop fetching
  // new instruction from the IMem immediately
  next_fe2_out_valid = is_pipeline_mem_stall ? fe2_out_valid :
                       (!is_pipeline_has_branch && fe1_out_valid);
  next_dec_out_valid = is_pipeline_mem_stall ? dec_out_valid : fetch_instruction_ready;
  next_exe_out_valid = is_pipeline_mem_stall ? exe_out_valid : dec_out_valid;


  //*********** Generate Pipeline stage control signal ***********************//
  br_taken         = !is_pipeline_mem_stall && is_branch_taken;
  enable_updatePC  = has_been_reset &&
                     !is_pipeline_mem_stall && (!is_pipeline_has_branch || is_branch_taken);
  enable_fetch     = !has_been_reset ||
                     !is_pipeline_mem_stall && next_fe2_out_valid;
  enable_decode    = !is_pipeline_mem_stall && next_dec_out_valid;
  enable_execute   = !is_pipeline_mem_stall && next_exe_out_valid;
  enable_writeback = !is_pipeline_mem_stall && is_insn_need_wtb;
  mem_state        = mem_state_internal[1: 0];

  //*********** Generate Pipeline data bypass sigal **************************//
  bypass_alu_1 = 0;
  bypass_alu_2 = 0;
  bypass_mem_1 = 0;
  bypass_mem_2 = 0;

  if (insn_exe_out.use_dr) begin
    if (insn_dec_out.use_sr1 && (insn_dec_out.sr1 == insn_exe_out.dr))
      if (insn_exe_out.optype == MEMORY)
        bypass_mem_1 = 1;
      else
        bypass_alu_1 = 1;
    if (insn_dec_out.use_sr2 && (insn_dec_out.sr2 == insn_exe_out.dr))
      if (insn_exe_out.optype == MEMORY)
        bypass_mem_2 = 1;
      else
        bypass_alu_2 = 1;
  end

  //*********** Update valid information for next prediction *****************//
  fe1_out_valid = next_fe1_out_valid;
  fe2_out_valid = next_fe2_out_valid;
  dec_out_valid = next_dec_out_valid;
  exe_out_valid = next_exe_out_valid;

//stage65:mark the first independently predicted, completed pc advancement
if (enable_updatePC && complete_instr)
  stage65_first_pc_advance = 1;
has_been_reset = 1;

if (stage50_probe_on != 0) begin
  stage50_probe_index++;
  if (stage50_probe_index <= 400) begin
    $display({"STAGE50_MODEL t=%0t n=%0d ci=%b cd=%b ir=%04h ie=%04h im=%04h psr=%03b nzp=%03b ",
      "valid_pre=%b%b%b%b valid_post=%b%b%b%b reset_pre=%b hazard=%b resolved=%b taken=%b ",
      "stall=%b pc=%b fetch=%b dec=%b exe=%b wb=%b br=%b mem=%b"},
      $time,stage50_probe_index,complete_instr,complete_data,IR,IR_Exec,IMem_dout,psr,NZP,
      stage50_pre_fe1,stage50_pre_fe2,stage50_pre_dec,stage50_pre_exe,
      fe1_out_valid,fe2_out_valid,dec_out_valid,exe_out_valid,
      stage50_pre_reset,is_pipeline_has_branch,is_branch_resolved,is_branch_taken,
      is_pipeline_mem_stall,enable_updatePC,enable_fetch,enable_decode,enable_execute,
      enable_writeback,br_taken,mem_state);
  end
end

return (0);
endfunction
