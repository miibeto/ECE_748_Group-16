//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//
//----------------------------------------------------------------------
//
// DESCRIPTION: This analysis component contains analysis_exports for receiving
//   data and analysis_ports for sending data.
// 
//   This analysis component has the following analysis_exports that receive the 
//   listed transaction type.
//   
//   imem_agent_ae receives transactions of type  imem_transaction
//   dmem_agent_ae receives transactions of type  dmem_transaction
//
//   This analysis component has the following analysis_ports that can broadcast 
//   the listed transaction type.
//
//  lc3_sb_ap broadcasts transactions of type dmem_transaction
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//

class lc3_predictor #(
  type CONFIG_T,
  type BASE_T = uvm_component
  )
 extends BASE_T;

  // Factory registration of this class
  `uvm_component_param_utils( lc3_predictor #(
                              CONFIG_T,
                              BASE_T
                              )
)


  // Instantiate a handle to the configuration of the environment in which this component resides
  CONFIG_T configuration;

  
  // Instantiate the analysis exports
  uvm_analysis_imp_imem_agent_ae #(imem_transaction, lc3_predictor #(
                              .CONFIG_T(CONFIG_T),
                              .BASE_T(BASE_T)
                              )
) imem_agent_ae;
  uvm_analysis_imp_dmem_agent_ae #(dmem_transaction, lc3_predictor #(
                              .CONFIG_T(CONFIG_T),
                              .BASE_T(BASE_T)
                              )
) dmem_agent_ae;

  
  // Instantiate the analysis ports
  uvm_analysis_port #(dmem_transaction) lc3_sb_ap;


  // Transaction variable for predicted values to be sent out lc3_sb_ap
  // Once a transaction is sent through an analysis_port, another transaction should
  // be constructed for the next predicted transaction. 
  typedef dmem_transaction lc3_sb_ap_output_transaction_t;
  lc3_sb_ap_output_transaction_t lc3_sb_ap_output_transaction;
  // Code for sending output transaction out through lc3_sb_ap
  // lc3_sb_ap.write(lc3_sb_ap_output_transaction);

  // Define transaction handles for debug visibility 
  imem_transaction imem_agent_ae_debug;
  dmem_transaction dmem_agent_ae_debug;


  // pragma uvmf custom class_item_additional begin
  //architectural registers and shadow memory are independent of the dut data path
  bit [15:0] architectural_regs [0:7];
  bit reg_known [0:7];
  bit [15:0] architectural_memory [bit [15:0]];
  int unsigned predicted_mem_ops = 0;
  int unsigned observed_mem_ops = 0;
  int unsigned unknown_operand_count = 0;

  function automatic bit [15:0] sign_extend5(input bit [4:0] v);
    return {{11{v[4]}}, v};
  endfunction

  function automatic bit [15:0] sign_extend6(input bit [5:0] v);
    return {{10{v[5]}}, v};
  endfunction

  function automatic bit [15:0] sign_extend9(input bit [8:0] v);
    return {{7{v[8]}}, v};
  endfunction

  //create one expected dmem operation from an instruction-level calculation
  function void send_memory_expectation(
      input bit [15:0] instruction_pc,
      input bit [15:0] instruction,
      input bit is_read,
      input bit [15:0] effective_addr,
      input bit [15:0] write_data,
      input bit [15:0] read_data,
      input time fetch_start_time,
      input time fetch_end_time);
    lc3_sb_ap_output_transaction =
        lc3_sb_ap_output_transaction_t::type_id::create("lc3_sb_ap_output_transaction");
    lc3_sb_ap_output_transaction.Data_addr = effective_addr;
    lc3_sb_ap_output_transaction.Data_rd = is_read;
    lc3_sb_ap_output_transaction.Data_din = is_read ? 16'h0000 : write_data;
    lc3_sb_ap_output_transaction.Data_dout = is_read ? read_data : 16'h0000;
    lc3_sb_ap_output_transaction.D_macc = 1'b1;
    lc3_sb_ap_output_transaction.complete_data = 1'b1;
    lc3_sb_ap_output_transaction.start_time = fetch_start_time;
    lc3_sb_ap_output_transaction.end_time = fetch_end_time;
    predicted_mem_ops++;
    `uvm_info("LC3_ARCH_PRED", $sformatf(
      "n=%0d pc=%04h instr=%04h %s addr=%04h din=%04h dout=%04h",
      predicted_mem_ops, instruction_pc, instruction,
      is_read ? "read" : "write", effective_addr,
      lc3_sb_ap_output_transaction.Data_din,
      lc3_sb_ap_output_transaction.Data_dout), UVM_LOW)
    lc3_sb_ap.write(lc3_sb_ap_output_transaction);
  endfunction
  // pragma uvmf custom class_item_additional end

  // FUNCTION: new
  function new(string name, uvm_component parent);
     super.new(name,parent);
  // pragma uvmf custom new begin
  // pragma uvmf custom new end
  endfunction

  // FUNCTION: build_phase
  virtual function void build_phase (uvm_phase phase);

    imem_agent_ae = new("imem_agent_ae", this);
    dmem_agent_ae = new("dmem_agent_ae", this);
    lc3_sb_ap =new("lc3_sb_ap", this );
  // pragma uvmf custom build_phase begin
  // pragma uvmf custom build_phase end
  endfunction

  // FUNCTION: write_imem_agent_ae
  // Transactions received through imem_agent_ae initiate the execution of this function.
  // This function performs prediction of DUT output values based on DUT input, configuration and state
  virtual function void write_imem_agent_ae(imem_transaction t);
    // pragma uvmf custom imem_agent_ae_predictor begin
    bit [15:0] instruction;
    bit [15:0] instruction_pc;
    bit [15:0] effective_addr;
    bit [15:0] value;
    bit value_known;
    bit [2:0] dest;
    bit [2:0] src1;
    bit [2:0] src2;
    bit [3:0] opcode;

    imem_agent_ae_debug = t;
    //only a completed fetch represents an instruction to predict
    if (!t.instrmem_rd || !t.complete_instr)
      return;

    instruction = t.Instr_dout;
    instruction_pc = t.PC;
    opcode = instruction[15:12];
    dest = instruction[11:9];
    src1 = instruction[8:6];
    src2 = instruction[2:0];
    value = 16'h0000;
    value_known = 1'b0;

    //execute the supported operations in architectural program order
    //no dut writeback values or data-memory addresses are used as oracle inputs
    case (opcode)
      4'h1: begin
        //add
        if (reg_known[src1]) begin
          if (instruction[5]) begin
            value = architectural_regs[src1] + sign_extend5(instruction[4:0]);
            value_known = 1'b1;
          end else if (reg_known[src2]) begin
            value = architectural_regs[src1] + architectural_regs[src2];
            value_known = 1'b1;
          end
        end
        architectural_regs[dest] = value;
        reg_known[dest] = value_known;
      end
      4'h5: begin
        //and, including clear-register idiom with immediate zero
        if (instruction[5] && instruction[4:0] == 5'h00) begin
          value = 16'h0000;
          value_known = 1'b1;
        end else if (reg_known[src1]) begin
          if (instruction[5]) begin
            value = architectural_regs[src1] & sign_extend5(instruction[4:0]);
            value_known = 1'b1;
          end else if (reg_known[src2]) begin
            value = architectural_regs[src1] & architectural_regs[src2];
            value_known = 1'b1;
          end
        end
        architectural_regs[dest] = value;
        reg_known[dest] = value_known;
      end
      4'h9: begin
        //not
        architectural_regs[dest] = ~architectural_regs[src1];
        reg_known[dest] = reg_known[src1];
      end
      4'hE: begin
        //lea is pc-relative to the incremented pc
        architectural_regs[dest] = instruction_pc + 16'h0001 + sign_extend9(instruction[8:0]);
        reg_known[dest] = 1'b1;
      end
      4'h3: begin
        //st, pc-relative store
        effective_addr = instruction_pc + 16'h0001 + sign_extend9(instruction[8:0]);
        if (!reg_known[dest]) begin
          unknown_operand_count++;
          `uvm_error("LC3_ARCH_UNKNOWN", $sformatf("unknown ST source R%0d at pc=%04h", dest, instruction_pc))
        end else begin
          value = architectural_regs[dest];
          architectural_memory[effective_addr] = value;
          send_memory_expectation(instruction_pc, instruction, 1'b0,
            effective_addr, value, 16'h0000, t.start_time, t.end_time);
        end
      end
      4'h2: begin
        //ld, pc-relative load
        effective_addr = instruction_pc + 16'h0001 + sign_extend9(instruction[8:0]);
        value = architectural_memory.exists(effective_addr) ? architectural_memory[effective_addr] : 16'h0000;
        architectural_regs[dest] = value;
        reg_known[dest] = 1'b1;
        send_memory_expectation(instruction_pc, instruction, 1'b1,
          effective_addr, 16'h0000, value, t.start_time, t.end_time);
      end
      4'h7: begin
        //str, base-register-relative store
        effective_addr = architectural_regs[src1] + sign_extend6(instruction[5:0]);
        if (!reg_known[src1] || !reg_known[dest]) begin
          unknown_operand_count++;
          `uvm_error("LC3_ARCH_UNKNOWN", $sformatf("unknown STR operand at pc=%04h", instruction_pc))
        end else begin
          value = architectural_regs[dest];
          architectural_memory[effective_addr] = value;
          send_memory_expectation(instruction_pc, instruction, 1'b0,
            effective_addr, value, 16'h0000, t.start_time, t.end_time);
        end
      end
      4'h6: begin
        //ldr, base-register-relative load
        effective_addr = architectural_regs[src1] + sign_extend6(instruction[5:0]);
        if (!reg_known[src1]) begin
          unknown_operand_count++;
          `uvm_error("LC3_ARCH_UNKNOWN", $sformatf("unknown LDR base at pc=%04h", instruction_pc))
          reg_known[dest] = 1'b0;
        end else begin
          value = architectural_memory.exists(effective_addr) ? architectural_memory[effective_addr] : 16'h0000;
          architectural_regs[dest] = value;
          reg_known[dest] = 1'b1;
          send_memory_expectation(instruction_pc, instruction, 1'b1,
            effective_addr, 16'h0000, value, t.start_time, t.end_time);
        end
      end
      4'ha: begin
        //ldi: first read an address from pc-relative memory, then read data
        effective_addr = instruction_pc + 16'h0001 + sign_extend9(instruction[8:0]);
        value = architectural_memory.exists(effective_addr) ?
            architectural_memory[effective_addr] : 16'h0000;
        send_memory_expectation(instruction_pc, instruction, 1'b1,
            effective_addr, 16'h0000, value, t.start_time, t.end_time);
        effective_addr = value;
        value = architectural_memory.exists(effective_addr) ?
            architectural_memory[effective_addr] : 16'h0000;
        architectural_regs[dest] = value;
        reg_known[dest] = 1'b1;
        send_memory_expectation(instruction_pc, instruction, 1'b1,
            effective_addr, 16'h0000, value, t.start_time, t.end_time);
      end
      4'hb: begin
        //sti: first read pointer, then write source register through pointer
        effective_addr = instruction_pc + 16'h0001 + sign_extend9(instruction[8:0]);
        value = architectural_memory.exists(effective_addr) ?
            architectural_memory[effective_addr] : 16'h0000;
        send_memory_expectation(instruction_pc, instruction, 1'b1,
            effective_addr, 16'h0000, value, t.start_time, t.end_time);
        effective_addr = value;
        if (!reg_known[dest]) begin
          unknown_operand_count++;
          `uvm_error("LC3_ARCH_UNKNOWN", $sformatf(
            "unknown STI source R%0d at pc=%04h", dest, instruction_pc))
        end else begin
          value = architectural_regs[dest];
          architectural_memory[effective_addr] = value;
          send_memory_expectation(instruction_pc, instruction, 1'b0,
              effective_addr, value, 16'h0000, t.start_time, t.end_time);
        end
      end
      default: begin
        //other opcodes need control-flow support
        //no memory transactions are predicted for non-memory opcodes
      end
    endcase
    // pragma uvmf custom imem_agent_ae_predictor end
  endfunction

  // FUNCTION: write_dmem_agent_ae
  // Transactions received through dmem_agent_ae initiate the execution of this function.
  // This function performs prediction of DUT output values based on DUT input, configuration and state
  virtual function void write_dmem_agent_ae(dmem_transaction t);
    // pragma uvmf custom dmem_agent_ae_predictor begin
    dmem_agent_ae_debug = t;
    observed_mem_ops++;
    `uvm_info("LC3_ARCH_OBS", $sformatf(
      "n=%0d %s addr=%04h din=%04h dout=%04h done=%b",
      observed_mem_ops, t.Data_rd ? "read" : "write", t.Data_addr,
      t.Data_din, t.Data_dout, t.complete_data), UVM_LOW)
    //the dmem monitor already feeds the scoreboard actual port
    //do not emit a second prediction for the same completed dmem operation
    // pragma uvmf custom dmem_agent_ae_predictor end
  endfunction


  //fail the architectural comparison if the physical interface completes
  //more operations than the independent instruction-model predicts
  //a first-match score is not sufficient: a repeated store is a failure
  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info("STAGE44_ARCH_COUNTS", $sformatf(
      "expected=%0d observed=%0d difference=%0d status=%s",
      predicted_mem_ops, observed_mem_ops,
      $signed(observed_mem_ops)-$signed(predicted_mem_ops),
      predicted_mem_ops == observed_mem_ops ? "COUNT_MATCH" : "COUNT_MISMATCH"), UVM_NONE)
    if (predicted_mem_ops != observed_mem_ops) begin
      `uvm_error("STAGE44_ARCH_COUNT_FAIL", $sformatf(
        "independent model predicted %0d memory transactions, monitor observed %0d; duplicate and missing operations are not architectural passes",
        predicted_mem_ops, observed_mem_ops))
    end
  endfunction

endclass 

// pragma uvmf custom external begin
// pragma uvmf custom external end

