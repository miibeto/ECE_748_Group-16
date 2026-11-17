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
class TEST_NAME extends lc3_checked_test; \
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
//`LC3_DIRECTED_OPCODE_TEST(jsr_test , 4'b0100)
`LC3_DIRECTED_OPCODE_TEST(and_test , 4'b0101)
`LC3_DIRECTED_OPCODE_TEST(ldr_test , 4'b0110)
`LC3_DIRECTED_OPCODE_TEST(str_test , 4'b0111)
`LC3_DIRECTED_OPCODE_TEST(not_test , 4'b1001)
`LC3_DIRECTED_OPCODE_TEST(ldi_test , 4'b1010)
`LC3_DIRECTED_OPCODE_TEST(sti_test , 4'b1011)
`LC3_DIRECTED_OPCODE_TEST(jmp_test , 4'b1100)
`LC3_DIRECTED_OPCODE_TEST(lea_test , 4'b1110)
//`LC3_DIRECTED_OPCODE_TEST(trap_test, 4'b1111)

//----------------------------------------------------------------------
// Mode-change / cross-bin directed tests
//
// Pin a single opcode AND a mode bit so the opcode x mode crosses close
// deterministically. Each uses a locally-declared transaction extension
// of imem_single_opcode_transaction that adds the mode constraint.
//----------------------------------------------------------------------

// ADD immediate mode: opcode=ADD, Instr_dout[5]==1
class imem_tx_add_imm extends imem_single_opcode_transaction #(4'b0001);
  `uvm_object_utils(imem_tx_add_imm)
  constraint add_imm_c { Instr_dout[5] == 1'b1; }
  function new(string name = "imem_tx_add_imm"); super.new(name); endfunction
endclass

// ADD register mode: opcode=ADD, Instr_dout[5]==0, bits[4:3]==00
class imem_tx_add_reg extends imem_single_opcode_transaction #(4'b0001);
  `uvm_object_utils(imem_tx_add_reg)
  constraint add_reg_c { Instr_dout[5] == 1'b0; Instr_dout[4:3] == 2'b00; }
  function new(string name = "imem_tx_add_reg"); super.new(name); endfunction
endclass

// AND immediate mode
class imem_tx_and_imm extends imem_single_opcode_transaction #(4'b0101);
  `uvm_object_utils(imem_tx_and_imm)
  constraint and_imm_c { Instr_dout[5] == 1'b1; }
  function new(string name = "imem_tx_and_imm"); super.new(name); endfunction
endclass

// AND register mode
class imem_tx_and_reg extends imem_single_opcode_transaction #(4'b0101);
  `uvm_object_utils(imem_tx_and_reg)
  constraint and_reg_c { Instr_dout[5] == 1'b0; Instr_dout[4:3] == 2'b00; }
  function new(string name = "imem_tx_and_reg"); super.new(name); endfunction
endclass

// BR with every non-zero NZP combination (001..111). Forces each br_nzp bin.
class imem_tx_br_all_nzp extends imem_single_opcode_transaction #(4'b0000);
  `uvm_object_utils(imem_tx_br_all_nzp)
  constraint br_nzp_c { Instr_dout[11:9] inside {3'b001, 3'b010, 3'b011,
                                                 3'b100, 3'b101, 3'b110,
                                                 3'b111}; }
  function new(string name = "imem_tx_br_all_nzp"); super.new(name); endfunction
endclass

// JSR mode: opcode=JSR (0x4), Instr_dout[11]==1
class imem_tx_jsr_mode extends imem_single_opcode_transaction #(4'b0100);
  `uvm_object_utils(imem_tx_jsr_mode)
  constraint jsr_c { Instr_dout[11] == 1'b1; }
  function new(string name = "imem_tx_jsr_mode"); super.new(name); endfunction
endclass

// JSRR mode: opcode=JSR (0x4), Instr_dout[11]==0, bits[10:9]==0, bits[5:0]==0
class imem_tx_jsrr_mode extends imem_single_opcode_transaction #(4'b0100);
  `uvm_object_utils(imem_tx_jsrr_mode)
  constraint jsrr_c { Instr_dout[11]  == 1'b0;
                      Instr_dout[10:9] == 2'b00;
                      Instr_dout[5:0]  == 6'b000000; }
  function new(string name = "imem_tx_jsrr_mode"); super.new(name); endfunction
endclass

`define LC3_DIRECTED_MODE_TEST(TEST_NAME, TX_T) \
class TEST_NAME extends lc3_checked_test; \
  `uvm_component_utils( TEST_NAME ) \
  function new(string name = "", uvm_component parent = null); \
    super.new(name, parent); \
  endfunction \
  virtual function void build_phase(uvm_phase phase); \
    imem_transaction::type_id::set_type_override( TX_T::get_type() ); \
    super.build_phase(phase); \
  endfunction \
endclass

`LC3_DIRECTED_MODE_TEST(add_imm_mode_test , imem_tx_add_imm)
`LC3_DIRECTED_MODE_TEST(add_reg_mode_test , imem_tx_add_reg)
`LC3_DIRECTED_MODE_TEST(and_imm_mode_test , imem_tx_and_imm)
`LC3_DIRECTED_MODE_TEST(and_reg_mode_test , imem_tx_and_reg)
`LC3_DIRECTED_MODE_TEST(br_all_nzp_test   , imem_tx_br_all_nzp)
`LC3_DIRECTED_MODE_TEST(jsr_mode_test     , imem_tx_jsr_mode)
`LC3_DIRECTED_MODE_TEST(jsrr_mode_test    , imem_tx_jsrr_mode)
