//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
// File: lc3_predictor.svh
// Description: Predictor component for top-level LC-3 environment.
//              Synchronizes IMEM and DMEM transactions, calls the 
//              lc3_top_golden_model, and broadcasts predicted output 
//              transactions to the scoreboard.
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
  // Pending queues to buffer transactions until matching cycle pairs arrive
  imem_transaction imem_pending[$];
  dmem_transaction dmem_pending[$];
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
  endfunction

  // -------------------------------------------------------------------
  // FUNCTION: process_pending_transactions
  // Pairs IMEM and DMEM transactions in FIFO order, invokes the LC-3 top
  // golden model, and sends predicted data memory transactions to scoreboard.
  // -------------------------------------------------------------------
  function void process_pending_transactions();
    logic [15:0] predicted_PC;
    logic        predicted_instrmem_rd;

    // Process all paired transactions available in the queues
    while (imem_pending.size() > 0 && dmem_pending.size() > 0) begin
      imem_transaction imem_tr = imem_pending.pop_front();
      dmem_transaction dmem_tr = dmem_pending.pop_front();

      // Create new transaction object for scoreboard output
      lc3_sb_ap_output_transaction = lc3_sb_ap_output_transaction_t::type_id::create("lc3_sb_ap_output_transaction");

      // Execute Golden Model step using inputs from matched transactions
      if (lc3_top_golden_model(
            .complete_data  (dmem_tr.complete_data),
            .complete_instr (imem_tr.complete_instr),
            .Instr_dout     (imem_tr.Instr_dout),
            .Data_dout      (dmem_tr.Data_dout),
            .PC             (predicted_PC),
            .instrmem_rd    (predicted_instrmem_rd),
            .Data_addr      (lc3_sb_ap_output_transaction.Data_addr),
            .Data_din       (lc3_sb_ap_output_transaction.Data_din),
            .Data_rd        (lc3_sb_ap_output_transaction.Data_rd)
          )) 
      begin
        `uvm_error("LC3_PREDICTOR", "LC3 Top Golden Model returned error status.")
      end

      // Assign monitored interface fields to output transaction
      lc3_sb_ap_output_transaction.Data_dout     = dmem_tr.Data_dout;
      lc3_sb_ap_output_transaction.complete_data = dmem_tr.complete_data;

      `uvm_info("LC3_PREDICTOR", 
        $sformatf("Predicted DMEM Txn: Addr=0x%04h Din=0x%04h Rd=%0b", 
                  lc3_sb_ap_output_transaction.Data_addr, 
                  lc3_sb_ap_output_transaction.Data_din, 
                  lc3_sb_ap_output_transaction.Data_rd), UVM_MEDIUM)

      // Broadcast predicted transaction to Scoreboard
      lc3_sb_ap.write(lc3_sb_ap_output_transaction);
    end
  endfunction

  // FUNCTION: write_imem_agent_ae
  virtual function void write_imem_agent_ae(imem_transaction t);
    // pragma uvmf custom imem_agent_ae_predictor begin
    imem_agent_ae_debug = t;
    `uvm_info("PRED", $sformatf("Transaction received through imem_agent_ae: %s", t.convert2string()), UVM_MEDIUM)
    imem_pending.push_back(t);
    process_pending_transactions();
    // pragma uvmf custom imem_agent_ae_predictor end
  endfunction

  // FUNCTION: write_dmem_agent_ae
  virtual function void write_dmem_agent_ae(dmem_transaction t);
    // pragma uvmf custom dmem_agent_ae_predictor begin
    dmem_agent_ae_debug = t;
    `uvm_info("PRED", $sformatf("Transaction received through dmem_agent_ae: %s", t.convert2string()), UVM_MEDIUM)
    dmem_pending.push_back(t);
    process_pending_transactions();
    // pragma uvmf custom dmem_agent_ae_predictor end
  endfunction

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end