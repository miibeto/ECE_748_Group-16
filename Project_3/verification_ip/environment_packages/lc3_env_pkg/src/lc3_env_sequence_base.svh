//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//                                          
// DESCRIPTION: This file contains environment level sequences that will
//    be reused from block to top level simulations.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
class lc3_env_sequence_base #( 
      type CONFIG_T
      ) extends uvmf_virtual_sequence_base #(.CONFIG_T(CONFIG_T));


  `uvm_object_param_utils( lc3_env_sequence_base #(
                           CONFIG_T
                           ) );

  
// This lc3_env_sequence_base contains a handle to a lc3_env_configuration object 
// named configuration.  This configuration variable contains a handle to each 
// sequencer within each agent within this environment and any sub-environments.
// The configuration object handle is automatically assigned in the pre_body in the
// base class of this sequence.  The configuration handle is retrieved from the
// virtual sequencer that this sequence is started on.
// Available sequencer handles within the environment configuration:

  // Initiator agent sequencers in lc3_environment:

  // Responder agent sequencers in lc3_environment:
    // configuration.imem_agent_config.sequencer
    // configuration.dmem_agent_config.sequencer

  // Virtual sequencers in sub-environments located in sub-environment configuration
    // configuration.decode_env_config.vsqr
    // configuration.writeback_env_config.vsqr
    // configuration.memaccess_env_config.vsqr
    // configuration.control_env_config.vsqr




// This example shows how to use the environment sequence base for sub-environments
// It can only be used on environments generated with UVMF_2022.3 and later.
// Environment sequences generated with UVMF_2022.1 and earlier do not have the required 
//    environment level virtual sequencer
// typedef decode_env_sequence_base #(
//         .CONFIG_T(decode_env_configuration)
//         ) 
//         decode_env_sequence_base_t;
// rand decode_env_sequence_base_t decode_env_seq;

// typedef writeback_env_sequence_base #(
//         .CONFIG_T(writeback_env_configuration)
//         ) 
//         writeback_env_sequence_base_t;
// rand writeback_env_sequence_base_t writeback_env_seq;

// typedef memaccess_env_sequence_base #(
//         .CONFIG_T(memaccess_env_configuration)
//         ) 
//         memaccess_env_sequence_base_t;
// rand memaccess_env_sequence_base_t memaccess_env_seq;

// typedef control_env_sequence_base #(
//         .CONFIG_T(control_env_configuration)
//         ) 
//         control_env_sequence_base_t;
// rand control_env_sequence_base_t control_env_seq;



  // pragma uvmf custom class_item_additional begin
  // pragma uvmf custom class_item_additional end
  
  function new(string name = "" );
    super.new(name);

//     decode_env_seq = decode_env_sequence_base_t::type_id::create("decode_env_seq");
//     writeback_env_seq = writeback_env_sequence_base_t::type_id::create("writeback_env_seq");
//     memaccess_env_seq = memaccess_env_sequence_base_t::type_id::create("memaccess_env_seq");
//     control_env_seq = control_env_sequence_base_t::type_id::create("control_env_seq");

  endfunction

  virtual task body();

  

//     decode_env_seq.start(configuration.decode_env_config.vsqr);
//     writeback_env_seq.start(configuration.writeback_env_config.vsqr);
//     memaccess_env_seq.start(configuration.memaccess_env_config.vsqr);
//     control_env_seq.start(configuration.control_env_config.vsqr);

  endtask

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

