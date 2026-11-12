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

  constraint not_operands_c {
    (Instr_dout[15:12] == 4'b1001) -> Instr_dout[5:0] == 6'b111111;
  }

  function new(string name = "imem_constrained_transaction");
    super.new(name);
  endfunction

endclass
