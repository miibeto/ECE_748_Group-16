//----------------------------------------------------------------------
// random_instr_test
//
// Default stimulus test for LC3 coverage closure. Uses a factory type
// override to replace imem_transaction with imem_constrained_transaction
// so the imem responder sequence generates legal LC3 opcodes instead of
// pure random 16-bit values.
//----------------------------------------------------------------------

class random_instr_test extends test_top;

  `uvm_component_utils( random_instr_test )

  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    lc3_bench_sequence_base::type_id::set_type_override(lc3_bench_sequence_random::get_type());
    super.build_phase(phase);
  endfunction

endclass
