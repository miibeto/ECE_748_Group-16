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

class memaccess_environment  extends uvmf_environment_base #(
    .CONFIG_T( memaccess_env_configuration 
  ));
  `uvm_component_utils( memaccess_environment )





  typedef memaccess_in_agent  memaccess_in_agent_t;
  memaccess_in_agent_t memaccess_in_agent;

  typedef memaccess_out_agent  memaccess_out_agent_t;
  memaccess_out_agent_t memaccess_out_agent;




  typedef memaccess_predictor #(
                .CONFIG_T(CONFIG_T)
                )
 memaccess_pred_t;
  memaccess_pred_t memaccess_pred;

  typedef uvmf_in_order_scoreboard #(.T(memaccess_out_transaction))  memaccess_sb_t;
  memaccess_sb_t memaccess_sb;



  typedef uvmf_virtual_sequencer_base #(.CONFIG_T(memaccess_env_configuration)) memaccess_vsqr_t;
  memaccess_vsqr_t vsqr;

  // pragma uvmf custom class_item_additional begin
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
    memaccess_in_agent = memaccess_in_agent_t::type_id::create("memaccess_in_agent",this);
    memaccess_in_agent.set_config(configuration.memaccess_in_agent_config);
    memaccess_out_agent = memaccess_out_agent_t::type_id::create("memaccess_out_agent",this);
    memaccess_out_agent.set_config(configuration.memaccess_out_agent_config);
    memaccess_pred = memaccess_pred_t::type_id::create("memaccess_pred",this);
    memaccess_pred.configuration = configuration;
    memaccess_sb = memaccess_sb_t::type_id::create("memaccess_sb",this);

    vsqr = memaccess_vsqr_t::type_id::create("vsqr", this);
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
    memaccess_in_agent.monitored_ap.connect(memaccess_pred.memaccess_in_agent_ae);
    memaccess_pred.memaccess_sb_ap.connect(memaccess_sb.expected_analysis_export);
    memaccess_out_agent.monitored_ap.connect(memaccess_sb.actual_analysis_export);
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
     configuration.memaccess_configuration_cg.sample();
  endfunction

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

