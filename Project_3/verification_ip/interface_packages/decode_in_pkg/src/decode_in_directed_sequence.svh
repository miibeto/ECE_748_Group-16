


class decode_in_directed_sequence extends decode_in_sequence_base;

  `uvm_object_utils(decode_in_directed_sequence)

  // Array of all 12 valid LC-3 Decode stage opcodes using raw binary literals
  local bit [3:0] opcodes [12] = '{
    4'b0000, // BR
    4'b0001, // ADD
    4'b0010, // LD
    4'b0011, // ST
    4'b0101, // AND
    4'b0110, // LDR
    4'b0111, // STR
    4'b1001, // NOT
    4'b1010, // LDI
    4'b1011, // STI
    4'b1100, // JMP
    4'b1110  // LEA
  };

  function new(string name = "decode_in_directed_sequence");
    super.new(name);
  endfunction

  virtual task body();
    // pragma uvmf custom body begin
    foreach (opcodes[i]) begin
      req = decode_in_transaction_req_t::type_id::create("req");
      
      start_item(req);
      
      // Constrain upper bits of dout to the targeted opcode.
      // The transaction's internal constraints (valid_NOT_c and enable_on) 
      // will automatically set enable_decode=1 and dout[5:0]=6'b111111 for NOT.
      if (!req.randomize() with {
        dout[15:12] == opcodes[i];
      }) begin
        `uvm_fatal("SEQ", $sformatf("Randomization failed for opcode 4'b%04b", opcodes[i]))
      end
      
      finish_item(req);
      `uvm_info("SEQ", {"Response:",req.convert2string()},UVM_MEDIUM)
    end
    // pragma uvmf custom body end
  endtask

endclass