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

  // Pick the opcode FIRST, uniformly. Without this the solver is uniform
  // over all legal 16-bit encodings, so opcodes with few legal encodings
  // (JMP: 8, NOT: 64, TRAP: 256 vs ADD/AND: thousands) almost never appear.
  rand bit [3:0] opcode;
  constraint opcode_link_c {
    Instr_dout[15:12] == opcode;
    solve opcode before Instr_dout;
  }

  // Corner-value weighting for PCoffset9 (LD/ST/LDI/STI/LEA). Uniform random
  // hits offset 0 only 1/512 of the time; weight 0, -1, +255, -256 so the
  // zero bin and the range extremes are reached in a single short test.
  constraint pc9_corner_c {
    (opcode inside {4'b0010, 4'b0011, 4'b1010, 4'b1011, 4'b1110}) ->
      Instr_dout[8:0] dist { 9'h000 := 8,              // 0
                             9'h1FF := 4,              // -1
                             9'h0FF := 4,              // +255
                             9'h100 := 4,              // -256
                             [9'h001:9'h0FE] :/ 40,    // +1..+254
                             [9'h101:9'h1FE] :/ 40 };  // -255..-2
  }

  // JSR vs JSRR 50/50. JSR (bit11=1) has 2048 legal encodings but JSRR only
  // 8, so without this JSRR is practically never generated.
  constraint jsr_mode_split_c {
    (opcode == 4'b0100) -> Instr_dout[11] dist { 1'b0 := 1, 1'b1 := 1 };
  }

  // Corner-value weighting for offset6 (LDR/STR): 0, -1, +31, -32.
  constraint off6_corner_c {
    (opcode inside {4'b0110, 4'b0111}) ->
      Instr_dout[5:0] dist { 6'h00 := 8,              // 0
                             6'h3F := 4,              // -1
                             6'h1F := 4,              // +31
                             6'h20 := 4,              // -32
                             [6'h01:6'h1E] :/ 40,     // +1..+30
                             [6'h21:6'h3E] :/ 40 };   // -31..-2
  }

  // Corner-value weighting for imm5 (ADD/AND immediate mode): 0, -1, +15, -16.
  constraint imm5_corner_c {
    ((opcode inside {4'b0001, 4'b0101}) && Instr_dout[5] == 1'b1) ->
      Instr_dout[4:0] dist { 5'h00 := 8,              // 0
                             5'h1F := 4,              // -1
                             5'h0F := 4,              // +15
                             5'h10 := 4,              // -16
                             [5'h01:5'h0E] :/ 40,     // +1..+14
                             [5'h11:5'h1E] :/ 40 };   // -15..-2
  }

  // Opcode field helpers: Instr_dout[15:12] is the LC3 opcode.
  constraint legal_opcode_c {
    !(Instr_dout[15:12] inside {4'b1000, 4'b1101, 4'b1111});
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
