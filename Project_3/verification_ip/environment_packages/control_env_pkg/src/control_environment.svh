//----------------------------------------------------------------------
// Created with uvmf_gen version 2023.4_2
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//                                          
// DESCRIPTION: This environment contains all agents, predictors and
// scoreboards required for the block level design.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//

class control_environment  extends uvmf_environment_base #(
    .CONFIG_T( control_env_configuration 
  ));
  `uvm_component_utils( control_environment )





  typedef control_in_agent  control_in_agent_t;
  control_in_agent_t control_in_agent;

  typedef control_out_agent  control_out_agent_t;
  control_out_agent_t control_out_agent;




  typedef control_predictor #(
                .CONFIG_T(CONFIG_T)
                )
 control_pred_t;
  control_pred_t control_pred;

  typedef uvmf_in_order_scoreboard #(.T(control_out_transaction))  control_sb_t;
  control_sb_t control_sb;



  typedef uvmf_virtual_sequencer_base #(.CONFIG_T(control_env_configuration)) control_vsqr_t;
  control_vsqr_t vsqr;

  // pragma uvmf custom class_item_additional begin
  //stage31 independently observes the exact expected/actual transaction streams
  //from the existing scoreboard, without changing predictions or scoreboard rules
  uvm_tlm_analysis_fifo #(control_out_transaction) stage31_expected_fifo;
  uvm_tlm_analysis_fifo #(control_out_transaction) stage31_actual_fifo;
  //stage34 pairs the corresponding input with the same-cycle prediction and observation
  uvm_tlm_analysis_fifo #(control_in_transaction) stage34_input_fifo;
  int unsigned stage34_ack_count;
  int unsigned stage34_ack_actual_decode;
  int unsigned stage34_ack_expected_decode;
  int unsigned stage34_data_count;
  int unsigned stage31_compared;
  int unsigned stage31_transactions_mismatched;
  int unsigned stage31_field_mismatches[11];

  //stage33 stores four-state snapshots for timing comparisons, not transaction handles
  //this avoids any monitor object reuse affecting the retrospective comparison
  logic [11:0] stage33_expected_samples[$];
  logic [11:0] stage33_actual_samples[$];

  function automatic logic [11:0] stage33_pack(control_out_transaction tr);
    return {tr.enable_updatePC, tr.enable_fetch, tr.enable_decode,
            tr.enable_execute, tr.enable_writeback, tr.br_taken,
            tr.bypass_alu_1, tr.bypass_alu_2,
            tr.bypass_mem_1, tr.bypass_mem_2, tr.mem_state};
  endfunction

  function automatic bit stage33_field_diff(int index,
                                             logic [11:0] exp_sample,
                                             logic [11:0] act_sample);
    if (index == 10)
      return (exp_sample[1:0] !== act_sample[1:0]);
    return (exp_sample[11-index] !== act_sample[11-index]);
  endfunction

  function string stage31_field_name(int unsigned index);
    case (index)
      0: return "enable_updatePC";
      1: return "enable_fetch";
      2: return "enable_decode";
      3: return "enable_execute";
      4: return "enable_writeback";
      5: return "br_taken";
      6: return "bypass_alu_1";
      7: return "bypass_alu_2";
      8: return "bypass_mem_1";
      9: return "bypass_mem_2";
      10: return "mem_state";
      default: return "unknown";
    endcase
  endfunction
  // pragma uvmf custom class_item_additional end
 
// ****************************************************************************
// FUNCTION : new()
// This function is the standard SystemVerilog constructor.
//
  function new( string name = "", uvm_component parent = null );
    super.new( name, parent );
  endfunction

// ****************************************************************************
// FUNCTION: build_phase()
// This function builds all components within this environment.
//
  virtual function void build_phase(uvm_phase phase);
// pragma uvmf custom build_phase_pre_super begin
// pragma uvmf custom build_phase_pre_super end
    super.build_phase(phase);
    control_in_agent = control_in_agent_t::type_id::create("control_in_agent",this);
    control_in_agent.set_config(configuration.control_in_agent_config);
    control_out_agent = control_out_agent_t::type_id::create("control_out_agent",this);
    control_out_agent.set_config(configuration.control_out_agent_config);
    control_pred = control_pred_t::type_id::create("control_pred",this);
    control_pred.configuration = configuration;
    control_sb = control_sb_t::type_id::create("control_sb",this);
    stage31_expected_fifo = new("stage31_expected_fifo", this);
    stage31_actual_fifo = new("stage31_actual_fifo", this);
    stage34_input_fifo = new("stage34_input_fifo", this);

    vsqr = control_vsqr_t::type_id::create("vsqr", this);
    vsqr.set_config(configuration);
    configuration.set_vsqr(vsqr);

    // pragma uvmf custom build_phase begin
    // pragma uvmf custom build_phase end
  endfunction

// ****************************************************************************
// FUNCTION: connect_phase()
// This function makes all connections within this environment.  Connections
// typically inclue agent to predictor, predictor to scoreboard and scoreboard
// to agent.
//
  virtual function void connect_phase(uvm_phase phase);
// pragma uvmf custom connect_phase_pre_super begin
// pragma uvmf custom connect_phase_pre_super end
    super.connect_phase(phase);
    control_in_agent.monitored_ap.connect(control_pred.control_in_agent_ae);
    control_in_agent.monitored_ap.connect(stage34_input_fifo.analysis_export);
    control_pred.control_sb_ap.connect(control_sb.expected_analysis_export);
    control_out_agent.monitored_ap.connect(control_sb.actual_analysis_export);
    //observe the same streams the original scoreboard receives, without replacing it
    control_pred.control_sb_ap.connect(stage31_expected_fifo.analysis_export);
    control_out_agent.monitored_ap.connect(stage31_actual_fifo.analysis_export);
    // pragma uvmf custom reg_model_connect_phase begin
    // pragma uvmf custom reg_model_connect_phase end
  endfunction

// ****************************************************************************
// FUNCTION: end_of_simulation_phase()
// This function is executed just prior to executing run_phase.  This function
// was added to the environment to sample environment configuration settings
// just before the simulation exits time 0.  The configuration structure is 
// randomized in the build phase before the environment structure is constructed.
// Configuration variables can be customized after randomization in the build_phase
// of the extended test.
// If a sequence modifies values in the configuration structure then the sequence is
// responsible for sampling the covergroup in the configuration if required.
//
  virtual function void start_of_simulation_phase(uvm_phase phase);
     configuration.control_configuration_cg.sample();
  endfunction

  //stage31 mismatch attribution for every controller output
  //the real uvmf scoreboard remains the verification authority
  virtual task run_phase(uvm_phase phase);
    control_out_transaction expected;
    control_out_transaction observed;
    control_in_transaction input_sample;
    bit any_mismatch;
    int stage50_trace;
    logic [11:0] stage50_expected;
    logic [11:0] stage50_actual;
    logic [11:0] stage50_different;
    super.run_phase(phase);
    stage50_trace=0;
    void'($value$plusargs("TRACE50_BRANCH=%d",stage50_trace));
    if (stage50_trace != 0)
      `uvm_info("STAGE50_MODE", "trace=1 version=50.1 cycle_comparison=400 no_waivers=1", UVM_NONE)
    forever begin
      stage31_expected_fifo.get(expected);
      stage31_actual_fifo.get(observed);
      stage34_input_fifo.get(input_sample);
      stage33_expected_samples.push_back(stage33_pack(expected));
      stage33_actual_samples.push_back(stage33_pack(observed));
      stage31_compared++;
      //the trace is observational only; the original scoreboard remains unchanged
      if (input_sample.complete_instr === 1'b1) begin
        stage34_ack_count++;
        if (observed.enable_decode === 1'b1) stage34_ack_actual_decode++;
        if (expected.enable_decode === 1'b1) stage34_ack_expected_decode++;
      end
      if (input_sample.complete_data === 1'b1) stage34_data_count++;
      if (stage31_compared <= 115) begin
        `uvm_info("CTRL34_CYCLE", $sformatf(
          "n=%0d ci=%b cd=%b ir=%04h ie=%04h im=%04h psr=%b nzp=%b | exp: pc=%b f=%b d=%b e=%b w=%b br=%b ms=%b | dut: pc=%b f=%b d=%b e=%b w=%b br=%b ms=%b",
          stage31_compared,
          input_sample.complete_instr, input_sample.complete_data,
          input_sample.IR, input_sample.IR_Exec, input_sample.IMem_dout,
          input_sample.psr, input_sample.NZP,
          expected.enable_updatePC, expected.enable_fetch, expected.enable_decode,
          expected.enable_execute, expected.enable_writeback,
          expected.br_taken, expected.mem_state,
          observed.enable_updatePC, observed.enable_fetch, observed.enable_decode,
          observed.enable_execute, observed.enable_writeback,
          observed.br_taken, observed.mem_state), UVM_NONE)
      end
      any_mismatch = 0;
      if (expected.enable_updatePC !== observed.enable_updatePC) begin
        stage31_field_mismatches[0]++; any_mismatch = 1;
      end
      if (expected.enable_fetch !== observed.enable_fetch) begin
        stage31_field_mismatches[1]++; any_mismatch = 1;
      end
      if (expected.enable_decode !== observed.enable_decode) begin
        stage31_field_mismatches[2]++; any_mismatch = 1;
      end
      if (expected.enable_execute !== observed.enable_execute) begin
        stage31_field_mismatches[3]++; any_mismatch = 1;
      end
      if (expected.enable_writeback !== observed.enable_writeback) begin
        stage31_field_mismatches[4]++; any_mismatch = 1;
      end
      if (expected.br_taken !== observed.br_taken) begin
        stage31_field_mismatches[5]++; any_mismatch = 1;
      end
      if (expected.bypass_alu_1 !== observed.bypass_alu_1) begin
        stage31_field_mismatches[6]++; any_mismatch = 1;
      end
      if (expected.bypass_alu_2 !== observed.bypass_alu_2) begin
        stage31_field_mismatches[7]++; any_mismatch = 1;
      end
      if (expected.bypass_mem_1 !== observed.bypass_mem_1) begin
        stage31_field_mismatches[8]++; any_mismatch = 1;
      end
      if (expected.bypass_mem_2 !== observed.bypass_mem_2) begin
        stage31_field_mismatches[9]++; any_mismatch = 1;
      end
      if (expected.mem_state !== observed.mem_state) begin
        stage31_field_mismatches[10]++; any_mismatch = 1;
      end
      if (stage50_trace != 0 && stage31_compared <= 400) begin
        stage50_expected = stage33_pack(expected);
        stage50_actual = stage33_pack(observed);
        stage50_different = stage50_expected ^ stage50_actual;
        `uvm_info("STAGE50_CYCLE", $sformatf(
          {"n=%0d ci=%b cd=%b ir=%04h ie=%04h im=%04h psr=%03b nzp=%03b ",
          "expected=%03h actual=%03h diff=%03h mismatch=%0d"},
          stage31_compared,input_sample.complete_instr,input_sample.complete_data,
          input_sample.IR,input_sample.IR_Exec,input_sample.IMem_dout,
          input_sample.psr,input_sample.NZP,
          stage50_expected,stage50_actual,stage50_different,any_mismatch), UVM_NONE)
      end
      if (any_mismatch) begin
        stage31_transactions_mismatched++;
        if (stage31_transactions_mismatched <= 15) begin
          `uvm_info("CTRL31_FIRST", $sformatf(
            "sample=%0d expected: pc=%b f=%b d=%b e=%b w=%b br=%b ba=%b%b bm=%b%b mem=%b | actual: pc=%b f=%b d=%b e=%b w=%b br=%b ba=%b%b bm=%b%b mem=%b",
            stage31_compared,
            expected.enable_updatePC, expected.enable_fetch,
            expected.enable_decode, expected.enable_execute,
            expected.enable_writeback, expected.br_taken,
            expected.bypass_alu_1, expected.bypass_alu_2,
            expected.bypass_mem_1, expected.bypass_mem_2, expected.mem_state,
            observed.enable_updatePC, observed.enable_fetch,
            observed.enable_decode, observed.enable_execute,
            observed.enable_writeback, observed.br_taken,
            observed.bypass_alu_1, observed.bypass_alu_2,
            observed.bypass_mem_1, observed.bypass_mem_2, observed.mem_state), UVM_NONE)
        end
      end
    end
  endtask

  virtual function void report_phase(uvm_phase phase);
    int shift;
    int ix;
    int jx;
    int matched_pairs;
    int mismatch_pairs;
    int mismatched_fields;
    int field_counts[11];
    logic [11:0] ex_snap;
    logic [11:0] ac_snap;
    super.report_phase(phase);
    `uvm_info("CTRL34_SUMMARY", $sformatf(
      "samples=%0d instr_completions=%0d actual_decode_on_completion=%0d predicted_decode_on_completion=%0d data_completions=%0d; diagnostic_only=1",
      stage31_compared, stage34_ack_count, stage34_ack_actual_decode,
      stage34_ack_expected_decode, stage34_data_count), UVM_NONE)
    `uvm_info("CTRL31_TOTAL", $sformatf(
      "samples=%0d transactions_with_any_mismatch=%0d", stage31_compared,
      stage31_transactions_mismatched), UVM_NONE)
    for (int unsigned index=0; index<11; index++) begin
      `uvm_info("CTRL31_FIELD", $sformatf(
        "name=%s mismatches=%0d samples=%0d",
        stage31_field_name(index), stage31_field_mismatches[index], stage31_compared), UVM_NONE)
    end

    //stage33 compares prediction at sample i with rtl output at sample i+shift
    //positive shift means the rtl output occurs later than the prediction
    //diagnostic only: no scoreboard transactions are altered or suppressed
    for (shift=-2; shift<=2; shift++) begin
      matched_pairs=0;
      mismatch_pairs=0;
      mismatched_fields=0;
      for (int f=0; f<11; f++) field_counts[f]=0;
      for (ix=0; ix<stage33_expected_samples.size(); ix++) begin
        jx=ix+shift;
        if (jx<0 || jx>=stage33_actual_samples.size()) continue;
        ex_snap=stage33_expected_samples[ix];
        ac_snap=stage33_actual_samples[jx];
        matched_pairs++;
        if (ex_snap !== ac_snap) mismatch_pairs++;
        for (int f=0; f<11; f++) begin
          if (stage33_field_diff(f, ex_snap, ac_snap)) begin
            field_counts[f]++;
            mismatched_fields++;
          end
        end
      end
      `uvm_info("CTRL33_SHIFT", $sformatf(
        "shift=%0d pairs=%0d mismatched_transactions=%0d mismatched_fields=%0d",
        shift, matched_pairs, mismatch_pairs, mismatched_fields), UVM_NONE)
      for (int f=0; f<11; f++) begin
        `uvm_info("CTRL33_FIELD", $sformatf(
          "shift=%0d name=%s mismatches=%0d compared=%0d",
          shift, stage31_field_name(f), field_counts[f], matched_pairs), UVM_NONE)
      end
    end
    `uvm_info("CTRL33_INFO", $sformatf(
      "snapshots_expected=%0d snapshots_actual=%0d shift0_must_match_CTRL31; experiment_does_not_change_scoreboard",
      stage33_expected_samples.size(), stage33_actual_samples.size()), UVM_NONE)
  endfunction

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

