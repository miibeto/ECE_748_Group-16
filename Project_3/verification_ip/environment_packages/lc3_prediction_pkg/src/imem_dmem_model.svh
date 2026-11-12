

function bit imem_dmem_model
  (
    input bit [15: 0] instr_dout,
    input bit [15: 0] PC,
    output bit [15: 0] Data_addr,
    output tri Data_rd
  );

  casex (instr_dout[15: 12])
    ADD : begin
      Data_rd = 'bz;
    end

    AND : begin
      Data_rd = 'bz;
    end

    NOT : begin
      Data_rd = 'bz;
    end

    BR : begin
      Data_rd = 'bz;
    end

    JMP : begin
      Data_rd = 'bz;
    end

    LD : begin
      Data_addr = PC + instr_dout[9:0];
      Data_rd 
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

  endcase

  return (0);
endfunction
