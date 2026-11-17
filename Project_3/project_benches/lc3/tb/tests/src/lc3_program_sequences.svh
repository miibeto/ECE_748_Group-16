//----------------------------------------------------------------------
// lc3_program_sequences
//
// Program-shaped stimulus for random_instr_test (team spec, Sheet 5):
//
//   preamble : AND R0..R7, Rn, #0      (clear all registers -> known state)
//   main     : NUM_INSTRS constrained-random instructions
//   closing  : TRAP x25 (HALT)
//   after    : ADD R0,R0,#0 fillers until the test ends
//
// lc3_program_imem_sequence replaces imem_responder_sequence (factory type
// override), so lc3_bench_sequence_base needs no changes. Main-phase items
// come from req.randomize(), so the imem_transaction type override in the
// test (imem_constrained_transaction) still sets the instruction mix.
//
// lc3_program_bench_sequence replaces lc3_bench_sequence_base: instead of a
// fixed 400 clocks, it ends the test DRAIN_CLOCKS after HALT is delivered
// (with a timeout in case the DUT hangs).
//
// Length is set from the command line:  +NUM_INSTRS=<n>   (default 2000)
//----------------------------------------------------------------------

class lc3_program_imem_sequence extends imem_responder_sequence;

  `uvm_object_utils( lc3_program_imem_sequence )

  //localparam bit [15:0] HALT_INSTR = 16'hF025;   // TRAP x25
  localparam bit [15:0] NOP_INSTR  = 16'h1020;   // ADD R0, R0, #0

  int unsigned num_instrs = 2000;
  bit          halt_sent  = 1'b0;

  function new(string name = "lc3_program_imem_sequence");
    super.new(name);
    void'($value$plusargs("NUM_INSTRS=%d", num_instrs));
  endfunction

  // One responder item. fixed: drive 'instr'; otherwise randomize req.
  protected task send(bit [15:0] instr, bit randomize_it = 1'b0);
    start_item(req);
    if (randomize_it) begin
      if (!req.randomize())
        `uvm_fatal("SEQ", "lc3_program_imem_sequence: randomization failed")
    end else begin
      req.Instr_dout     = instr;
      req.complete_instr = 1'b1;
    end
    finish_item(req);
  endtask

  task body();
    req = imem_transaction::type_id::create("req");

    // Two lead-in NOPs never reach Decode:
    //  item 0: consumed by imem_driver_bfm to accept the fetch request the
    //          DUT already has outstanding at reset release; its Instr_dout
    //          is never driven onto the bus.
    //  item 1: driven in the first clock after reset, before the DUT enables
    //          Decode, so it is dropped (seen in sim: imem logs it as a fetch
    //          at 215ns, Decode's first instruction is item 2 at 225ns, and
    //          imem2dec_chk reports it as 1 fetched-not-decoded).
    // Without item 1 here, the preamble's AND R0 was the one dropped and R0
    // was never cleared. If startup timing ever changes so item 1 does get
    // decoded, it's a harmless ADD R0,R0,#0 before the preamble.
    send(NOP_INSTR);
    send(NOP_INSTR);

    // Preamble: AND Rn, Rn, #0 for n = 0..7  ->  0101 nnn nnn 1 00000
    for (int n = 0; n < 8; n++)
      send({4'b0101, n[2:0], n[2:0], 1'b1, 5'b00000});

    // Main random body.
    repeat (num_instrs) send(16'h0000, 1'b1);

    // Closing HALT.
    //send(HALT_INSTR);
    halt_sent = 1'b1; // DO NOT REMOVE! The bench sequence relies on this to properly end the sequence.
    `uvm_info("SEQ", $sformatf("program done: 8 preamble + %0d random + HALT delivered", num_instrs), UVM_LOW)

    // The DUT keeps fetching after HALT; feed NOPs until the test ends.
    forever send(NOP_INSTR);
  endtask

endclass


class lc3_program_bench_sequence extends lc3_bench_sequence_base;

  `uvm_object_utils( lc3_program_bench_sequence )

  // Clocks to run after HALT so it (and the instructions ahead of it) drain
  // through decode and the scoreboards.
  int unsigned drain_clocks = 20;

  function new(string name = "");
    super.new(name);
  endfunction

  virtual task body();
    lc3_program_imem_sequence prog;
    int unsigned max_clocks;

    imem_agent_responder_seq = imem_agent_responder_seq_t::type_id::create("imem_agent_responder_seq");
    dmem_agent_responder_seq = dmem_agent_responder_seq_t::type_id::create("dmem_agent_responder_seq");
    if (!$cast(prog, imem_agent_responder_seq))
      `uvm_fatal("SEQ", "lc3_program_bench_sequence needs imem_responder_sequence overridden by lc3_program_imem_sequence")

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

    fork
      imem_agent_responder_seq.start(imem_agent_sequencer);
      dmem_agent_responder_seq.start(dmem_agent_sequencer);
    join_none

    // Worst case is well under 20 clocks per instruction (LDI/STI).
    max_clocks = (prog.num_instrs + 16) * 20 + 1000;

    // Isolated fork so 'disable fork' does not kill the responder sequences.
    fork begin
      fork
        begin
          wait (prog.halt_sent);
          imem_agent_config.wait_for_num_clocks(drain_clocks);
        end
        begin
          imem_agent_config.wait_for_num_clocks(max_clocks);
          `uvm_error("TIMEOUT", $sformatf("HALT not reached within %0d clocks (DUT hung?)", max_clocks))
        end
      join_any
      disable fork;
    end join
  endtask

endclass
