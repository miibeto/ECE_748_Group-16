

class imem_experiment_sequence extends imem_responder_sequence;
  `uvm_object_utils(imem_experiment_sequence)

  // -------------------------------------------------------------------
  // Instruction Memory ROM Table (PC -> Machine Code)
  // -------------------------------------------------------------------
  bit [15:0] imem_rom[bit [15:0]];
  int unsigned insn_count = 0;

  function new(string name = "imem_experiment_sequence");
    super.new(name);
    initialize_rom();
  endfunction

  // Pre-seed ROM with instruction test sequence starting at PC 0x3000
  function void initialize_rom();
    // imem_rom[16'h3000] = 16'h5020;
    // imem_rom[16'h3001] = 16'h5260;
    // imem_rom[16'h3002] = 16'h54A0;
    // imem_rom[16'h3003] = 16'h56E0;
    // imem_rom[16'h3004] = 16'h5920;
    // imem_rom[16'h3005] = 16'h5B60;
    // imem_rom[16'h3006] = 16'h5DA0;
    // imem_rom[16'h3007] = 16'h5FE0;
    // imem_rom[16'h3008] = 16'h1266;
    // imem_rom[16'h3009] = 16'h320B;
    // imem_rom[16'h300A] = 16'h5842;
    // imem_rom[16'h300B] = 16'h2409;
    // imem_rom[16'h300C] = 16'h56E0;
    // imem_rom[16'h300D] = 16'h1D6A;
    // imem_rom[16'h300E] = 16'h17B1;
    // imem_rom[16'h300f] = 16'hE000;
    // imem_rom[16'h3010] = 16'h56E0;
    // imem_rom[16'h3011] = 16'h7600;
    // imem_rom[16'h3012] = 16'h96FF;
    // imem_rom[16'h3013] = 16'h6800;
    // imem_rom[16'h3014] = 16'h3BF5;
    // imem_rom[16'h3015] = 16'hADF4;
    // imem_rom[16'h3016] = 16'h5920;
    // imem_rom[16'h3017] = 16'hBFF1;
    // imem_rom[16'h3018] = 16'h1360;
    // imem_rom[16'h3019] = 16'h09E7;
    // imem_rom[16'h302a] = 16'h16E1;
    // imem_rom[16'h302b] = 16'h4FD6;
    // imem_rom[16'h302c] = 16'hF025;
    // imem_rom[16'h302d] = 16'h14A1;
    // imem_rom[16'h302e] = 16'hC1C0;
    // imem_rom[16'h302f] = 16'hF025;
    imem_rom[16'h3000] = 16'h5020;
    imem_rom[16'h3001] = 16'h5260;
    imem_rom[16'h3002] = 16'h54A0;
    imem_rom[16'h3003] = 16'h56E0;
    imem_rom[16'h3004] = 16'h5920;
    imem_rom[16'h3005] = 16'h5B60;
    imem_rom[16'h3006] = 16'h5DA0;
    imem_rom[16'h3007] = 16'h5FE0;
    imem_rom[16'h3008] = 16'h1266;
    imem_rom[16'h3009] = 16'h16E6;
    imem_rom[16'h300A] = 16'h1B66;
    imem_rom[16'h300B] = 16'h1DA6;
    imem_rom[16'h300C] = 16'h3223;
    imem_rom[16'h300D] = 16'h1020;
    imem_rom[16'h300E] = 16'h3622;
    imem_rom[16'h300f] = 16'h1020;
    imem_rom[16'h3010] = 16'h3A21;
    imem_rom[16'h3011] = 16'h1020;
    imem_rom[16'h3012] = 16'h3C20;
    imem_rom[16'h3013] = 16'h1020;
    imem_rom[16'h3014] = 16'h241E;
    imem_rom[16'h3015] = 16'h1020;
    imem_rom[16'h3016] = 16'h281B;
    imem_rom[16'h3017] = 16'h1020;
    imem_rom[16'h3018] = 16'h2218;
    imem_rom[16'h3019] = 16'h1020;
    imem_rom[16'h301a] = 16'h2615;
    imem_rom[16'h301b] = 16'hF025;
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
        
      `uvm_info("ROM_IMEM", 
                $sformatf("NOP for unmapped PC: 0x%04h", req.PC), UVM_MEDIUM)
      end

      // Complete handshake back to driver
      finish_item(req);

      // Stop sequence when HALT (TRAP 0x25 / 0xF025) instruction completes
      if (req.Instr_dout == 16'hF025) begin
        `uvm_info("ROM_IMEM", "HALT instruction (0xF025) executed. Sequence complete.", UVM_LOW)
      end
    end
  endtask

endclass