// The decode_model function models the behavior of the decode unit
// The return value indicates model results status: 0 success, 1 failure
//
// 'automatic' so every call gets fresh outputs. As a static function the
// outputs kept the previous call's values, so opcodes without a case item
// (JSR/JSRR, TRAP, RTI, RESERVED) silently reused the last instruction's
// e/w/mem_control as their prediction.
function automatic bit decode_model
  (
    input bit [15: 0] instr_dout,
    input bit [15: 0] npc_in,
    output bit [15: 0] ir,
    output bit [15: 0] npc_out,
    output bit [5: 0] e_control,
    output bit [1: 0] w_control,
    output bit mem_control
  );

  // Replace test code below with lc3 decode model
  ir = instr_dout;
  npc_out = npc_in;

  // Defaults for every output before the case. Opcodes not covered below
  // keep these values and the model reports status 1 (not modeled).
  // NOTE: JSR/JSRR/TRAP/RTI decode outputs are not defined in the material
  // we have; these defaults are NOT taken from the DUT. Replace with spec
  // values once the E_Control/W_Control table for them is confirmed.
  e_control   = 6'b000000;
  w_control   = 2'b00;
  mem_control = 1'b0;

  casex (instr_dout[15: 12])
    ADD : begin
      w_control = 0;
      e_control = (instr_dout[5] == 1) ? (6'b000000) : (6'b000001);
      mem_control = 0;
    end

    AND : begin
      w_control = 0;
      e_control = (instr_dout[5] == 1) ? (6'b010000) : (6'b010001);
      mem_control = 0;
    end

    NOT : begin
      w_control = 0;
      e_control = 6'b100000;
      mem_control = 0;
    end

    BR : begin
      w_control = 0;
      e_control = 6'b000110;
      mem_control = 0;
    end

    JMP : begin
      w_control = 0;
      e_control = 6'b001100;
      mem_control = 0;
    end

    LD : begin
      w_control = 1;
      e_control = 6'b000110;
      mem_control = 0;
    end

    LDR : begin
      w_control = 1;
      e_control = 6'b001000;
      mem_control = 0;
    end

    LDI : begin
      w_control = 1;
      e_control = 6'b000110;
      mem_control = 1;
    end

    LEA : begin
      w_control = 2;
      e_control = 6'b000110;
      mem_control = 0;
    end

    ST : begin
      w_control = 0;
      e_control = 6'b000110;
      mem_control = 0;
    end

    STR : begin
      w_control = 0;
      e_control = 6'b001000;
      mem_control = 0;
    end

    STI : begin
      w_control = 0;
      e_control = 6'b000110;
      mem_control = 1;
    end

    default : begin
      // JSR/JSRR, TRAP, RTI, RESERVED: outputs stay at the defaults above.
      return (1);
    end

  endcase

  return (0);
endfunction
