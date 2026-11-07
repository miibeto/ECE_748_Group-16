//----------------------------------------------------------------------
// File: lc3_startup_imem_responder_sequence.svh
// Description: Custom IMEM responder sequence that initializes 
//              registers R0-R7 before generating random instructions.
//----------------------------------------------------------------------

class imem_lc3_startup_sequence extends imem_responder_sequence;
  `uvm_object_utils(imem_lc3_startup_sequence)

  // -------------------------------------------------------------------
  // 16-bit Startup Program Instructions:
  // 1. Clear R0-R7 using AND Rx, Rx, #0 (Opcode 5)
  // 2. Seed initial non-zero values into R0-R7 using ADD Rx, Rx, #imm (Opcode 1)
  // -------------------------------------------------------------------
  protected bit [15:0] startup_program[16] = '{
    // Step 1: Clear R0 - R7 to 16'h0000
    16'h5020, // AND R0, R0, #0
    16'h5260, // AND R1, R1, #0
    16'h54A0, // AND R2, R2, #0
    16'h56E0, // AND R3, R3, #0
    16'h5920, // AND R4, R4, #0
    16'h5B60, // AND R5, R5, #0
    16'h5DA0, // AND R6, R6, #0
    16'h5FE0, // AND R7, R7, #0

    // Step 2: Seed initial values into R0 - R7
    16'h1021, // ADD R0, R0, #1
    16'h1262, // ADD R1, R1, #2
    16'h14A3, // ADD R2, R2, #3
    16'h16E4, // ADD R3, R3, #4
    16'h1925, // ADD R4, R4, #5
    16'h1B66, // ADD R5, R5, #6
    16'h1DA7, // ADD R6, R6, #7
    16'h1FE8  // ADD R7, R7, #8
  };

  int unsigned insn_count = 0;

  function new(string name = "imem_lc3_startup_sequence");
    super.new(name);
  endfunction

  virtual task body();
    imem_transaction req;

    forever begin
      req = imem_transaction::type_id::create("req");
      
      // Handshake with Driver BFM: waits until DUT requests an instruction fetch
      start_item(req);

      // ---------------------------------------------------------------
      // Phase 1: Inject startup program instructions into DUT
      // ---------------------------------------------------------------
      if (insn_count < $size(startup_program)) begin
        req.Instr_dout     = startup_program[insn_count];
        req.complete_instr = 1'b1; // Tell LC-3 Controller instruction is ready
        
        `uvm_info("STARTUP_IMEM", 
          $sformatf("Driving Startup Insn [%0d/15] @ Instr_dout: 0x%04h", 
                    insn_count, req.Instr_dout), UVM_MEDIUM)
        
        insn_count++;
      end 
      // ---------------------------------------------------------------
      // Phase 2: Fallback to standard randomized instruction generation
      // ---------------------------------------------------------------
      else begin
        if (!req.randomize()) begin
          `uvm_fatal("SEQ", "imem_transaction randomization failed!")
        end
        req.complete_instr = 1'b1;
      end

      // Complete transfer and pass transaction to Driver BFM to drive pins
      finish_item(req);
    end
  endtask

endclass