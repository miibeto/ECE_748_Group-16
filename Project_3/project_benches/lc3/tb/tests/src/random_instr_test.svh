//----------------------------------------------------------------------
// random_instr_test
//
// Main stimulus test for LC3 coverage closure (the only test in the
// default regression). Factory overrides:
//   imem_transaction        -> imem_constrained_transaction (legal LC3 mix)
//   imem_responder_sequence -> lc3_program_imem_sequence (preamble, random
//                              body, closing HALT; see lc3_program_sequences)
//   lc3_bench_sequence_base -> lc3_program_bench_sequence (ends after HALT)
//
// Program length: +NUM_INSTRS=<n> (default 2000).
//----------------------------------------------------------------------

class random_instr_test extends lc3_checked_test;

  `uvm_component_utils( random_instr_test )

  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    imem_transaction::type_id::set_type_override(
        imem_constrained_transaction::get_type());
    imem_responder_sequence::type_id::set_type_override(
        lc3_program_imem_sequence::get_type());
    lc3_bench_sequence_base::type_id::set_type_override(
        lc3_program_bench_sequence::get_type());
    super.build_phase(phase);
  endfunction

endclass
