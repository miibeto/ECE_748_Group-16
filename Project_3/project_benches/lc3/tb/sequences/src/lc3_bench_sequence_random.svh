

class lc3_bench_sequence_random extends lc3_bench_sequence_base;

  `uvm_object_utils( lc3_bench_sequence_random  );

    // UVMF_CHANGE_ME : Instantiate, construct, and start sequences as needed to create stimulus scenarios.
  // Instantiate sequences here
  typedef dmem_responder_sequence  dmem_agent_responder_seq_t;
  dmem_agent_responder_seq_t dmem_agent_responder_seq;

  // Replace standard responder sequence with custom startup responder sequence
  typedef imem_random_sequence imem_agent_responder_seq_t;
  imem_agent_responder_seq_t imem_agent_responder_seq;

  function new(string name = "lc3_bench_sequence_random" );
    super.new(name);
  endfunction

  // ****************************************************************************
  virtual task body();
    // pragma uvmf custom body begin

    // Construct sequences here

    // lc3_env_seq = lc3_env_sequence_base_t::type_id::create("lc3_env_seq");

    imem_agent_responder_seq  = imem_agent_responder_seq_t::type_id::create("imem_agent_responder_seq");
    dmem_agent_responder_seq  = dmem_agent_responder_seq_t::type_id::create("dmem_agent_responder_seq");
    fork
      decode_env_decode_in_agent_config.wait_for_reset();
      decode_env_decode_out_agent_config.wait_for_reset();
      writeback_env_writeback_in_agent_config.wait_for_reset();
      writeback_env_writeback_out_agent_config.wait_for_reset();
      memaccess_env_memaccess_in_agent_config.wait_for_reset();
      memaccess_env_memaccess_out_agent_config.wait_for_reset();
      control_env_control_in_agent_config.wait_for_reset();
      control_env_control_out_agent_config.wait_for_reset();
      imem_agent_config.wait_for_reset();
      dmem_agent_config.wait_for_reset();
    join
    // Start RESPONDER sequences here
    fork
      imem_agent_responder_seq.start(imem_agent_sequencer);
      dmem_agent_responder_seq.start(dmem_agent_sequencer);
    join_none
    // Start INITIATOR sequences here
    fork
    join

// lc3_env_seq.start(top_configuration.vsqr);

    // UVMF_CHANGE_ME : Extend the simulation XXX number of clocks after 
    // the last sequence to allow for the last sequence item to flow 
    // through the design.
    fork
      decode_env_decode_in_agent_config.wait_for_num_clocks(400);
      decode_env_decode_out_agent_config.wait_for_num_clocks(400);
      writeback_env_writeback_in_agent_config.wait_for_num_clocks(400);
      writeback_env_writeback_out_agent_config.wait_for_num_clocks(400);
      memaccess_env_memaccess_in_agent_config.wait_for_num_clocks(400);
      memaccess_env_memaccess_out_agent_config.wait_for_num_clocks(400);
      control_env_control_in_agent_config.wait_for_num_clocks(400);
      control_env_control_out_agent_config.wait_for_num_clocks(400);
      imem_agent_config.wait_for_num_clocks(400);
      dmem_agent_config.wait_for_num_clocks(400);
    join

    // pragma uvmf custom body end
  endtask

endclass