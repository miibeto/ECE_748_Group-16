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

  function automatic bit [15:0] instruction_at(bit [15:0] pc);
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
    void'($value$plusargs("IMEM_PROGRAM=%s", selected_program));
    if ((selected_program != "smoke") && (selected_program != "alu") && (selected_program != "branch") && (selected_program != "jump") && (selected_program != "indirect") && (selected_program != "sti_only") && (selected_program != "ldi_only") && (selected_program != "sti_first"))
      `uvm_fatal("IMEM_PROGRAM", $sformatf("unsupported IMEM_PROGRAM='%s'", selected_program))
    `uvm_info("IMEM_PROGRAM", $sformatf("selected program=%s", selected_program), UVM_LOW)
    req = imem_transaction::type_id::create("req");
    req.Instr_dout = 16'h0000;
    req.complete_instr = 1'b0;
    forever begin
      start_item(req);
      finish_item(req);
      //finish_item returns after the driver captures the next request
      if (req.instrmem_rd) begin
        req.Instr_dout = instruction_at(req.PC);
        req.complete_instr = 1'b1;
        `uvm_info("IMEM", $sformatf("fetch pc=%04h opcode=%04h", req.PC, req.Instr_dout), UVM_MEDIUM)
      end else begin
        req.complete_instr = 1'b0;
      end
    end
  endtask

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

