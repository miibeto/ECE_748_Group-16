//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
// Description: This top level UVM test is the base class for all
//     future tests created for this project.
//
//     This test class contains:
//          Configuration:  The top level configuration for the project.
//          Environment:    The top level environment for the project.
//          Top_level_sequence:  The top level sequence for the project.
//                                        
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//

typedef lc3_env_configuration lc3_env_configuration_t;
typedef lc3_environment lc3_environment_t;

class test_top extends uvmf_test_base #(.CONFIG_T(lc3_env_configuration_t), 
                                        .ENV_T(lc3_environment_t), 
                                        .TOP_LEVEL_SEQ_T(lc3_bench_sequence_base));

  `uvm_component_utils( test_top );


  string interface_names[] = {
    decode_env_decode_in_agent_BFM /* decode_env_decode_in_agent     [0] */ , 
    decode_env_decode_out_agent_BFM /* decode_env_decode_out_agent     [1] */ , 
    writeback_env_writeback_in_agent_BFM /* writeback_env_writeback_in_agent     [2] */ , 
    writeback_env_writeback_out_agent_BFM /* writeback_env_writeback_out_agent     [3] */ , 
    memaccess_env_memaccess_in_agent_BFM /* memaccess_env_memaccess_in_agent     [4] */ , 
    memaccess_env_memaccess_out_agent_BFM /* memaccess_env_memaccess_out_agent     [5] */ , 
    control_env_control_in_agent_BFM /* control_env_control_in_agent     [6] */ , 
    control_env_control_out_agent_BFM /* control_env_control_out_agent     [7] */ , 
    imem_agent_BFM /* imem_agent     [8] */ , 
    dmem_agent_BFM /* dmem_agent     [9] */ 
};

uvmf_active_passive_t interface_activities[] = { 
    PASSIVE /* decode_env_decode_in_agent     [0] */ , 
    PASSIVE /* decode_env_decode_out_agent     [1] */ , 
    PASSIVE /* writeback_env_writeback_in_agent     [2] */ , 
    PASSIVE /* writeback_env_writeback_out_agent     [3] */ , 
    PASSIVE /* memaccess_env_memaccess_in_agent     [4] */ , 
    PASSIVE /* memaccess_env_memaccess_out_agent     [5] */ , 
    PASSIVE /* control_env_control_in_agent     [6] */ , 
    PASSIVE /* control_env_control_out_agent     [7] */ , 
    ACTIVE /* imem_agent     [8] */ , 
    ACTIVE /* dmem_agent     [9] */   };


  // pragma uvmf custom class_item_additional begin
  // pragma uvmf custom class_item_additional end

  // ****************************************************************************
  // FUNCTION: new()
  // This is the standard systemVerilog constructor.  All components are 
  // constructed in the build_phase to allow factory overriding.
  //
  function new( string name = "", uvm_component parent = null );
     super.new( name ,parent );
  endfunction



  // ****************************************************************************
  // FUNCTION: build_phase()
  // The construction of the configuration and environment classes is done in
  // the build_phase of uvmf_test_base.  Once the configuraton and environment
  // classes are built then the initialize call is made to perform the
  // following: 
  //     Monitor and driver BFM virtual interface handle passing into agents
  //     Set the active/passive state for each agent
  // Once this build_phase completes, the build_phase of the environment is
  // executed which builds the agents.
  //
  virtual function void build_phase(uvm_phase phase);
// pragma uvmf custom build_phase_pre_super begin
// pragma uvmf custom build_phase_pre_super end
    super.build_phase(phase);
    // pragma uvmf custom configuration_settings_post_randomize begin
    // pragma uvmf custom configuration_settings_post_randomize end
    configuration.initialize(NA, "uvm_test_top.environment", interface_names, null, interface_activities);
  endfunction

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

