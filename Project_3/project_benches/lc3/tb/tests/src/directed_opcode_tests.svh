//----------------------------------------------------------------------
// directed_opcode_tests
//
// One test per LC3 opcode. Each uses a factory type_override to force
// the imem responder sequence to emit transactions pinned to a single
// opcode nibble. Running all of these in a regression guarantees every
// opcode bin in imem_transaction_cg is hit, which closes the primary
// instruction-coverage metric for Project 3.
//
// Tests extend test_top so they inherit the full environment, interface
// list, and lc3_bench_sequence_base behavior; only the stimulus
// transaction type is changed.
//----------------------------------------------------------------------

`define LC3_DIRECTED_OPCODE_TEST(TEST_NAME, OPCODE_VAL) \
class TEST_NAME extends test_top; \
  `uvm_component_utils( TEST_NAME ) \
  typedef imem_single_opcode_transaction #( OPCODE_VAL ) tx_t; \
  function new(string name = "", uvm_component parent = null); \
    super.new(name, parent); \
  endfunction \
  virtual function void build_phase(uvm_phase phase); \
    imem_transaction::type_id::set_type_override( tx_t::get_type() ); \
    super.build_phase(phase); \
  endfunction \
endclass

`LC3_DIRECTED_OPCODE_TEST(br_test  , 4'b0000)
`LC3_DIRECTED_OPCODE_TEST(add_test , 4'b0001)
`LC3_DIRECTED_OPCODE_TEST(ld_test  , 4'b0010)
`LC3_DIRECTED_OPCODE_TEST(st_test  , 4'b0011)
`LC3_DIRECTED_OPCODE_TEST(jsr_test , 4'b0100)
`LC3_DIRECTED_OPCODE_TEST(and_test , 4'b0101)
`LC3_DIRECTED_OPCODE_TEST(ldr_test , 4'b0110)
`LC3_DIRECTED_OPCODE_TEST(str_test , 4'b0111)
`LC3_DIRECTED_OPCODE_TEST(not_test , 4'b1001)
`LC3_DIRECTED_OPCODE_TEST(ldi_test , 4'b1010)
`LC3_DIRECTED_OPCODE_TEST(sti_test , 4'b1011)
`LC3_DIRECTED_OPCODE_TEST(jmp_test , 4'b1100)
`LC3_DIRECTED_OPCODE_TEST(lea_test , 4'b1110)
`LC3_DIRECTED_OPCODE_TEST(trap_test, 4'b1111)
