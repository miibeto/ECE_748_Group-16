//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
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

class lc3_environment  extends uvmf_environment_base #(
    .CONFIG_T( lc3_env_configuration 
  ));
  `uvm_component_utils( lc3_environment )

  typedef decode_environment decode_env_t;
  decode_env_t decode_env;
   
  typedef writeback_environment writeback_env_t;
  writeback_env_t writeback_env;
   
  typedef memaccess_environment memaccess_env_t;
  memaccess_env_t memaccess_env;
   
  typedef control_environment control_env_t;
  control_env_t control_env;
   




  typedef imem_agent  imem_agent_t;
  imem_agent_t imem_agent;

  typedef dmem_agent  dmem_agent_t;
  dmem_agent_t dmem_agent;




  typedef lc3_predictor #(
                .CONFIG_T(CONFIG_T)
                )
 lc3_pred_t;
  lc3_pred_t lc3_pred;

  typedef uvmf_in_order_scoreboard #(.T(dmem_transaction))  lc3_sb_t;
  lc3_sb_t lc3_sb;
  //stage74:explicit memory-free program contract
  bit stage74_no_dmem_expected;
  string stage74_program;



  typedef uvmf_virtual_sequencer_base #(.CONFIG_T(lc3_env_configuration)) lc3_vsqr_t;
  lc3_vsqr_t vsqr;

  // pragma uvmf custom class_item_additional begin
  //allow a memoryless program to have zero predictions and zero observations.
  //all expected/actual comparisons and non-empty checks remain enabled.
  bit stage48_zero_memory_program = 0;
  string stage48_imem_program = "smoke";
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
    decode_env = decode_env_t::type_id::create("decode_env",this);
    decode_env.set_config(configuration.decode_env_config);
    writeback_env = writeback_env_t::type_id::create("writeback_env",this);
    writeback_env.set_config(configuration.writeback_env_config);
    memaccess_env = memaccess_env_t::type_id::create("memaccess_env",this);
    memaccess_env.set_config(configuration.memaccess_env_config);
    control_env = control_env_t::type_id::create("control_env",this);
    control_env.set_config(configuration.control_env_config);
    imem_agent = imem_agent_t::type_id::create("imem_agent",this);
    imem_agent.set_config(configuration.imem_agent_config);
    dmem_agent = dmem_agent_t::type_id::create("dmem_agent",this);
    dmem_agent.set_config(configuration.dmem_agent_config);
    lc3_pred = lc3_pred_t::type_id::create("lc3_pred",this);
    lc3_pred.configuration = configuration;
    lc3_sb = lc3_sb_t::type_id::create("lc3_sb",this);

    //the uvmf activity check assumes every test must generate a memory transaction.
    //alu/branch/jmp programs must instead prove zero predicted and observed memory ops.
    void'($value$plusargs("IMEM_PROGRAM=%s", stage48_imem_program));
    stage48_zero_memory_program =
      (stage48_imem_program == "alu") ||
      (stage48_imem_program == "branch") ||
      (stage48_imem_program == "jump");
    if (stage48_zero_memory_program)
      lc3_sb.disable_end_of_test_activity_check();
    `uvm_info("STAGE48_EMPTY_SCBD", $sformatf(
      "program=%s zero_memory_expected=%0d activity_check_enabled=%0d comparison_enabled=%0d empty_check_enabled=%0d",
      stage48_imem_program, stage48_zero_memory_program,
      lc3_sb.end_of_test_activity_check,
      !lc3_sb.disable_entry_compare,
      lc3_sb.end_of_test_empty_check), UVM_NONE)

    vsqr = lc3_vsqr_t::type_id::create("vsqr", this);
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
    imem_agent.monitored_ap.connect(lc3_pred.imem_agent_ae);
    dmem_agent.monitored_ap.connect(lc3_pred.dmem_agent_ae);
    lc3_pred.lc3_sb_ap.connect(lc3_sb.expected_analysis_export);
    dmem_agent.monitored_ap.connect(lc3_sb.actual_analysis_export);
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
     configuration.lc3_configuration_cg.sample();
     void'($value$plusargs("IMEM_PROGRAM=%s", stage74_program));
     stage74_no_dmem_expected = (stage74_program == "cov72_alu" ||
                                 stage74_program == "cov72_jump");
     if (stage74_no_dmem_expected) begin
       //zero transactions is the expected result, not missing verification
       lc3_sb.disable_end_of_test_activity_check();
     end
  endfunction

  //the empty-scoreboard activity check is inappropriate only for memoryless tests.
  //check the explicit architectural counters instead of accepting nonzero traffic.
  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (stage48_zero_memory_program) begin
      if (lc3_pred.predicted_mem_ops != 0 ||
          lc3_pred.observed_mem_ops != 0 ||
          lc3_sb.transaction_count != 0 ||
          lc3_sb.nothing_to_compare_against_count != 0 ||
          lc3_sb.mismatch_count != 0 ||
          lc3_sb.match_count != 0) begin
        `uvm_error("STAGE48_ZERO_MEM_FAIL", $sformatf(
          "program=%s expected=%0d observed=%0d scoreboard_predictions=%0d no_expected=%0d matches=%0d mismatches=%0d",
          stage48_imem_program, lc3_pred.predicted_mem_ops,
          lc3_pred.observed_mem_ops, lc3_sb.transaction_count,
          lc3_sb.nothing_to_compare_against_count,
          lc3_sb.match_count, lc3_sb.mismatch_count))
      end else begin
        `uvm_info("STAGE48_ZERO_MEM_OK", $sformatf(
          "program=%s expected=0 observed=0 scoreboard_predictions=0",
          stage48_imem_program), UVM_NONE)
      end
    end
    if (stage74_no_dmem_expected) begin
      //preserve comparisons and pending-entry checks; reject any memory activity
      if (lc3_sb.transaction_count != 0 || lc3_sb.match_count != 0 ||
          lc3_sb.mismatch_count != 0 || lc3_sb.nothing_to_compare_against_count != 0)
        `uvm_error("STAGE74_NO_DMEM", $sformatf("%s unexpected memory activity predicted=%0d matches=%0d mismatches=%0d unexpected_actual=%0d", stage74_program, lc3_sb.transaction_count, lc3_sb.match_count, lc3_sb.mismatch_count, lc3_sb.nothing_to_compare_against_count))
      else
        `uvm_info("STAGE74_NO_DMEM", $sformatf("%s PASS zero memory transactions", stage74_program), UVM_LOW)
    end
  endfunction

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

