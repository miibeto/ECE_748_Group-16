//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
// pragma uvmf custom header begin
typedef enum bit [3:0] {
  OP_BR   = 4'b0000,
  OP_ADD  = 4'b0001,
  OP_LD   = 4'b0010,
  OP_ST   = 4'b0011,
  OP_JSR  = 4'b0100, // Excluded from standard 5-stage LC-3 RTL
  OP_AND  = 4'b0101,
  OP_LDR  = 4'b0110,
  OP_STR  = 4'b0111,
  OP_RTI  = 4'b1000, // Excluded
  OP_NOT  = 4'b1001,
  OP_LDI  = 4'b1010,
  OP_STI  = 4'b1011,
  OP_JMP  = 4'b1100,
  OP_RES  = 4'b1101, // Reserved / Excluded
  OP_LEA  = 4'b1110,
  OP_TRAP = 4'b1111  // Reserved for Closing (HALT = 16'hF025)
} lc3_opcode_e;

class lc3_rand_instr extends uvm_object;
  `uvm_object_utils(lc3_rand_instr)

  // Randomizable LC-3 instruction fields
  rand lc3_opcode_e opcode;
  rand bit [2:0]    dr;          // Destination / Source register [11:9]
  rand bit [2:0]    sr1;         // Source register 1 [8:6]
  rand bit [2:0]    sr2;         // Source register 2 [2:0]
  rand bit [2:0]    base_r;      // Base register for LDR/STR/JMP [8:6]
  rand bit          imm_mode;    // Mode bit for ADD/AND [5]
  rand bit signed [4:0] imm5;    // 5-bit signed immediate [4:0]
  rand bit [2:0]    nzp;         // Condition flags for BR [11:9]
  rand bit [8:0]    pc_offset9;  // 9-bit PC offset [8:0]
  rand bit signed [5:0] offset6; // 6-bit signed base offset [5:0]

  // State tracking & configuration knobs
  bit prev_is_mem = 0;
  bit avoid_back_to_back_mem = 1; // Set to 0 to stress back-to-back mem ops

  // Assembled 16-bit LC-3 instruction word
  bit [15:0] instr;

  // Additional state tracking & configuration knobs
  bit enable_ctrl_ops        = 1; // 0: Linear random stream (no BR/JMP flushes); 1: Include BR/JMP
  bit avoid_ctrl_hazards     = 1; // 1: Prevent BR/JMP adjacent to mem stalls or other BR/JMPs
  bit avoid_jmp_r0_bug       = 1; // 1: Avoid reading R0 after JMP until R0 is overwritten (DUT R0 writeback bug workaround)
  bit prev_is_ctrl           = 0; // Tracks if previous instruction was BR or JMP
  bit prev_was_jmp           = 0; // Tracks if previous instruction was JMP
  bit r0_dirty               = 0; // Tracks if R0 was corrupted by a prior JMP and not yet overwritten

  function new(string name = "lc3_rand_instr");
    super.new(name);
  endfunction

  // 1. Valid Opcode Distribution (Excludes JSR, RTI, Reserved, TRAP)
  constraint c_valid_opcode {
    opcode dist {
      OP_ADD := 20,
      OP_AND := 20,
      OP_NOT := 10,
      OP_LEA := 10,
      OP_LD  := 8,
      OP_LDR := 8,
      OP_LDI := 6,
      OP_ST  := 8,
      OP_STR := 8,
      OP_STI := 6,
      OP_BR  := 10,
      OP_JMP := 4
    };
  }

  // 2. Prevent back-to-back memory instructions if avoid_back_to_back_mem is active
  constraint c_mem_spacing {
    if (avoid_back_to_back_mem && prev_is_mem) {
      !(opcode inside {OP_LD, OP_LDR, OP_LDI, OP_ST, OP_STR, OP_STI});
    }
  }

  // 3. Branch (BR) Constraints: Avoid NOP branches (nzp=0) and backward infinite loops
  constraint c_branch_safe {
    if (opcode == OP_BR) {
      nzp != 3'b000;
      pc_offset9[8] == 1'b0;             // Positive forward offset only
      pc_offset9 inside {[9'd1 : 9'd6]}; // Small forward hop to stay in Main block
    }
  }

  // 4. Jump (JMP) Constraints: Use R7 (pre-loaded with valid target before JMP)
  constraint c_jmp_safe {
    if (opcode == OP_JMP) {
      base_r == 3'd7;
    }
  }

  // 5. PC-Relative Memory / LEA Constraints: Keep offsets positive and in data range
  constraint c_pcrel_offset {
    if (opcode inside {OP_LD, OP_LDI, OP_ST, OP_STI, OP_LEA}) {
      pc_offset9[8] == 1'b0;
      pc_offset9 inside {[9'd16 : 9'd127]};
    }
  }

  // 6. Base+Offset Memory (LDR/STR) Constraints
  constraint c_base_offset {
    if (opcode inside {OP_LDR, OP_STR}) {
      offset6 inside {[-6'sd8 : 6'sd8]};
    }
  }

  // 7. Optional Control-Flow Gate (Toggle BR/JMP off for pure linear random tests)
  constraint c_ctrl_enable {
    if (!enable_ctrl_ops) {
      !(opcode inside {OP_BR, OP_JMP});
    }
  }

  // 8. Prevent Control-Flow / Stall Collisions & Back-to-Back Branches
  //    - Stops BR/JMP from landing on the stall boundary of a preceding LD/ST
  //    - Stops back-to-back BR/JMP so MAIN_JMP_SETUP (LEA R7, #1) is never flushed
  //    - Prevents a memory op immediately after BR/JMP from stalling during a pipeline flush
  constraint c_ctrl_spacing {
    if (avoid_ctrl_hazards) {
      if (prev_is_mem || prev_is_ctrl) {
        !(opcode inside {OP_BR, OP_JMP});
      }
      if (prev_is_ctrl) {
        !(opcode inside {OP_LD, OP_LDR, OP_LDI, OP_ST, OP_STR, OP_STI});
      }
    }
  }

  // 9. Prevent Overwriting R7 Immediately Before/After JMP Hazards
  //    Keeps R7 clean as a dedicated link/jump register when control ops are enabled
  constraint c_protect_r7 {
    if (enable_ctrl_ops) {
      if (opcode inside {OP_ADD, OP_AND, OP_NOT, OP_LD, OP_LDR, OP_LDI, OP_LEA}) {
        dr != 3'd7;
      }
    }
  }

  // 10. Corner-Case Weighting for 5-bit Signed Immediates (ADD/AND)
  //     Ensures boundary values (-16, -1, 0, +1, +15) hit frequently alongside mid-range values
  constraint c_imm5_corners {
    if ((opcode inside {OP_ADD, OP_AND}) && imm_mode) {
      imm5 dist {
        -5'sd16         := 10, // Min negative (-16)
        [-5'sd15:-5'sd2] := 25,
        -5'sd1          := 15, // All-ones mask (5'b11111) / decrement
         5'sd0          := 15, // Zero / identity
         5'sd1          := 15, // Increment
        [5'sd2:5'sd14]  := 10,
         5'sd15         := 10  // Max positive (+15)
      };
    }
  }

  // 11. Balanced NZP Flag Distribution for BR
  //     Guarantees single-flag (BRn, BRz, BRp), dual-flag, and unconditional (BRnzp) coverage
  constraint c_br_nzp_dist {
    if (opcode == OP_BR) {
      nzp dist {
        3'b100 := 15, // BRn
        3'b010 := 15, // BRz
        3'b001 := 15, // BRp
        3'b110 := 10, // BRnz
        3'b101 := 10, // BRnp
        3'b011 := 10, // BRzp
        3'b111 := 25  // BRnzp
      };
    }
  }

  // 12. Prevent Reading R0 While Dirty From a Prior JMP Until Overwritten
  constraint c_avoid_r0_dirty {
    if (avoid_jmp_r0_bug && r0_dirty) {
      if (opcode inside {OP_ADD, OP_AND, OP_NOT}) {
        sr1 != 3'd0;
      }
      if ((opcode inside {OP_ADD, OP_AND}) && !imm_mode) {
        sr2 != 3'd0;
      }
      if (opcode inside {OP_LDR, OP_STR, OP_JMP}) {
        base_r != 3'd0;
      }
      if (opcode inside {OP_ST, OP_STR, OP_STI}) {
        dr != 3'd0; // Store data source register (bits [11:9])
      }
    }
  }

  // Pack constrained fields into exact 16-bit LC-3 ISA encoding
  function void post_randomize();
    case (opcode)
      OP_ADD, OP_AND: begin
        if (imm_mode)
          instr = {opcode, dr, sr1, 1'b1, imm5};
        else
          instr = {opcode, dr, sr1, 3'b000, sr2};
      end
      OP_NOT: instr = {opcode, dr, sr1, 6'b111111};
      OP_LD, OP_LDI, OP_LEA, OP_ST, OP_STI:
              instr = {opcode, dr, pc_offset9};
      OP_LDR, OP_STR:
              instr = {opcode, dr, base_r, offset6};
      OP_BR:  instr = {opcode, nzp, pc_offset9};
      OP_JMP: instr = {opcode, 3'b000, base_r, 6'b000000};
      default: instr = 16'h0000;
    endcase

    prev_is_mem  = (opcode inside {OP_LD, OP_LDR, OP_LDI, OP_ST, OP_STR, OP_STI});
    prev_is_ctrl = (opcode inside {OP_BR, OP_JMP});
    prev_was_jmp = (opcode == OP_JMP);

    // Track R0 corruption on JMP and clear once a valid writeback overwrites R0
    if (opcode == OP_JMP) begin
      r0_dirty = 1'b1;
    end else if ((opcode inside {OP_ADD, OP_AND, OP_NOT, OP_LD, OP_LDR, OP_LDI, OP_LEA}) &&
                 (dr == 3'd0)) begin
      r0_dirty = 1'b0;
    end
  endfunction
endclass
// pragma uvmf custom header end
//----------------------------------------------------------------------
//
class imem_random_sequence extends imem_sequence_base ;

  `uvm_object_utils( imem_random_sequence )

  // pragma uvmf custom class_item_additional begin
  int unsigned num_random_instrs = 85;
  lc3_rand_instr rand_instr;
  // pragma uvmf custom class_item_additional end
  
  //*****************************************************************
  function new(string name = "");
    super.new(name);
  endfunction: new

  // ****************************************************************************
  // Helper task to serve a single fetch request from the DUT
  // ****************************************************************************
  task send_instr(bit [15:0] instr_word, string phase_tag);
    req = imem_transaction::type_id::create("req");
    start_item(req);
    req.Instr_dout     = instr_word;
    req.complete_instr = 1'b1;
    finish_item(req);
    `uvm_info("SEQ", $sformatf("[%s] PC:0x%04h -> Instr:0x%04h", phase_tag, req.PC, instr_word), UVM_HIGH)
  endtask

  // ****************************************************************************
  // TASK : body()
  // ****************************************************************************
  task body();
    bit [15:0] preamble_q[$];
    rand_instr = lc3_rand_instr::type_id::create("rand_instr");

    // =========================================================================
    // 1. PREAMBLE (Deterministic Register & Pointer Initialization)
    // =========================================================================
    // Ensures R0-R7 contain known non-X values and valid memory base addresses
    // before any randomized LDR/STR/ALU/BR operations execute.
    preamble_q = '{
      16'h5020, // AND R0, R0, #0
      16'h5260, // AND R1, R1, #0
      16'h54A0, // AND R2, R2, #0
      16'h56E0, // AND R3, R3, #0
      16'h5920, // AND R4, R4, #0
      16'h5B60, // AND R5, R5, #0
      16'h5DA0, // AND R6, R6, #0
      16'h5FE0, // AND R7, R7, #0
      16'hE040, // LEA R0, #64   (Valid memory base address in R0)
      16'h5260, // AND R1, R1, #0
      16'h1265, // ADD R1, R1, #5  (R1 = 5)
      16'h54A0, // AND R2, R2, #0
      16'h14AA, // ADD R2, R2, #10 (R2 = 10)
      16'hE650, // LEA R3, #80   (Valid memory base address in R3)
      16'h1842, // ADD R4, R1, R2  (R4 = 15)
      16'h9A7F, // NOT R5, R1      (R5 = ~5)
      16'hEC60, // LEA R6, #96   (Valid memory base address in R6)
      16'hEE01  // LEA R7, #1    (Valid code address in R7, sets NZP)
    };

    foreach (preamble_q[i]) begin
      send_instr(preamble_q[i], "PREAMBLE");
    end

    // =========================================================================
    // 2. MAIN (Constrained Random Instruction Generation)
    // =========================================================================
    repeat (num_random_instrs) begin
      if (!rand_instr.randomize()) begin
        `uvm_fatal("SEQ", "imem_random_sequence::body() - lc3_rand_instr randomization failed")
      end

      // If JMP R7 was generated, load R7 with next sequential PC (PC+1) first
      // so JMP never jumps to unmapped memory or creates an infinite loop.
      if (rand_instr.opcode == OP_JMP) begin
        send_instr(16'hEE01, "MAIN_JMP_SETUP"); // LEA R7, #1 -> R7 = address after JMP
      end

      send_instr(rand_instr.instr, "MAIN_RAND");

      // // This "buffer" is an ADD R0, R0, #0 instruction that is placed in between each Memory Operations to
      // // prevent the DUT from stalling. (This is caused by a bug in the LC-3 DUT, where back-to-back memory
      // // operations cause the DUT to stall and stop sending new sequence items).
      // if (rand_instr.opcode == OP_LD || rand_instr.opcode == OP_ST ||
      //     rand_instr.opcode == OP_LDI || rand_instr.opcode == OP_STI ||
      //     rand_instr.opcode == OP_LDR || rand_instr.opcode == OP_STR) 
      // begin
      //   send_instr(16'h1020, "BUFFER");
      // end
    end

    // =========================================================================
    // 3. CLOSING 
    // =========================================================================
    repeat (8) begin
      send_instr(16'h0E00, "CLOSING_DRAIN");
    end

    // // Serve NOPs for the remainder of the bench sequence
    // forever begin
    //   send_instr(16'h0000, "CLOSING_NOP");
    // end
  endtask

endclass: imem_random_sequence

// pragma uvmf custom external begin
// pragma uvmf custom external end

// //----------------------------------------------------------------------
// // Created with uvmf_gen version 2026.1
// //----------------------------------------------------------------------
// // pragma uvmf custom header begin
// typedef enum bit [3:0] {
//   OP_BR   = 4'b0000,
//   OP_ADD  = 4'b0001,
//   OP_LD   = 4'b0010,
//   OP_ST   = 4'b0011,
//   OP_JSR  = 4'b0100, // Excluded from standard 5-stage LC-3 RTL
//   OP_AND  = 4'b0101,
//   OP_LDR  = 4'b0110,
//   OP_STR  = 4'b0111,
//   OP_RTI  = 4'b1000, // Excluded
//   OP_NOT  = 4'b1001,
//   OP_LDI  = 4'b1010,
//   OP_STI  = 4'b1011,
//   OP_JMP  = 4'b1100,
//   OP_RES  = 4'b1101, // Reserved / Excluded
//   OP_LEA  = 4'b1110,
//   OP_TRAP = 4'b1111  // Reserved for Closing (HALT = 16'hF025)
// } lc3_opcode_e;

// class lc3_rand_instr extends uvm_object;
//   `uvm_object_utils(lc3_rand_instr)

//   // Randomizable LC-3 instruction fields
//   rand lc3_opcode_e opcode;
//   rand bit [2:0]    dr;          // Destination / Source register [11:9]
//   rand bit [2:0]    sr1;         // Source register 1 [8:6]
//   rand bit [2:0]    sr2;         // Source register 2 [2:0]
//   rand bit [2:0]    base_r;      // Base register for LDR/STR/JMP [8:6]
//   rand bit          imm_mode;    // Mode bit for ADD/AND [5]
//   rand bit signed [4:0] imm5;    // 5-bit signed immediate [4:0]
//   rand bit [2:0]    nzp;         // Condition flags for BR [11:9]
//   rand bit [8:0]    pc_offset9;  // 9-bit PC offset [8:0]
//   rand bit signed [5:0] offset6; // 6-bit signed base offset [5:0]

//   // State tracking & configuration knobs
//   bit prev_is_mem = 0;
//   bit avoid_back_to_back_mem = 1; // Set to 0 to stress back-to-back mem ops

//   // Assembled 16-bit LC-3 instruction word
//   bit [15:0] instr;

//   // Additional state tracking & configuration knobs
//   bit enable_ctrl_ops        = 1; // 0: Linear random stream (no BR/JMP flushes); 1: Include BR/JMP
//   bit avoid_ctrl_hazards     = 1; // 1: Prevent BR/JMP adjacent to mem stalls or other BR/JMPs
//   bit prev_is_ctrl           = 0; // Tracks if previous instruction was BR or JMP
//   bit prev_was_jmp           = 0; // Tracks if previous instruction was JMP

//   function new(string name = "lc3_rand_instr");
//     super.new(name);
//   endfunction

//   // 1. Valid Opcode Distribution (Excludes JSR, RTI, Reserved, TRAP)
//   constraint c_valid_opcode {
//     opcode dist {
//       OP_ADD := 20,
//       OP_AND := 20,
//       OP_NOT := 10,
//       OP_LEA := 10,
//       OP_LD  := 8,
//       OP_LDR := 8,
//       OP_LDI := 6,
//       OP_ST  := 8,
//       OP_STR := 8,
//       OP_STI := 6,
//       OP_BR  := 10,
//       OP_JMP := 4
//     };
//   }

//   // 2. Prevent back-to-back memory instructions if avoid_back_to_back_mem is active
//   constraint c_mem_spacing {
//     if (avoid_back_to_back_mem && prev_is_mem) {
//       !(opcode inside {OP_LD, OP_LDR, OP_LDI, OP_ST, OP_STR, OP_STI});
//     }
//   }

//   // 3. Branch (BR) Constraints: Avoid NOP branches (nzp=0) and backward infinite loops
//   constraint c_branch_safe {
//     if (opcode == OP_BR) {
//       nzp != 3'b000;
//       pc_offset9[8] == 1'b0;             // Positive forward offset only
//       pc_offset9 inside {[9'd1 : 9'd6]}; // Small forward hop to stay in Main block
//     }
//   }

//   // 4. Jump (JMP) Constraints: Use R7 (pre-loaded with valid target before JMP)
//   constraint c_jmp_safe {
//     if (opcode == OP_JMP) {
//       base_r == 3'd7;
//     }
//   }

//   // 5. PC-Relative Memory / LEA Constraints: Keep offsets positive and in data range
//   constraint c_pcrel_offset {
//     if (opcode inside {OP_LD, OP_LDI, OP_ST, OP_STI, OP_LEA}) {
//       pc_offset9[8] == 1'b0;
//       pc_offset9 inside {[9'd16 : 9'd127]};
//     }
//   }

//   // 6. Base+Offset Memory (LDR/STR) Constraints
//   constraint c_base_offset {
//     if (opcode inside {OP_LDR, OP_STR}) {
//       offset6 inside {[-6'sd8 : 6'sd8]};
//     }
//   }

//   // 7. Optional Control-Flow Gate (Toggle BR/JMP off for pure linear random tests)
//   constraint c_ctrl_enable {
//     if (!enable_ctrl_ops) {
//       !(opcode inside {OP_BR, OP_JMP});
//     }
//   }

//   // 8. Prevent Control-Flow / Stall Collisions & Back-to-Back Branches
//   //    - Stops BR/JMP from landing on the stall boundary of a preceding LD/ST
//   //    - Stops back-to-back BR/JMP so MAIN_JMP_SETUP (LEA R7, #1) is never flushed
//   //    - Prevents a memory op immediately after BR/JMP from stalling during a pipeline flush
//   constraint c_ctrl_spacing {
//     if (avoid_ctrl_hazards) {
//       if (prev_is_mem || prev_is_ctrl) {
//         !(opcode inside {OP_BR, OP_JMP});
//       }
//       if (prev_is_ctrl) {
//         !(opcode inside {OP_LD, OP_LDR, OP_LDI, OP_ST, OP_STR, OP_STI});
//       }
//     }
//   }

//   // 9. Prevent Overwriting R7 Immediately Before/After JMP Hazards
//   //    Keeps R7 clean as a dedicated link/jump register when control ops are enabled
//   constraint c_protect_r7 {
//     if (enable_ctrl_ops) {
//       if (opcode inside {OP_ADD, OP_AND, OP_NOT, OP_LD, OP_LDR, OP_LDI, OP_LEA}) {
//         dr != 3'd7;
//       }
//     }
//   }

//   // 10. Corner-Case Weighting for 5-bit Signed Immediates (ADD/AND)
//   //     Ensures boundary values (-16, -1, 0, +1, +15) hit frequently alongside mid-range values
//   constraint c_imm5_corners {
//     if ((opcode inside {OP_ADD, OP_AND}) && imm_mode) {
//       imm5 dist {
//         -5'sd16        := 10, // Min negative (-16)
//         [-5'sd15:-5'sd2] := 25,
//         -5'sd1         := 15, // All-ones mask (5'b11111) / decrement
//          5'sd0         := 15, // Zero / identity
//          5'sd1         := 15, // Increment
//         [5'sd2:5'sd14] := 10,
//          5'sd15        := 10  // Max positive (+15)
//       };
//     }
//   }

//   // 11. Balanced NZP Flag Distribution for BR
//   //     Guarantees single-flag (BRn, BRz, BRp), dual-flag, and unconditional (BRnzp) coverage
//   constraint c_br_nzp_dist {
//     if (opcode == OP_BR) {
//       nzp dist {
//         3'b100 := 15, // BRn
//         3'b010 := 15, // BRz
//         3'b001 := 15, // BRp
//         3'b110 := 10, // BRnz
//         3'b101 := 10, // BRnp
//         3'b011 := 10, // BRzp
//         3'b111 := 25  // BRnzp
//       };
//     }
//   }

//   // Pack constrained fields into exact 16-bit LC-3 ISA encoding
//   function void post_randomize();
//     case (opcode)
//       OP_ADD, OP_AND: begin
//         if (imm_mode)
//           instr = {opcode, dr, sr1, 1'b1, imm5};
//         else
//           instr = {opcode, dr, sr1, 3'b000, sr2};
//       end
//       OP_NOT: instr = {opcode, dr, sr1, 6'b111111};
//       OP_LD, OP_LDI, OP_LEA, OP_ST, OP_STI:
//               instr = {opcode, dr, pc_offset9};
//       OP_LDR, OP_STR:
//               instr = {opcode, dr, base_r, offset6};
//       OP_BR:  instr = {opcode, nzp, pc_offset9};
//       OP_JMP: instr = {opcode, 3'b000, base_r, 6'b000000};
//       default: instr = 16'h0000;
//     endcase

//     prev_is_mem = (opcode inside {OP_LD, OP_LDR, OP_LDI, OP_ST, OP_STR, OP_STI});
//     prev_is_ctrl = (opcode inside {OP_BR, OP_JMP});
//   endfunction
// endclass
// // pragma uvmf custom header end
// //----------------------------------------------------------------------
// //
// class imem_random_sequence extends imem_sequence_base ;

//   `uvm_object_utils( imem_random_sequence )

//   // pragma uvmf custom class_item_additional begin
//   int unsigned num_random_instrs = 85;
//   lc3_rand_instr rand_instr;
//   // pragma uvmf custom class_item_additional end
  
//   //*****************************************************************
//   function new(string name = "");
//     super.new(name);
//   endfunction: new

//   // ****************************************************************************
//   // Helper task to serve a single fetch request from the DUT
//   // ****************************************************************************
//   task send_instr(bit [15:0] instr_word, string phase_tag);
//     req = imem_transaction::type_id::create("req");
//     start_item(req);
//     req.Instr_dout     = instr_word;
//     req.complete_instr = 1'b1;
//     finish_item(req);
//     `uvm_info("SEQ", $sformatf("[%s] PC:0x%04h -> Instr:0x%04h", phase_tag, req.PC, instr_word), UVM_HIGH)
//   endtask

//   // ****************************************************************************
//   // TASK : body()
//   // ****************************************************************************
//   task body();
//     bit [15:0] preamble_q[$];
//     rand_instr = lc3_rand_instr::type_id::create("rand_instr");

//     // =========================================================================
//     // 1. PREAMBLE (Deterministic Register & Pointer Initialization)
//     // =========================================================================
//     // Ensures R0-R7 contain known non-X values and valid memory base addresses
//     // before any randomized LDR/STR/ALU/BR operations execute.
//     preamble_q = '{
//       16'h5020, // AND R0, R0, #0
//       16'h5260, // AND R1, R1, #0
//       16'h54A0, // AND R2, R2, #0
//       16'h56E0, // AND R3, R3, #0
//       16'h5920, // AND R4, R4, #0
//       16'h5B60, // AND R5, R5, #0
//       16'h5DA0, // AND R6, R6, #0
//       16'h5FE0, // AND R7, R7, #0
//       16'hE040, // LEA R0, #64   (Valid memory base address in R0)
//       16'h5260, // AND R1, R1, #0
//       16'h1265, // ADD R1, R1, #5  (R1 = 5)
//       16'h54A0, // AND R2, R2, #0
//       16'h14AA, // ADD R2, R2, #10 (R2 = 10)
//       16'hE650, // LEA R3, #80   (Valid memory base address in R3)
//       16'h1842, // ADD R4, R1, R2  (R4 = 15)
//       16'h9A7F, // NOT R5, R1      (R5 = ~5)
//       16'hEC60, // LEA R6, #96   (Valid memory base address in R6)
//       16'hEE01  // LEA R7, #1    (Valid code address in R7, sets NZP)
//     };

//     foreach (preamble_q[i]) begin
//       send_instr(preamble_q[i], "PREAMBLE");
//     end

//     // =========================================================================
//     // 2. MAIN (Constrained Random Instruction Generation)
//     // =========================================================================
//     repeat (num_random_instrs) begin
//       if (!rand_instr.randomize()) begin
//         `uvm_fatal("SEQ", "imem_random_sequence::body() - lc3_rand_instr randomization failed")
//       end

//       // If JMP R7 was generated, load R7 with next sequential PC (PC+1) first
//       // so JMP never jumps to unmapped memory or creates an infinite loop.
//       if (rand_instr.opcode == OP_JMP) begin
//         send_instr(16'hEE01, "MAIN_JMP_SETUP"); // LEA R7, #1 -> R7 = address after JMP
//       end

//       send_instr(rand_instr.instr, "MAIN_RAND");

//       // // This "buffer" is an ADD R0, R0, #0 instruction that is placed in between each Memory Operations to
//       // // prevent the DUT from stalling. (This is caused by a bug in the LC-3 DUT, where back-to-back memory
//       // // operations cause the DUT to stall and stop sending new sequence items).
//       // if (rand_instr.opcode == OP_LD || rand_instr.opcode == OP_ST ||
//       //     rand_instr.opcode == OP_LDI || rand_instr.opcode == OP_STI ||
//       //     rand_instr.opcode == OP_LDR || rand_instr.opcode == OP_STR) 
//       // begin
//       //   send_instr(16'h1020, "BUFFER");
//       // end
//     end

//     // =========================================================================
//     // 3. CLOSING 
//     // =========================================================================
//     repeat (8) begin
//       send_instr(16'h0E00, "CLOSING_DRAIN");
//     end

//     // // Serve NOPs for the remainder of the bench sequence
//     // forever begin
//     //   send_instr(16'h0000, "CLOSING_NOP");
//     // end
//   endtask

// endclass: imem_random_sequence

// // pragma uvmf custom external begin
// // pragma uvmf custom external end



// //----------------------------------------------------------------------
// // Created with uvmf_gen version 2026.1
// //----------------------------------------------------------------------
// // pragma uvmf custom header begin
// // pragma uvmf custom header end
// //----------------------------------------------------------------------
// //----------------------------------------------------------------------
// //     
// // DESCRIPTION: 
// // This sequences randomizes the imem transaction and sends it 
// // to the UVM driver.
// //
// // This sequence constructs and randomizes a imem_transaction.
// // 
// //----------------------------------------------------------------------
// //----------------------------------------------------------------------
// //
// class imem_random_sequence 
//   extends imem_sequence_base ;

//   `uvm_object_utils( imem_random_sequence )

//   // pragma uvmf custom class_item_additional begin
//   // pragma uvmf custom class_item_additional end
  
//   //*****************************************************************
//   function new(string name = "");
//     super.new(name);
//   endfunction: new

//   // ****************************************************************************
//   // TASK : body()
//   // This task is automatically executed when this sequence is started using the 
//   // start(sequencerHandle) task.
//   //
//   task body();
  
//       // Construct the transaction
//       req=imem_transaction::type_id::create("req");
//       start_item(req);
//       // Randomize the transaction
//       if(!req.randomize()) `uvm_fatal("SEQ", "imem_random_sequence::body()-imem_transaction randomization failed")
//       // Send the transaction to the imem_driver_bfm via the sequencer and imem_driver.
//       finish_item(req);
//       `uvm_info("SEQ", {"Response:",req.convert2string()},UVM_MEDIUM)

//   endtask

// endclass: imem_random_sequence

// pragma uvmf custom external begin
// pragma uvmf custom external end

