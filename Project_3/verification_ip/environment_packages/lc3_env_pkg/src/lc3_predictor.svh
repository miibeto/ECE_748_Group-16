

//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
// File: lc3_predictor.svh
// Description: Predictor component for top-level LC-3 environment.
//              Decodes incoming IMEM instructions via dmem_decode_model
//              and broadcasts expected DMEM transactions to the scoreboard.
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------

class lc3_predictor #(
  type CONFIG_T,
  type BASE_T = uvm_component
  ) extends BASE_T;

  // Factory registration of this class
  `uvm_component_param_utils( lc3_predictor #(
                              CONFIG_T,
                              BASE_T
                              )
                            )

  // Handle to the environment configuration
  CONFIG_T configuration;

  // Analysis exports for receiving interface transactions from monitors
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

  // Analysis port for broadcasting predicted transactions to the Scoreboard
  uvm_analysis_port #(dmem_transaction) lc3_sb_ap;

  // Transaction handles for prediction output and debugging
  typedef dmem_transaction lc3_sb_ap_output_transaction_t;
  lc3_sb_ap_output_transaction_t lc3_sb_ap_output_transaction;

  imem_transaction imem_agent_ae_debug;
  dmem_transaction dmem_agent_ae_debug;

  // pragma uvmf custom class_item_additional begin
  typedef enum {
    OP_LOAD,     // LD, LDR, or 2nd stage of LDI -> writes t.Data_dout into regfile[reg_idx]
    OP_STORE,    // ST, STR, or 2nd stage of STI -> no regfile update
    OP_LDI_PTR,  // 1st stage of LDI -> emits 2nd read at Addr = t.Data_dout
    OP_STI_PTR   // 1st stage of STI -> emits 2nd write at Addr = t.Data_dout
  } dmem_op_e;

  typedef struct {
    dmem_op_e    op_type;
    logic [2:0]  reg_idx;
    logic [15:0] store_data;
    int unsigned write_gen;
  } pending_dmem_t;

  // Shadow architectural register file (R0-R7), write generation tags, and in-flight DMEM queue
  logic [15:0]   regfile [0:7];
  int unsigned   reg_write_gen [0:7];
  pending_dmem_t pending_dmem_q [$];
  // pragma uvmf custom class_item_additional end

  // FUNCTION: new
  function new(string name, uvm_component parent);
     super.new(name, parent);
  endfunction

  // FUNCTION: build_phase
  virtual function void build_phase (uvm_phase phase);
    imem_agent_ae = new("imem_agent_ae", this);
    dmem_agent_ae = new("dmem_agent_ae", this);
    lc3_sb_ap     = new("lc3_sb_ap",     this);

    foreach (regfile[i]) begin
      regfile[i]       = 16'h0000;
      reg_write_gen[i] = 0;
    end
    pending_dmem_q.delete();
  endfunction

  // FUNCTION: write_imem_agent_ae
  virtual function void write_imem_agent_ae(imem_transaction t);
    // pragma uvmf custom imem_agent_ae_predictor begin
    logic [15:0]   predicted_Data_addr;
    logic          predicted_Data_rd;
    bit            valid_op;
    logic [15:0]   instr;
    logic [3:0]    opcode;
    logic [2:0]    dr_sr;
    logic [2:0]    sr1_base;
    pending_dmem_t pending_txn;

    imem_agent_ae_debug = t;
    `uvm_info("PRED", $sformatf("Transaction received through imem_agent_ae: %s", t.convert2string()), UVM_MEDIUM)

    instr    = t.Instr_dout;
    opcode   = instr[15:12];
    dr_sr    = instr[11:9];
    sr1_base = instr[8:6];

    // Pass the 16-bit contents of BaseR (not the 3-bit register index)
    if (imem_dmem_model(
          .instr_dout   (instr),
          .pc           (t.PC),
          .base_reg_val (regfile[sr1_base]),
          .Data_addr    (predicted_Data_addr),
          .Data_rd      (predicted_Data_rd),
          .valid_op     (valid_op)
        ))
    begin
      `uvm_error("LC3_PREDICTOR", "dmem_decode_model returned error status.")
    end

    // Broadcast expected DMEM transaction when a valid memory instruction is decoded
    if (valid_op) begin
      lc3_sb_ap_output_transaction = lc3_sb_ap_output_transaction_t::type_id::create("lc3_sb_ap_output_transaction");

      lc3_sb_ap_output_transaction.Data_addr     = predicted_Data_addr;
      lc3_sb_ap_output_transaction.Data_rd       = predicted_Data_rd;
      lc3_sb_ap_output_transaction.Data_din      = (opcode == 4'b0011 || opcode == 4'b0111) ? regfile[dr_sr] : 16'h0000;
      lc3_sb_ap_output_transaction.Data_dout     = 16'h0000;
      lc3_sb_ap_output_transaction.D_macc        = 1'b1;
      lc3_sb_ap_output_transaction.complete_data = 1'b1;

      `uvm_info("LC3_PREDICTOR",
        $sformatf("Predicted DMEM Txn: Addr=0x%04h Din=0x%04h Rd=%0b (from PC=0x%04h Instr=0x%04h)",
                  lc3_sb_ap_output_transaction.Data_addr,
                  lc3_sb_ap_output_transaction.Data_din,
                  lc3_sb_ap_output_transaction.Data_rd,
                  t.PC,
                  instr), UVM_MEDIUM)

      lc3_sb_ap.write(lc3_sb_ap_output_transaction);

      // Track in-flight DMEM operation for regfile writeback or 2nd-stage LDI/STI access
      pending_txn.reg_idx    = dr_sr;
      pending_txn.store_data = regfile[dr_sr];
      pending_txn.write_gen  = 0;
      case (opcode)
        4'b0010, 4'b0110: begin // LD, LDR
          reg_write_gen[dr_sr]++;
          pending_txn.op_type   = OP_LOAD;
          pending_txn.write_gen = reg_write_gen[dr_sr];
        end
        4'b0011, 4'b0111: begin // ST, STR
          pending_txn.op_type   = OP_STORE;
        end
        4'b1010: begin          // LDI (stage 1 pointer fetch)
          reg_write_gen[dr_sr]++;
          pending_txn.op_type   = OP_LDI_PTR;
          pending_txn.write_gen = reg_write_gen[dr_sr];
        end
        4'b1011: begin          // STI (stage 1 pointer fetch)
          pending_txn.op_type   = OP_STI_PTR;
        end
        default: begin
          pending_txn.op_type   = OP_STORE;
        end
      endcase
      pending_dmem_q.push_back(pending_txn);
    end

    // Update shadow register file and write generation tags for non-DMEM writeback instructions
    case (opcode)
      4'b0001: begin // ADD
        if (instr[5])
          regfile[dr_sr] = regfile[sr1_base] + {{11{instr[4]}}, instr[4:0]};
        else
          regfile[dr_sr] = regfile[sr1_base] + regfile[instr[2:0]];
        reg_write_gen[dr_sr]++;
      end

      4'b0101: begin // AND
        if (instr[5])
          regfile[dr_sr] = regfile[sr1_base] & {{11{instr[4]}}, instr[4:0]};
        else
          regfile[dr_sr] = regfile[sr1_base] & regfile[instr[2:0]];
        reg_write_gen[dr_sr]++;
      end

      4'b1001: begin // NOT
        regfile[dr_sr] = ~regfile[sr1_base];
        reg_write_gen[dr_sr]++;
      end

      4'b1110: begin // LEA (PC + SEXT(PCoffset9))
        regfile[dr_sr] = t.PC + {{7{instr[8]}}, instr[8:0]};
        reg_write_gen[dr_sr]++;
      end

      4'b0100: begin // JSR / JSRR saves NPC into R7
        regfile[3'd7] = t.PC + 16'd1;
        reg_write_gen[3'd7]++;
      end

      default: ; // BR, JMP/RET, RTI, TRAP, and DMEM ops handled elsewhere
    endcase
    // pragma uvmf custom imem_agent_ae_predictor end
  endfunction

  // FUNCTION: write_dmem_agent_ae
  virtual function void write_dmem_agent_ae(dmem_transaction t);
    // pragma uvmf custom dmem_agent_ae_predictor begin
    pending_dmem_t completed_txn;
    pending_dmem_t stage2_txn;

    dmem_agent_ae_debug = t;
    `uvm_info("PRED", $sformatf("Transaction received through dmem_agent_ae: %s", t.convert2string()), UVM_MEDIUM)

    if (t.D_macc && t.complete_data) begin
      if (pending_dmem_q.size() == 0) begin
        `uvm_warning("LC3_PREDICTOR", "Received DMEM transaction with empty pending_dmem_q.")
        return;
      end

      completed_txn = pending_dmem_q.pop_front();

      case (completed_txn.op_type)
        OP_LOAD: begin
          // Only commit load data if no younger instruction has overwritten this register
          if (completed_txn.write_gen == reg_write_gen[completed_txn.reg_idx]) begin
            regfile[completed_txn.reg_idx] = t.Data_dout;
          end
        end

        OP_LDI_PTR: begin
          // Pointer fetch finished; emit 2nd DMEM read at target address t.Data_dout
          lc3_sb_ap_output_transaction = lc3_sb_ap_output_transaction_t::type_id::create("lc3_sb_ap_output_transaction");
          lc3_sb_ap_output_transaction.Data_addr     = t.Data_dout;
          lc3_sb_ap_output_transaction.Data_rd       = 1'b1;
          lc3_sb_ap_output_transaction.Data_din      = 16'h0000;
          lc3_sb_ap_output_transaction.Data_dout     = 16'h0000;
          lc3_sb_ap_output_transaction.D_macc        = 1'b1;
          lc3_sb_ap_output_transaction.complete_data = 1'b1;
          lc3_sb_ap.write(lc3_sb_ap_output_transaction);

          stage2_txn.op_type    = OP_LOAD;
          stage2_txn.reg_idx    = completed_txn.reg_idx;
          stage2_txn.store_data = 16'h0000;
          stage2_txn.write_gen  = completed_txn.write_gen;
          pending_dmem_q.push_back(stage2_txn);
        end

        OP_STI_PTR: begin
          // Pointer fetch finished; emit 2nd DMEM write at target address t.Data_dout
          lc3_sb_ap_output_transaction = lc3_sb_ap_output_transaction_t::type_id::create("lc3_sb_ap_output_transaction");
          lc3_sb_ap_output_transaction.Data_addr     = t.Data_dout;
          lc3_sb_ap_output_transaction.Data_rd       = 1'b0;
          lc3_sb_ap_output_transaction.Data_din      = completed_txn.store_data;
          lc3_sb_ap_output_transaction.Data_dout     = 16'h0000;
          lc3_sb_ap_output_transaction.D_macc        = 1'b1;
          lc3_sb_ap_output_transaction.complete_data = 1'b1;
          lc3_sb_ap.write(lc3_sb_ap_output_transaction);

          stage2_txn.op_type    = OP_STORE;
          stage2_txn.reg_idx    = completed_txn.reg_idx;
          stage2_txn.store_data = completed_txn.store_data;
          stage2_txn.write_gen  = completed_txn.write_gen;
          pending_dmem_q.push_back(stage2_txn);
        end

        OP_STORE: ; // Nothing to write back to regfile
      endcase
    end
    // pragma uvmf custom dmem_agent_ae_predictor end
  endfunction

endclass

// //----------------------------------------------------------------------
// // Created with uvmf_gen version 2026.1
// // File: lc3_predictor.svh
// // Description: Predictor component for top-level LC-3 environment.
// //              Decodes incoming IMEM instructions via dmem_decode_model
// //              and broadcasts expected DMEM transactions to the scoreboard.
// //----------------------------------------------------------------------
// // pragma uvmf custom header begin
// // pragma uvmf custom header end
// //----------------------------------------------------------------------

// class lc3_predictor #(
//   type CONFIG_T,
//   type BASE_T = uvm_component
//   ) extends BASE_T;

//   // Factory registration of this class
//   `uvm_component_param_utils( lc3_predictor #(
//                               CONFIG_T,
//                               BASE_T
//                               )
//                             )

//   // Handle to the environment configuration
//   CONFIG_T configuration;

//   // Analysis exports for receiving interface transactions from monitors
//   uvm_analysis_imp_imem_agent_ae #(imem_transaction, lc3_predictor #(
//                               .CONFIG_T(CONFIG_T),
//                               .BASE_T(BASE_T)
//                               )
//                             ) imem_agent_ae;

//   uvm_analysis_imp_dmem_agent_ae #(dmem_transaction, lc3_predictor #(
//                               .CONFIG_T(CONFIG_T),
//                               .BASE_T(BASE_T)
//                               )
//                             ) dmem_agent_ae;

//   // Analysis port for broadcasting predicted transactions to the Scoreboard
//   uvm_analysis_port #(dmem_transaction) lc3_sb_ap;

//   // Transaction handles for prediction output and debugging
//   typedef dmem_transaction lc3_sb_ap_output_transaction_t;
//   lc3_sb_ap_output_transaction_t lc3_sb_ap_output_transaction;

//   imem_transaction imem_agent_ae_debug;
//   dmem_transaction dmem_agent_ae_debug;

//   // pragma uvmf custom class_item_additional begin
//   // pragma uvmf custom class_item_additional end

//   // FUNCTION: new
//   function new(string name, uvm_component parent);
//      super.new(name, parent);
//   endfunction

//   // FUNCTION: build_phase
//   virtual function void build_phase (uvm_phase phase);
//     imem_agent_ae = new("imem_agent_ae", this);
//     dmem_agent_ae = new("dmem_agent_ae", this);
//     lc3_sb_ap     = new("lc3_sb_ap",     this);
//   endfunction

//   // FUNCTION: write_imem_agent_ae
//   virtual function void write_imem_agent_ae(imem_transaction t);
//     // pragma uvmf custom imem_agent_ae_predictor begin
//     logic [15:0] predicted_Data_addr;
//     logic        predicted_Data_rd;
//     bit          valid_op;

//     imem_agent_ae_debug = t;
//     `uvm_info("PRED", $sformatf("Transaction received through imem_agent_ae: %s", t.convert2string()), UVM_MEDIUM)

//     if (imem_dmem_model(
//           .instr_dout (t.Instr_dout),
//           .pc         (t.PC),
//           .base_reg_val (t.Instr_dout[8:6]),
//           .Data_addr  (predicted_Data_addr),
//           .Data_rd    (predicted_Data_rd),
//           .valid_op   (valid_op)
//         ))
//     begin
//       `uvm_error("LC3_PREDICTOR", "dmem_decode_model returned error status.")
//     end

//     // Only broadcast to the scoreboard when a valid memory instruction is decoded
//     if (valid_op) begin
//       lc3_sb_ap_output_transaction = lc3_sb_ap_output_transaction_t::type_id::create("lc3_sb_ap_output_transaction");

//       lc3_sb_ap_output_transaction.Data_addr     = predicted_Data_addr;
//       lc3_sb_ap_output_transaction.Data_rd       = predicted_Data_rd;
//       lc3_sb_ap_output_transaction.D_macc        = 1'b1;
//       lc3_sb_ap_output_transaction.complete_data = 1'b1;

//       `uvm_info("LC3_PREDICTOR",
//         $sformatf("Predicted DMEM Txn: Addr=0x%04h Rd=%0b (from PC=0x%04h Instr=0x%04h)",
//                   lc3_sb_ap_output_transaction.Data_addr,
//                   lc3_sb_ap_output_transaction.Data_rd,
//                   t.PC,
//                   t.Instr_dout), UVM_MEDIUM)

//       lc3_sb_ap.write(lc3_sb_ap_output_transaction);
//     end
//     // pragma uvmf custom imem_agent_ae_predictor end
//   endfunction

//   // FUNCTION: write_dmem_agent_ae
//   virtual function void write_dmem_agent_ae(dmem_transaction t);
//     // pragma uvmf custom dmem_agent_ae_predictor begin
//     dmem_agent_ae_debug = t;
//     `uvm_info("PRED", $sformatf("Transaction received through dmem_agent_ae: %s", t.convert2string()), UVM_MEDIUM)
//     // pragma uvmf custom dmem_agent_ae_predictor end
//   endfunction

// endclass

// // pragma uvmf custom external begin
// // pragma uvmf custom external end
