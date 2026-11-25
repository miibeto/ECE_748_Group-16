//----------------------------------------------------------------------
// imem_single_opcode_transaction
//
// Parameterized constrained-random instruction transaction that forces
// Instr_dout[15:12] to a single opcode nibble. Used by directed tests
// that need to drive the design with one opcode at a time for coverage
// closure on hard-to-hit bins.
//----------------------------------------------------------------------

class imem_single_opcode_transaction #(bit [3:0] OPCODE = 4'b0001)
  extends imem_constrained_transaction;

  `uvm_object_param_utils( imem_single_opcode_transaction #(OPCODE) )

  constraint pin_opcode_c {
    Instr_dout[15:12] == OPCODE;
  }

  function new(string name = "imem_single_opcode_transaction");
    super.new(name);
  endfunction

endclass
