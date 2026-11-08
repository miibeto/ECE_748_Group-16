//----------------------------------------------------------------------
// File: lc3_startup_imem_responder_sequence.svh
// Description: Custom IMEM responder sequence that initializes 
//              registers and services instruction fetches from ROM.
//----------------------------------------------------------------------

class imem_lc3_startup_sequence extends imem_responder_sequence;
  `uvm_object_utils(imem_lc3_startup_sequence)

  // -------------------------------------------------------------------
  // Instruction Memory ROM Table (PC -> Machine Code)
  // -------------------------------------------------------------------
  bit [15:0] imem_rom[bit [15:0]];
  int unsigned insn_count = 0;

  function new(string name = "imem_lc3_startup_sequence");
    super.new(name);
    initialize_rom();
  endfunction

  // Pre-seed ROM with instruction test sequence starting at PC 0x3000
  function void initialize_rom();
    // Phase 1: Dual Load Constraint
    imem_rom[16'h3000] = 16'h2213; // LD  R1, 0x3014 (Loads DATA_VAL1 = 0x0005)
    imem_rom[16'h3001] = 16'h2413; // LD  R2, 0x3015 (Loads DATA_VAL2 = 0x000A)

    // Phase 2: ALU & Condition Code Verification
    imem_rom[16'h3002] = 16'h1642; // ADD R3, R1, R2   (R3 = 5 + 10 = 15, sets 'P')
    imem_rom[16'h3003] = 16'h5842; // AND R4, R1, R2   (R4 = 5 & 10 = 0, sets 'Z')
    imem_rom[16'h3004] = 16'h9AFF; // NOT R5, R3       (R5 = ~15 = -16, sets 'N')
    imem_rom[16'h3005] = 16'h1C6A; // ADD R6, R1, #10  (R6 = 5 + 10 = 15)
    imem_rom[16'h3006] = 16'h1EB1; // ADD R7, R2, #-15 (R7 = 10 - 15 = -5)

    // Phase 3: Memory Addressing & Data Hazards (RAW)
    imem_rom[16'h3007] = 16'hE010; // LEA R0, 0x3018   (R0 = address of SCRATCHPAD)
    imem_rom[16'h3008] = 16'h7600; // STR R3, R0, #0   (Store R3=15 to [R0 + 0])
    imem_rom[16'h3009] = 16'h6800; // LDR R4, R0, #0   (Read back from [R0 + 0])
    // imem_rom[16'h300A] = 16'h3A0B; // ST  R5, 0x3016   (Store R5=-16 to STORE_TARGET)
    // imem_rom[16'h300B] = 16'hA60B; // LDI R6, 0x3017   (Load through INDIR_PTR)
    // imem_rom[16'h300C] = 16'hB70A; // STI R7, 0x3017   (Store through INDIR_PTR)

    // // Phase 4: Control Flow (Branching, Subroutine, Return)
    // imem_rom[16'h300D] = 16'h1360; // ADD R1, R5, #0   (Set CC based on R5 = -16)
    // imem_rom[16'h300E] = 16'h0801; // BRn 0x3010       (Branch taken to 0x3010)
    // imem_rom[16'h300F] = 16'h16E1; // ADD R3, R3, #1   (Pipeline bubble, skipped)
    // imem_rom[16'h3010] = 16'h4801; // JSR 0x3012       (Jump to SUBROUTINE, R7=0x3011)
    // imem_rom[16'h3011] = 16'hF025; // TRAP 0x25        (HALT)

    // Subroutine Body
    imem_rom[16'h3012] = 16'h14A1; // ADD R2, R2, #1   (Subroutine body: R2 = R2 + 1)
    imem_rom[16'h3013] = 16'hC1C0; // RET              (Return to PC saved in R7)
  endfunction

  virtual task body();
    req = imem_transaction::type_id::create("req");

    forever begin
      // Retrieve fetch request from Driver (captures incoming DUT req.PC)
      start_item(req);

      // Check if requested PC exists in ROM memory table
      if (imem_rom.exists(req.PC)) begin
        req.Instr_dout     = imem_rom[req.PC];
        req.complete_instr = 1'b1;
        insn_count++;

        `uvm_info("ROM_IMEM", 
          $sformatf("Executed Insn [%0d] @ PC:0x%04h -> Instr:0x%04h", 
                    insn_count, req.PC, req.Instr_dout), UVM_MEDIUM)
      end else begin
        // PC address is outside initialized ROM space -> drive NOP and exit
        req.Instr_dout     = 16'h0000; // NOP
        req.complete_instr = 1'b1;
        
      `uvm_info("ROM_IMEM", 
                $sformatf("Driving NOP for unmapped PC: 0x%04h", req.PC), UVM_MEDIUM)
        
        // finish_item(req);
        // break; // Stop sequence execution
      end

      // Complete handshake back to driver
      finish_item(req);

      // Stop sequence when HALT (TRAP 0x25 / 0xF025) instruction completes
      if (req.Instr_dout == 16'hF025) begin
        `uvm_info("ROM_IMEM", "HALT instruction (0xF025) executed. Sequence complete.", UVM_LOW)
        break; // Stop sequence execution
      end
    end
  endtask

endclass