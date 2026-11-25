//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: This class can be used to provide stimulus when an interface
//              has been configured to run in a responder mode. It
//              will never finish by default, always going back to the driver
//              and driver BFM for the next transaction with which to respond.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
class imem_responder_sequence 
  extends imem_sequence_base ;

  `uvm_object_utils( imem_responder_sequence )

  // pragma uvmf custom class_item_additional begin
  //deterministic load/store test for verifying the data memory responder
  //the instruction-memory address space and data-memory address space are separate
  function automatic bit [15:0] smoke_instruction_at(bit [15:0] pc);
    case (pc)
      16'h3000: return 16'h5020; //and r0,r0,#0
      16'h3001: return 16'h1025; //add r0,r0,#5
      16'h3002: return 16'h1b60; //add r5,r5,#0 (spacing)
      16'h3003: return 16'h5fe0; //and r7,r7,#0 (spacing)
      16'h3004: return 16'h301b; //st r0,+27 -> data address x3020
      16'h3005: return 16'h1b60; //add r5,r5,#0 (spacing)
      16'h3006: return 16'h2219; //ld r1,+25 -> data address x3020
      16'h3007: return 16'h1b60; //add r5,r5,#0 (spacing)
      16'h3008: return 16'he417; //lea r2,+23 -> r2 = x3020
      16'h3009: return 16'h1b60; //add r5,r5,#0 (spacing)
      16'h300a: return 16'h6680; //ldr r3,r2,#0 -> data[x3020]
      16'h300b: return 16'h1b60; //add r5,r5,#0 (spacing)
      16'h300c: return 16'h16e1; //add r3,r3,#1
      16'h300d: return 16'h1b60; //add r5,r5,#0 (spacing)
      16'h300e: return 16'h7681; //str r3,r2,#1 -> data[x3021]
      16'h300f: return 16'h1b60; //add r5,r5,#0 (spacing)
      16'h3010: return 16'h6881; //ldr r4,r2,#1 -> data[x3021]
      16'h3011: return 16'h1b60; //add r5,r5,#0 (spacing)
      16'h3012: return 16'h1120; //add r0,r4,#0 -> r0 should become 6
      default:  return 16'h1b60; //add r5,r5,#0 (safe filler)
    endcase
  endfunction
  //selectable directed programs; default smoke remains unchanged
  string selected_program = "smoke";

  function automatic bit [15:0] alu_instruction_at(bit [15:0] pc);
    case (pc)
      16'h3000: return 16'h5020; //and r0,r0,#0
      16'h3001: return 16'h5260; //and r1,r1,#0
      16'h3002: return 16'h54a0; //and r2,r2,#0
      16'h3003: return 16'h56e0; //and r3,r3,#0
      16'h3004: return 16'h5920; //and r4,r4,#0
      16'h3005: return 16'h5b60; //and r5,r5,#0
      16'h3006: return 16'h5da0; //and r6,r6,#0
      16'h3007: return 16'h5fe0; //and r7,r7,#0
      16'h3008: return 16'h1021; //add r0,r0,#1
      16'h3009: return 16'h1261; //add r1,r1,#1
      16'h300a: return 16'h14a1; //add r2,r2,#1
      16'h300b: return 16'h16e1; //add r3,r3,#1
      16'h300c: return 16'h1921; //add r4,r4,#1
      16'h300d: return 16'h1b61; //add r5,r5,#1
      16'h300e: return 16'h1da1; //add r6,r6,#1
      16'h300f: return 16'h1fe1; //add r7,r7,#1
      16'h3010: return 16'h1001; //add r0,r0,r1
      16'h3011: return 16'h1242; //add r1,r1,r2
      16'h3012: return 16'h1483; //add r2,r2,r3
      16'h3013: return 16'h16c4; //add r3,r3,r4
      16'h3014: return 16'h1905; //add r4,r4,r5
      16'h3015: return 16'h1b46; //add r5,r5,r6
      16'h3016: return 16'h1d87; //add r6,r6,r7
      16'h3017: return 16'h1fc0; //add r7,r7,r0
      16'h3018: return 16'h5002; //and r0,r0,r2
      16'h3019: return 16'h5243; //and r1,r1,r3
      16'h301a: return 16'h5484; //and r2,r2,r4
      16'h301b: return 16'h56c5; //and r3,r3,r5
      16'h301c: return 16'h5906; //and r4,r4,r6
      16'h301d: return 16'h5b47; //and r5,r5,r7
      16'h301e: return 16'h5d80; //and r6,r6,r0
      16'h301f: return 16'h5fc1; //and r7,r7,r1
      16'h3020: return 16'h903f; //not r0,r0
      16'h3021: return 16'h927f; //not r1,r1
      16'h3022: return 16'h94bf; //not r2,r2
      16'h3023: return 16'h96ff; //not r3,r3
      16'h3024: return 16'h993f; //not r4,r4
      16'h3025: return 16'h9b7f; //not r5,r5
      16'h3026: return 16'h9dbf; //not r6,r6
      16'h3027: return 16'h9fff; //not r7,r7
      16'h3028: return 16'h103f; //add r0,r0,#-1
      16'h3029: return 16'h127f; //add r1,r1,#-1
      16'h302a: return 16'h14bf; //add r2,r2,#-1
      16'h302b: return 16'h16ff; //add r3,r3,#-1
      16'h302c: return 16'h193f; //add r4,r4,#-1
      16'h302d: return 16'h1b7f; //add r5,r5,#-1
      16'h302e: return 16'h1dbf; //add r6,r6,#-1
      16'h302f: return 16'h1fff; //add r7,r7,#-1
      default: return 16'h5020; //and r0,r0,#0: deterministic filler
    endcase
  endfunction

  //a zero-offset taken branch targets the sequential next pc
  //this exercises the condition masks without using a backward branch
  function automatic bit [15:0] branch_instruction_at(bit [15:0] pc);
    case (pc)
      16'h3000: return 16'h5020; //and r0,r0,#0; condition code = zero
      16'h3001: return 16'h0000; //brnever #0, zero condition-code block
      16'h3002: return 16'h0200; //brp #0, zero condition-code block
      16'h3003: return 16'h0400; //brz #0, zero condition-code block
      16'h3004: return 16'h0600; //brzp #0, zero condition-code block
      16'h3005: return 16'h0800; //brn #0, zero condition-code block
      16'h3006: return 16'h0a00; //brnp #0, zero condition-code block
      16'h3007: return 16'h0c00; //brnz #0, zero condition-code block
      16'h3008: return 16'h0e00; //brnzp #0, zero condition-code block
      16'h3009: return 16'h1021; //add r0,r0,#1; condition code = positive
      16'h300a: return 16'h0000; //brnever #0, positive condition-code block
      16'h300b: return 16'h0200; //brp #0, positive condition-code block
      16'h300c: return 16'h0400; //brz #0, positive condition-code block
      16'h300d: return 16'h0600; //brzp #0, positive condition-code block
      16'h300e: return 16'h0800; //brn #0, positive condition-code block
      16'h300f: return 16'h0a00; //brnp #0, positive condition-code block
      16'h3010: return 16'h0c00; //brnz #0, positive condition-code block
      16'h3011: return 16'h0e00; //brnzp #0, positive condition-code block
      16'h3012: return 16'h903f; //not r0,r0; condition code = negative
      16'h3013: return 16'h0000; //brnever #0, negative condition-code block
      16'h3014: return 16'h0200; //brp #0, negative condition-code block
      16'h3015: return 16'h0400; //brz #0, negative condition-code block
      16'h3016: return 16'h0600; //brzp #0, negative condition-code block
      16'h3017: return 16'h0800; //brn #0, negative condition-code block
      16'h3018: return 16'h0a00; //brnp #0, negative condition-code block
      16'h3019: return 16'h0c00; //brnz #0, negative condition-code block
      16'h301a: return 16'h0e00; //brnzp #0, negative condition-code block
      16'h301b: return 16'h5020; //and r0,r0,#0; restore zero condition
      16'h301c: return 16'h0001; //br never +1; non-taken positive offset
      16'h301d: return 16'h01ff; //br never -1; non-taken negative offset
      16'h301e: return 16'h00ff; //br never +255; positive offset boundary
      16'h301f: return 16'h0100; //br never -256; negative offset boundary
      default: return 16'h5020; //and r0,r0,#0; safe deterministic filler
    endcase
  endfunction
  //directed jmp coverage using only instructions supported by the design spec
  //the instruction at 3006 is safe if the known lea pc-relative bug occurs
  function automatic bit [15:0] jump_instruction_at(bit [15:0] pc);
    case (pc)
      16'h3000: return 16'h5020; //and r0,r0,#0
      16'h3001: return 16'hec05; //lea r6,+5; architectural target x3007
      16'h3002: return 16'h5260; //and r1,r1,#0; spacing
      16'h3003: return 16'hc180; //jmp r6; register-target jump
      16'h3004: return 16'h54a0; //and r2,r2,#0; should be skipped
      16'h3005: return 16'h56e0; //and r3,r3,#0; should be skipped
      16'h3006: return 16'h5920; //and r4,r4,#0; possible -1 landing
      16'h3007: return 16'h5b60; //and r5,r5,#0; correct landing
      16'h3008: return 16'h1021; //add r0,r0,#1; continue program
      16'h3009: return 16'h903f; //not r0,r0; continue program
      16'h300a: return 16'h5fe0; //and r7,r7,#0
      default: return 16'h5020; //and r0,r0,#0; safe filler
    endcase
  endfunction

  //indirect-mode directed test; only instructions from the 12-opcode subset
  //use both pointer locations to distinguish a pc-relative off-by-one from
  //the second memory access required by ldi and sti
  function automatic bit [15:0] indirect_instruction_at(bit [15:0] pc);
    case (pc)
      16'h3000: return 16'h5020; //and r0,r0,#0
      16'h3001: return 16'h1025; //add r0,r0,#5; pointer target x0005
      16'h3002: return 16'h5260; //and r1,r1,#0
      16'h3003: return 16'h1267; //add r1,r1,#7; initial data
      16'h3004: return 16'he41b; //lea r2,+27; arch x3020, known dut x301f
      16'h3005: return 16'h5da0; //and r6,r6,#0; spacing
      16'h3006: return 16'h7080; //str r0,r2,#0; pointer at actual x301f
      16'h3007: return 16'h5da0; //spacing
      16'h3008: return 16'h7081; //str r0,r2,#1; pointer at actual x3020
      16'h3009: return 16'h5da0; //spacing
      16'h300a: return 16'h7200; //str r1,r0,#0; data[x0005]=7
      16'h300b: return 16'h5da0; //spacing
      16'h300c: return 16'ha613; //ldi r3,+19; pointer at architectural x3020
      16'h300d: return 16'h5da0; //spacing
      16'h300e: return 16'h5260; //and r1,r1,#0
      16'h300f: return 16'h1269; //add r1,r1,#9
      16'h3010: return 16'h5da0; //spacing
      16'h3011: return 16'hb20e; //sti r1,+14; data[x0005]=9
      16'h3012: return 16'h5da0; //spacing
      16'h3013: return 16'ha80c; //ldi r4,+12; read new data[x0005]=9
      16'h3014: return 16'h5da0; //spacing
      16'h3015: return 16'h1b20; //add r5,r4,#0; should be 9
      default: return 16'h5da0; //valid, initialized deterministic filler
    endcase
  endfunction

  //one independent str, with no pc-relative addressing or other memory operations
  //the only intended data operation is write [x0005]=x0007
  function automatic bit [15:0] single_str_instruction_at(bit [15:0] pc);
    case (pc)
      16'h3000: return 16'h5020; //and r0,r0,#0
      16'h3001: return 16'h1025; //add r0,r0,#5
      16'h3002: return 16'h5260; //and r1,r1,#0
      16'h3003: return 16'h1267; //add r1,r1,#7
      16'h3004: return 16'h7200; //str r1,r0,#0; expected [x0005]=x0007
      default: return 16'h5da0; //and r6,r6,#0; no additional memory operations
    endcase
  endfunction

  //one lea followed by one str isolates the pc+1 addressing calculation
  //lea x3004+1+27=x3020, then str must write [x3020]=x0005
  function automatic bit [15:0] lea_str_instruction_at(bit [15:0] pc);
    case (pc)
      16'h3000: return 16'h5020; //and r0,r0,#0
      16'h3001: return 16'h1025; //add r0,r0,#5
      16'h3002: return 16'h5260; //and r1,r1,#0
      16'h3003: return 16'h1267; //add r1,r1,#7
      16'h3004: return 16'he41b; //lea r2,+27; expected x3020
      16'h3005: return 16'h5da0; //and r6,r6,#0; pipeline separation
      16'h3006: return 16'h7080; //str r0,r2,#0; expected [x3020]=x0005
      default: return 16'h5da0; //and r6,r6,#0; no additional memory operations
    endcase
  endfunction

  //sti-only isolates indirect stores from the ldi-repeat behavior.
  //the first twelve instructions initialize the same two pointer locations
  //and the target memory word as the existing indirect program.
  function automatic bit [15:0] sti_only_instruction_at(bit [15:0] pc);
    if (pc <= 16'h300b)
      return indirect_instruction_at(pc);
    case (pc)
      16'h300c: return 16'hb213; //sti r1,+19 through data[x3020]
      16'h300d: return 16'h5da0; //and r6,r6,#0; separation
      16'h300e: return 16'h6800; //ldr r4,r0,#0; check data[x0005]
      16'h300f: return 16'h5da0; //and r6,r6,#0
      16'h3010: return 16'h1120; //add r0,r4,#0
      default: return 16'h5da0; //initialized, valid spacing instruction
    endcase
  endfunction

  //ldi-only reproduces the indirect-load behavior without any later sti.
  function automatic bit [15:0] ldi_only_instruction_at(bit [15:0] pc);
    if (pc <= 16'h300c)
      return indirect_instruction_at(pc);
    case (pc)
      16'h300d: return 16'h5da0;
      16'h300e: return 16'h10e0; //add r0,r3,#0 if ldi completes
      default: return 16'h5da0;
    endcase
  endfunction

  //sti-first is retained for comparison with the original indirect run.
  function automatic bit [15:0] sti_first_instruction_at(bit [15:0] pc);
    if (pc == 16'h300c)
      return 16'hb213;
    return indirect_instruction_at(pc);
  endfunction

  //stage66:nonzero branch targets expose wrong-path execution
  function automatic bit [15:0] stage66_branch_at(bit [15:0] pc, bit taken_case);
    case (pc)
      16'h3000: return 16'h5020; //and r0,r0,#0
      16'h3001: return 16'h5260; //and r1,r1,#0
      16'h3002: return 16'h54a0; //and r2,r2,#0
      16'h3003: return 16'h56e0; //and r3,r3,#0; psr=z
      16'h3004: return taken_case ? 16'h0403 : 16'h0203; //brz/brp +3
      16'h3005: return 16'h5920; //fall-through sentinel 1
      16'h3006: return 16'h5b60; //fall-through sentinel 2
      16'h3007: return 16'h5da0; //fall-through sentinel 3
      16'h3008: return 16'h5fe0; //target sentinel
      default: return 16'h5020;
    endcase
  endfunction

  //stage67:non-idempotent control-flow sentinels with one observable store
  function automatic bit [15:0] stage67_program_at(bit [15:0] pc);
    case (pc)
      16'h3000: return 16'h5020; //and r0,r0,#0
      16'h3001: return (selected_program == "cf67_jump") ? 16'hec06 : 16'h5260; //lea r6,x3008 or clear r1
      16'h3002: return 16'h54a0;
      16'h3003: return 16'h56e0; //psr=z
      16'h3004: begin
        case (selected_program)
          "cf67_taken": return 16'h0403; //brz x3008
          "cf67_never": return 16'h0003; //zero mask, must not redirect
          "cf67_jump": return 16'hc180; //jmp r6
          default: return 16'h0203; //brp, not taken
        endcase
      end
      16'h3005: return (selected_program == "cf67_chain") ? 16'h0402 : 16'h1021; //brz x3008 or add r0,#1
      16'h3006: return 16'h5920;
      16'h3007: return 16'h5b60;
      16'h3008: return 16'h1022; //add r0,#2; duplicate execution is observable
      16'h3009: return 16'h5fe0;
      16'h300a: return 16'h5da0;
      16'h300b: return 16'h3014; //st r0,x3020
      default: return 16'h54a0;
    endcase
  endfunction

  //stage72:deterministic instruction-field coverage programs
  function automatic bit [15:0] stage72_instruction_at(bit [15:0] pc);
    case (selected_program)
      "cov72_alu": begin
        case (pc)
          16'h3000: return 16'h5020; //and r0,r0,#0
          16'h3001: return 16'h5260; //and r1,r1,#0
          16'h3002: return 16'h54a0; //and r2,r2,#0
          16'h3003: return 16'h56e0; //and r3,r3,#0
          16'h3004: return 16'h5920; //and r4,r4,#0
          16'h3005: return 16'h5b60; //and r5,r5,#0
          16'h3006: return 16'h5da0; //and r6,r6,#0
          16'h3007: return 16'h5fe0; //and r7,r7,#0
          16'h3008: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3009: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h300a: return 16'h1020; //add r0,r0,#0
          16'h300b: return 16'h5020; //and r0,r0,#0
          16'h300c: return 16'h1261; //add r1,r1,#1
          16'h300d: return 16'h5261; //and r1,r1,#1
          16'h300e: return 16'h14a2; //add r2,r2,#2
          16'h300f: return 16'h54a2; //and r2,r2,#2
          16'h3010: return 16'h16e3; //add r3,r3,#3
          16'h3011: return 16'h56e3; //and r3,r3,#3
          16'h3012: return 16'h1924; //add r4,r4,#4
          16'h3013: return 16'h5924; //and r4,r4,#4
          16'h3014: return 16'h1b65; //add r5,r5,#5
          16'h3015: return 16'h5b65; //and r5,r5,#5
          16'h3016: return 16'h1da6; //add r6,r6,#6
          16'h3017: return 16'h5da6; //and r6,r6,#6
          16'h3018: return 16'h1fe7; //add r7,r7,#7
          16'h3019: return 16'h5fe7; //and r7,r7,#7
          16'h301a: return 16'h1028; //add r0,r0,#8
          16'h301b: return 16'h5028; //and r0,r0,#8
          16'h301c: return 16'h1269; //add r1,r1,#9
          16'h301d: return 16'h5269; //and r1,r1,#9
          16'h301e: return 16'h14aa; //add r2,r2,#10
          16'h301f: return 16'h54aa; //and r2,r2,#10
          16'h3020: return 16'h16eb; //add r3,r3,#11
          16'h3021: return 16'h56eb; //and r3,r3,#11
          16'h3022: return 16'h192c; //add r4,r4,#12
          16'h3023: return 16'h592c; //and r4,r4,#12
          16'h3024: return 16'h1b6d; //add r5,r5,#13
          16'h3025: return 16'h5b6d; //and r5,r5,#13
          16'h3026: return 16'h1dae; //add r6,r6,#14
          16'h3027: return 16'h5dae; //and r6,r6,#14
          16'h3028: return 16'h1fef; //add r7,r7,#15
          16'h3029: return 16'h5fef; //and r7,r7,#15
          16'h302a: return 16'h1030; //add r0,r0,#-16
          16'h302b: return 16'h5030; //and r0,r0,#-16
          16'h302c: return 16'h1271; //add r1,r1,#-15
          16'h302d: return 16'h5271; //and r1,r1,#-15
          16'h302e: return 16'h14b2; //add r2,r2,#-14
          16'h302f: return 16'h54b2; //and r2,r2,#-14
          16'h3030: return 16'h16f3; //add r3,r3,#-13
          16'h3031: return 16'h56f3; //and r3,r3,#-13
          16'h3032: return 16'h1934; //add r4,r4,#-12
          16'h3033: return 16'h5934; //and r4,r4,#-12
          16'h3034: return 16'h1b75; //add r5,r5,#-11
          16'h3035: return 16'h5b75; //and r5,r5,#-11
          16'h3036: return 16'h1db6; //add r6,r6,#-10
          16'h3037: return 16'h5db6; //and r6,r6,#-10
          16'h3038: return 16'h1ff7; //add r7,r7,#-9
          16'h3039: return 16'h5ff7; //and r7,r7,#-9
          16'h303a: return 16'h1038; //add r0,r0,#-8
          16'h303b: return 16'h5038; //and r0,r0,#-8
          16'h303c: return 16'h1279; //add r1,r1,#-7
          16'h303d: return 16'h5279; //and r1,r1,#-7
          16'h303e: return 16'h14ba; //add r2,r2,#-6
          16'h303f: return 16'h54ba; //and r2,r2,#-6
          16'h3040: return 16'h16fb; //add r3,r3,#-5
          16'h3041: return 16'h56fb; //and r3,r3,#-5
          16'h3042: return 16'h193c; //add r4,r4,#-4
          16'h3043: return 16'h593c; //and r4,r4,#-4
          16'h3044: return 16'h1b7d; //add r5,r5,#-3
          16'h3045: return 16'h5b7d; //and r5,r5,#-3
          16'h3046: return 16'h1dbe; //add r6,r6,#-2
          16'h3047: return 16'h5dbe; //and r6,r6,#-2
          16'h3048: return 16'h1fff; //add r7,r7,#-1
          16'h3049: return 16'h5fff; //and r7,r7,#-1
          16'h304a: return 16'h1001; //add r0,r0,r1
          16'h304b: return 16'h5001; //and r0,r0,r1
          16'h304c: return 16'h903f; //not r0,r0
          16'h304d: return 16'h1242; //add r1,r1,r2
          16'h304e: return 16'h5242; //and r1,r1,r2
          16'h304f: return 16'h927f; //not r1,r1
          16'h3050: return 16'h1483; //add r2,r2,r3
          16'h3051: return 16'h5483; //and r2,r2,r3
          16'h3052: return 16'h94bf; //not r2,r2
          16'h3053: return 16'h16c4; //add r3,r3,r4
          16'h3054: return 16'h56c4; //and r3,r3,r4
          16'h3055: return 16'h96ff; //not r3,r3
          16'h3056: return 16'h1905; //add r4,r4,r5
          16'h3057: return 16'h5905; //and r4,r4,r5
          16'h3058: return 16'h993f; //not r4,r4
          16'h3059: return 16'h1b46; //add r5,r5,r6
          16'h305a: return 16'h5b46; //and r5,r5,r6
          16'h305b: return 16'h9b7f; //not r5,r5
          16'h305c: return 16'h1d87; //add r6,r6,r7
          16'h305d: return 16'h5d87; //and r6,r6,r7
          16'h305e: return 16'h9dbf; //not r6,r6
          16'h305f: return 16'h1fc0; //add r7,r7,r0
          16'h3060: return 16'h5fc0; //and r7,r7,r0
          16'h3061: return 16'h9fff; //not r7,r7
          default: return 16'h1fe0;
        endcase
      end
      "cov72_direct": begin
        case (pc)
          16'h3000: return 16'h5020; //and r0,r0,#0
          16'h3001: return 16'h5260; //and r1,r1,#0
          16'h3002: return 16'h54a0; //and r2,r2,#0
          16'h3003: return 16'h56e0; //and r3,r3,#0
          16'h3004: return 16'h5920; //and r4,r4,#0
          16'h3005: return 16'h5b60; //and r5,r5,#0
          16'h3006: return 16'h5da0; //and r6,r6,#0
          16'h3007: return 16'h5fe0; //and r7,r7,#0
          16'h3008: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3009: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h300a: return 16'he100; //lea r0,#-256
          16'h300b: return 16'he3ff; //lea r1,#-1
          16'h300c: return 16'he400; //lea r2,#0
          16'h300d: return 16'he601; //lea r3,#1
          16'h300e: return 16'he8ff; //lea r4,#255
          16'h300f: return 16'hebfe; //lea r5,#-2
          16'h3010: return 16'hec02; //lea r6,#2
          16'h3011: return 16'hee00; //lea r7,#0
          16'h3012: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3013: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3014: return 16'h3100; //st r0,#-256
          16'h3015: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3016: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3017: return 16'h2100; //ld r0,#-256
          16'h3018: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3019: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h301a: return 16'h33ff; //st r1,#-1
          16'h301b: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h301c: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h301d: return 16'h23ff; //ld r1,#-1
          16'h301e: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h301f: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3020: return 16'h3400; //st r2,#0
          16'h3021: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3022: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3023: return 16'h2400; //ld r2,#0
          16'h3024: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3025: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3026: return 16'h3601; //st r3,#1
          16'h3027: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3028: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3029: return 16'h2601; //ld r3,#1
          16'h302a: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h302b: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h302c: return 16'h38ff; //st r4,#255
          16'h302d: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h302e: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h302f: return 16'h28ff; //ld r4,#255
          16'h3030: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3031: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3032: return 16'h3bfe; //st r5,#-2
          16'h3033: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3034: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3035: return 16'h2bfe; //ld r5,#-2
          16'h3036: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3037: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3038: return 16'h3c02; //st r6,#2
          16'h3039: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h303a: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h303b: return 16'h2c02; //ld r6,#2
          16'h303c: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h303d: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h303e: return 16'h3e00; //st r7,#0
          16'h303f: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3040: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3041: return 16'h2e00; //ld r7,#0
          16'h3042: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3043: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3044: return 16'he040; //lea r0,#64
          16'h3045: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3046: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3047: return 16'h7220; //str r1,r0,#-32
          16'h3048: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3049: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h304a: return 16'h6420; //ldr r2,r0,#-32
          16'h304b: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h304c: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h304d: return 16'he240; //lea r1,#64
          16'h304e: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h304f: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3050: return 16'h747f; //str r2,r1,#-1
          16'h3051: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3052: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3053: return 16'h667f; //ldr r3,r1,#-1
          16'h3054: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3055: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3056: return 16'he440; //lea r2,#64
          16'h3057: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3058: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3059: return 16'h7680; //str r3,r2,#0
          16'h305a: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h305b: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h305c: return 16'h6880; //ldr r4,r2,#0
          16'h305d: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h305e: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h305f: return 16'he640; //lea r3,#64
          16'h3060: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3061: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3062: return 16'h78c1; //str r4,r3,#1
          16'h3063: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3064: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3065: return 16'h6ac1; //ldr r5,r3,#1
          16'h3066: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3067: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3068: return 16'he840; //lea r4,#64
          16'h3069: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h306a: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h306b: return 16'h7b1f; //str r5,r4,#31
          16'h306c: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h306d: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h306e: return 16'h6d1f; //ldr r6,r4,#31
          16'h306f: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3070: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3071: return 16'hea40; //lea r5,#64
          16'h3072: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3073: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3074: return 16'h7d7e; //str r6,r5,#-2
          16'h3075: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3076: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3077: return 16'h6f7e; //ldr r7,r5,#-2
          16'h3078: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3079: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h307a: return 16'hec40; //lea r6,#64
          16'h307b: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h307c: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h307d: return 16'h7f82; //str r7,r6,#2
          16'h307e: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h307f: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3080: return 16'h6182; //ldr r0,r6,#2
          16'h3081: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3082: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3083: return 16'hee40; //lea r7,#64
          16'h3084: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3085: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3086: return 16'h71c0; //str r0,r7,#0
          16'h3087: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3088: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3089: return 16'h63c0; //ldr r1,r7,#0
          16'h308a: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h308b: return 16'h1fe0; //add r7,r7,#0 (spacing)
          default: return 16'h1fe0;
        endcase
      end
      "cov72_indirect": begin
        case (pc)
          16'h3000: return 16'h5020; //and r0,r0,#0
          16'h3001: return 16'h5260; //and r1,r1,#0
          16'h3002: return 16'h54a0; //and r2,r2,#0
          16'h3003: return 16'h56e0; //and r3,r3,#0
          16'h3004: return 16'h5920; //and r4,r4,#0
          16'h3005: return 16'h5b60; //and r5,r5,#0
          16'h3006: return 16'h5da0; //and r6,r6,#0
          16'h3007: return 16'h5fe0; //and r7,r7,#0
          16'h3008: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3009: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h300a: return 16'h54a0; //and r2,r2,#0
          16'h300b: return 16'h14a8; //add r2,r2,#8 (known pointer value)
          16'h300c: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h300d: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h300e: return 16'h7480; //str r2,r2,#0 (initialize target)
          16'h300f: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3010: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3011: return 16'he307; //lea r1,#-249 (pointer cell address)
          16'h3012: return 16'h1260; //add r1,r1,#0
          16'h3013: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3014: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3015: return 16'h7440; //str r2,r1,#0 (initialize pointer cell)
          16'h3016: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3017: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3018: return 16'ha100; //ldi r0,#-256
          16'h3019: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h301a: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h301b: return 16'h54a0; //and r2,r2,#0
          16'h301c: return 16'h14a9; //add r2,r2,#9 (known pointer value)
          16'h301d: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h301e: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h301f: return 16'h7480; //str r2,r2,#0 (initialize target)
          16'h3020: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3021: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3022: return 16'he006; //lea r0,#6 (pointer cell address)
          16'h3023: return 16'h1020; //add r0,r0,#0
          16'h3024: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3025: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3026: return 16'h7400; //str r2,r0,#0 (initialize pointer cell)
          16'h3027: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3028: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3029: return 16'ha3ff; //ldi r1,#-1
          16'h302a: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h302b: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h302c: return 16'h5260; //and r1,r1,#0
          16'h302d: return 16'h126a; //add r1,r1,#10 (known pointer value)
          16'h302e: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h302f: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3030: return 16'h7240; //str r1,r1,#0 (initialize target)
          16'h3031: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3032: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3033: return 16'he007; //lea r0,#7 (pointer cell address)
          16'h3034: return 16'h1020; //add r0,r0,#0
          16'h3035: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3036: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3037: return 16'h7200; //str r1,r0,#0 (initialize pointer cell)
          16'h3038: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3039: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h303a: return 16'ha400; //ldi r2,#0
          16'h303b: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h303c: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h303d: return 16'h5260; //and r1,r1,#0
          16'h303e: return 16'h126b; //add r1,r1,#11 (known pointer value)
          16'h303f: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3040: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3041: return 16'h7240; //str r1,r1,#0 (initialize target)
          16'h3042: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3043: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3044: return 16'he008; //lea r0,#8 (pointer cell address)
          16'h3045: return 16'h1020; //add r0,r0,#0
          16'h3046: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3047: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3048: return 16'h7200; //str r1,r0,#0 (initialize pointer cell)
          16'h3049: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h304a: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h304b: return 16'ha601; //ldi r3,#1
          16'h304c: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h304d: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h304e: return 16'h5260; //and r1,r1,#0
          16'h304f: return 16'h126c; //add r1,r1,#12 (known pointer value)
          16'h3050: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3051: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3052: return 16'h7240; //str r1,r1,#0 (initialize target)
          16'h3053: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3054: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3055: return 16'he0ff; //lea r0,#255 (pointer cell address)
          16'h3056: return 16'h1027; //add r0,r0,#7
          16'h3057: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3058: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3059: return 16'h7200; //str r1,r0,#0 (initialize pointer cell)
          16'h305a: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h305b: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h305c: return 16'ha8ff; //ldi r4,#255
          16'h305d: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h305e: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h305f: return 16'h5260; //and r1,r1,#0
          16'h3060: return 16'h126d; //add r1,r1,#13 (known pointer value)
          16'h3061: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3062: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3063: return 16'h7240; //str r1,r1,#0 (initialize target)
          16'h3064: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3065: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3066: return 16'he005; //lea r0,#5 (pointer cell address)
          16'h3067: return 16'h1020; //add r0,r0,#0
          16'h3068: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3069: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h306a: return 16'h7200; //str r1,r0,#0 (initialize pointer cell)
          16'h306b: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h306c: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h306d: return 16'habfe; //ldi r5,#-2
          16'h306e: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h306f: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3070: return 16'h5260; //and r1,r1,#0
          16'h3071: return 16'h126e; //add r1,r1,#14 (known pointer value)
          16'h3072: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3073: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3074: return 16'h7240; //str r1,r1,#0 (initialize target)
          16'h3075: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3076: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3077: return 16'he009; //lea r0,#9 (pointer cell address)
          16'h3078: return 16'h1020; //add r0,r0,#0
          16'h3079: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h307a: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h307b: return 16'h7200; //str r1,r0,#0 (initialize pointer cell)
          16'h307c: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h307d: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h307e: return 16'hac02; //ldi r6,#2
          16'h307f: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3080: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3081: return 16'h5260; //and r1,r1,#0
          16'h3082: return 16'h126f; //add r1,r1,#15 (known pointer value)
          16'h3083: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3084: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3085: return 16'h7240; //str r1,r1,#0 (initialize target)
          16'h3086: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3087: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3088: return 16'he007; //lea r0,#7 (pointer cell address)
          16'h3089: return 16'h1020; //add r0,r0,#0
          16'h308a: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h308b: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h308c: return 16'h7200; //str r1,r0,#0 (initialize pointer cell)
          16'h308d: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h308e: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h308f: return 16'hae00; //ldi r7,#0
          16'h3090: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3091: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3092: return 16'h54a0; //and r2,r2,#0
          16'h3093: return 16'h14a8; //add r2,r2,#8 (known pointer value)
          16'h3094: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3095: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3096: return 16'he307; //lea r1,#-249 (pointer cell address)
          16'h3097: return 16'h1260; //add r1,r1,#0
          16'h3098: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3099: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h309a: return 16'h7440; //str r2,r1,#0 (initialize pointer cell)
          16'h309b: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h309c: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h309d: return 16'hb100; //sti r0,#-256
          16'h309e: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h309f: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30a0: return 16'h54a0; //and r2,r2,#0
          16'h30a1: return 16'h14a9; //add r2,r2,#9 (known pointer value)
          16'h30a2: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30a3: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30a4: return 16'he006; //lea r0,#6 (pointer cell address)
          16'h30a5: return 16'h1020; //add r0,r0,#0
          16'h30a6: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30a7: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30a8: return 16'h7400; //str r2,r0,#0 (initialize pointer cell)
          16'h30a9: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30aa: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30ab: return 16'hb3ff; //sti r1,#-1
          16'h30ac: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30ad: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30ae: return 16'h5260; //and r1,r1,#0
          16'h30af: return 16'h126a; //add r1,r1,#10 (known pointer value)
          16'h30b0: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30b1: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30b2: return 16'he007; //lea r0,#7 (pointer cell address)
          16'h30b3: return 16'h1020; //add r0,r0,#0
          16'h30b4: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30b5: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30b6: return 16'h7200; //str r1,r0,#0 (initialize pointer cell)
          16'h30b7: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30b8: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30b9: return 16'hb400; //sti r2,#0
          16'h30ba: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30bb: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30bc: return 16'h5260; //and r1,r1,#0
          16'h30bd: return 16'h126b; //add r1,r1,#11 (known pointer value)
          16'h30be: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30bf: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30c0: return 16'he008; //lea r0,#8 (pointer cell address)
          16'h30c1: return 16'h1020; //add r0,r0,#0
          16'h30c2: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30c3: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30c4: return 16'h7200; //str r1,r0,#0 (initialize pointer cell)
          16'h30c5: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30c6: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30c7: return 16'hb601; //sti r3,#1
          16'h30c8: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30c9: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30ca: return 16'h5260; //and r1,r1,#0
          16'h30cb: return 16'h126c; //add r1,r1,#12 (known pointer value)
          16'h30cc: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30cd: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30ce: return 16'he0ff; //lea r0,#255 (pointer cell address)
          16'h30cf: return 16'h1027; //add r0,r0,#7
          16'h30d0: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30d1: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30d2: return 16'h7200; //str r1,r0,#0 (initialize pointer cell)
          16'h30d3: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30d4: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30d5: return 16'hb8ff; //sti r4,#255
          16'h30d6: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30d7: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30d8: return 16'h5260; //and r1,r1,#0
          16'h30d9: return 16'h126d; //add r1,r1,#13 (known pointer value)
          16'h30da: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30db: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30dc: return 16'he005; //lea r0,#5 (pointer cell address)
          16'h30dd: return 16'h1020; //add r0,r0,#0
          16'h30de: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30df: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30e0: return 16'h7200; //str r1,r0,#0 (initialize pointer cell)
          16'h30e1: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30e2: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30e3: return 16'hbbfe; //sti r5,#-2
          16'h30e4: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30e5: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30e6: return 16'h5260; //and r1,r1,#0
          16'h30e7: return 16'h126e; //add r1,r1,#14 (known pointer value)
          16'h30e8: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30e9: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30ea: return 16'he009; //lea r0,#9 (pointer cell address)
          16'h30eb: return 16'h1020; //add r0,r0,#0
          16'h30ec: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30ed: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30ee: return 16'h7200; //str r1,r0,#0 (initialize pointer cell)
          16'h30ef: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30f0: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30f1: return 16'hbc02; //sti r6,#2
          16'h30f2: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30f3: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30f4: return 16'h5260; //and r1,r1,#0
          16'h30f5: return 16'h126f; //add r1,r1,#15 (known pointer value)
          16'h30f6: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30f7: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30f8: return 16'he007; //lea r0,#7 (pointer cell address)
          16'h30f9: return 16'h1020; //add r0,r0,#0
          16'h30fa: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30fb: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30fc: return 16'h7200; //str r1,r0,#0 (initialize pointer cell)
          16'h30fd: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30fe: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h30ff: return 16'hbe00; //sti r7,#0
          16'h3100: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3101: return 16'h1fe0; //add r7,r7,#0 (spacing)
          default: return 16'h1fe0;
        endcase
      end
      "cov72_jump": begin
        case (pc)
          16'h3000: return 16'h5020; //and r0,r0,#0
          16'h3001: return 16'h5260; //and r1,r1,#0
          16'h3002: return 16'h54a0; //and r2,r2,#0
          16'h3003: return 16'h56e0; //and r3,r3,#0
          16'h3004: return 16'h5920; //and r4,r4,#0
          16'h3005: return 16'h5b60; //and r5,r5,#0
          16'h3006: return 16'h5da0; //and r6,r6,#0
          16'h3007: return 16'h5fe0; //and r7,r7,#0
          16'h3008: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3009: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h300a: return 16'he005; //lea r0,#5 (forward target)
          16'h300b: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h300c: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h300d: return 16'hc000; //jmp r0
          16'h300e: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h300f: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3010: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3011: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3012: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3013: return 16'he205; //lea r1,#5 (forward target)
          16'h3014: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3015: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3016: return 16'hc040; //jmp r1
          16'h3017: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3018: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3019: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h301a: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h301b: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h301c: return 16'he405; //lea r2,#5 (forward target)
          16'h301d: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h301e: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h301f: return 16'hc080; //jmp r2
          16'h3020: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3021: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3022: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3023: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3024: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3025: return 16'he605; //lea r3,#5 (forward target)
          16'h3026: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3027: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3028: return 16'hc0c0; //jmp r3
          16'h3029: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h302a: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h302b: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h302c: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h302d: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h302e: return 16'he805; //lea r4,#5 (forward target)
          16'h302f: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3030: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3031: return 16'hc100; //jmp r4
          16'h3032: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3033: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3034: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3035: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3036: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3037: return 16'hea05; //lea r5,#5 (forward target)
          16'h3038: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3039: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h303a: return 16'hc140; //jmp r5
          16'h303b: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h303c: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h303d: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h303e: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h303f: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3040: return 16'hec05; //lea r6,#5 (forward target)
          16'h3041: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3042: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3043: return 16'hc180; //jmp r6
          16'h3044: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3045: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3046: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3047: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3048: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3049: return 16'hee05; //lea r7,#5 (forward target)
          16'h304a: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h304b: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h304c: return 16'hc1c0; //jmp r7
          16'h304d: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h304e: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h304f: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3050: return 16'h1fe0; //add r7,r7,#0 (spacing)
          16'h3051: return 16'h1fe0; //add r7,r7,#0 (spacing)
          default: return 16'h1fe0;
        endcase
      end
      default: return 16'h1fe0;
    endcase
  endfunction

  function automatic bit [15:0] instruction_at(bit [15:0] pc);
    if (selected_program == "cov72_alu" || selected_program == "cov72_direct" || selected_program == "cov72_indirect" || selected_program == "cov72_jump")
      return stage72_instruction_at(pc);
    if (selected_program == "cf67_taken" || selected_program == "cf67_not_taken" ||
        selected_program == "cf67_never" || selected_program == "cf67_jump" ||
        selected_program == "cf67_chain")
      return stage67_program_at(pc);
    if (selected_program == "br_taken")
      return stage66_branch_at(pc,1'b1);
    if (selected_program == "br_not_taken")
      return stage66_branch_at(pc,1'b0);
    if (selected_program == "single_str")
      return single_str_instruction_at(pc);
    if (selected_program == "lea_str")
      return lea_str_instruction_at(pc);
    if (selected_program == "alu")
      return alu_instruction_at(pc);
    if (selected_program == "branch")
      return branch_instruction_at(pc);
    if (selected_program == "jump")
      return jump_instruction_at(pc);
    if (selected_program == "indirect")
      return indirect_instruction_at(pc);
    if (selected_program == "sti_only")
      return sti_only_instruction_at(pc);
    if (selected_program == "ldi_only")
      return ldi_only_instruction_at(pc);
    if (selected_program == "sti_first")
      return sti_first_instruction_at(pc);
    return smoke_instruction_at(pc);
  endfunction
  // pragma uvmf custom class_item_additional end

  function new(string name = "imem_responder_sequence");
    super.new(name);
  endfunction

  task body();
    imem_transaction next_item;
    int unsigned item_number;
    bit [15:0] captured_pc;
    void'($value$plusargs("IMEM_PROGRAM=%s", selected_program));
    if ((selected_program != "smoke") && (selected_program != "alu") &&
        (selected_program != "branch") && (selected_program != "jump") &&
        (selected_program != "indirect") && (selected_program != "sti_only") &&
        (selected_program != "ldi_only") && (selected_program != "sti_first") &&
        (selected_program != "br_taken") && (selected_program != "br_not_taken") &&
        (selected_program != "cf67_taken") && (selected_program != "cf67_not_taken") &&
        (selected_program != "cf67_never") && (selected_program != "cf67_jump") &&
        (selected_program != "cf67_chain") &&
        (selected_program != "cov72_alu") &&
        (selected_program != "cov72_direct") &&
        (selected_program != "cov72_indirect") &&
        (selected_program != "cov72_jump"))
      `uvm_fatal("IMEM_PROGRAM", $sformatf("unsupported IMEM_PROGRAM='%s'", selected_program))
    `uvm_info("IMEM_PROGRAM", $sformatf("selected program=%s", selected_program), UVM_LOW)
    //the initial item primes the responder BFM to capture its first request
    req = imem_transaction::type_id::create("imem_prime");
    req.PC = 16'h0000;
    req.Instr_dout = 16'h0000;
    req.complete_instr = 1'b0;
    item_number = 0;
    forever begin
      start_item(req);
      finish_item(req);
      //finish_item returns the request captured by the driver BFM
      if (req.instrmem_rd !== 1'b1)
        `uvm_fatal("IMEM_REQUEST", "driver returned without a valid read request")
      captured_pc = req.PC;
      //never mutate a sequence item already handed to the UVMF driver
      next_item = imem_transaction::type_id::create($sformatf("imem_rsp_%0d", item_number));
      next_item.PC = captured_pc;
      next_item.instrmem_rd = 1'b1;
      next_item.I_macc = req.I_macc;
      next_item.Instr_dout = instruction_at(captured_pc);
      next_item.complete_instr = 1'b1;
      item_number++;
      if ($test$plusargs("CTRL61_HANDSHAKE") && item_number <= 80)
        `uvm_info("STAGE61_UVM_ITEM", $sformatf("n=%0d pc=%04h data=%04h",
          item_number, captured_pc, next_item.Instr_dout), UVM_LOW)
      req = next_item;
    end
  endtask

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

