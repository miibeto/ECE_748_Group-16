//----------------------------------------------------------------------
// imem_constrained_transaction
//
// Extends the UVMF-generated imem_transaction with a constraint that
// forces Instr_dout to be a legal LC3 instruction. The base RTI and
// RESERVED opcodes (0x8, 0xD) are excluded by default because the LC3
// RTL treats them as illegal, and NOT (opcode 0x9) must have bits [5:0]
// equal to 6'b111111.
//
// Tests apply a UVM factory type_override to swap this class in for
// imem_transaction so the responder sequence generates legal opcodes.
//----------------------------------------------------------------------

class imem_constrained_transaction extends imem_transaction;

  `uvm_object_utils( imem_constrained_transaction )

  // Opcode field helpers: Instr_dout[15:12] is the LC3 opcode.
  constraint legal_opcode_c {
    !(Instr_dout[15:12] inside {4'b1000, 4'b1101});
  }

  // NOT (0x9): bits[5:0] must be 6'b111111.
  constraint not_operands_c {
    (Instr_dout[15:12] == 4'b1001) -> Instr_dout[5:0] == 6'b111111;
  }

  // ADD/AND register-mode: bits[4:3] must be 2'b00 when imm-mode bit is 0.
  constraint add_and_reg_mode_c {
    ( (Instr_dout[15:12] inside {4'b0001, 4'b0101}) && Instr_dout[5] == 1'b0 )
      -> Instr_dout[4:3] == 2'b00;
  }

  // BR (0x0): NZP (bits[11:9]) must not be 000 (otherwise the branch is a
  // no-op / unreachable bin). If NZP == 111 (unconditional branch), the
  // 9-bit PC offset must not be -1, to prevent an infinite self-loop.
  constraint br_nzp_nonzero_c {
    (Instr_dout[15:12] == 4'b0000) -> Instr_dout[11:9] != 3'b000;
  }
  constraint br_no_infinite_loop_c {
    ( (Instr_dout[15:12] == 4'b0000) && Instr_dout[11:9] == 3'b111 )
      -> Instr_dout[8:0] != 9'h1FF;  // -1 in 9-bit two's complement
  }

  // JMP (0xC): bits[11:9] must be 000 and bits[5:0] must be 000000.
  // (RET is JMP with BaseR==7; left reachable via the random stimulus.)
  constraint jmp_fields_c {
    (Instr_dout[15:12] == 4'b1100) -> ( Instr_dout[11:9] == 3'b000
                                     && Instr_dout[5:0]  == 6'b000000 );
  }

  // JSR / JSRR (0x4): when bit[11]==0 (JSRR), bits[10:9] and bits[5:0]
  // must be zeroed per Sheet 5. JSR (bit[11]==1) leaves [10:0] as offset.
  constraint jsrr_fields_c {
    ( (Instr_dout[15:12] == 4'b0100) && Instr_dout[11] == 1'b0 )
      -> ( Instr_dout[10:9] == 2'b00 && Instr_dout[5:0] == 6'b000000 );
  }

  // TRAP (0xF): bits[11:8] must be 0; vector is chosen by test. Leave the
  // vector unconstrained here so directed tests can override to x25 (HALT).
  constraint trap_fields_c {
    (Instr_dout[15:12] == 4'b1111) -> Instr_dout[11:8] == 4'b0000;
  }

  function new(string name = "imem_constrained_transaction");
    super.new(name);
  endfunction

endclass
