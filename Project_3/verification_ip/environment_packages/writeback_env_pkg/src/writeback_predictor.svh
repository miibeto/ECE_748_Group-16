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
//   writeback_in_agent_ae receives transactions of type  writeback_in_transaction
//
//   This analysis component has the following analysis_ports that can broadcast 
//   the listed transaction type.
//
//  writeback_sb_ap broadcasts transactions of type writeback_out_transaction
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//

class writeback_predictor #(
  type CONFIG_T,
  type BASE_T = uvm_component
  )
 extends BASE_T;

  // Factory registration of this class
  `uvm_component_param_utils( writeback_predictor #(
                              CONFIG_T,
                              BASE_T
                              )
)


  // Instantiate a handle to the configuration of the environment in which this component resides
  CONFIG_T configuration;

  
  // Instantiate the analysis exports
  uvm_analysis_imp_writeback_in_agent_ae #(writeback_in_transaction, writeback_predictor #(
                              .CONFIG_T(CONFIG_T),
                              .BASE_T(BASE_T)
                              )
) writeback_in_agent_ae;

  
  // Instantiate the analysis ports
  uvm_analysis_port #(writeback_out_transaction) writeback_sb_ap;


  // Transaction variable for predicted values to be sent out writeback_sb_ap
  // Once a transaction is sent through an analysis_port, another transaction should
  // be constructed for the next predicted transaction. 
  typedef writeback_out_transaction writeback_sb_ap_output_transaction_t;
  writeback_sb_ap_output_transaction_t writeback_sb_ap_output_transaction;
  // Code for sending output transaction out through writeback_sb_ap
  // writeback_sb_ap.write(writeback_sb_ap_output_transaction);

  // Define transaction handles for debug visibility 
  writeback_in_transaction writeback_in_agent_ae_debug;


  // pragma uvmf custom class_item_additional begin
  bit [2:0] predicted_psr = 3'b000;
  int unsigned wb_ref_diag_count = 0;
  // pragma uvmf custom class_item_additional end

  // FUNCTION: new
  function new(string name, uvm_component parent);
     super.new(name,parent);
  // pragma uvmf custom new begin
  // pragma uvmf custom new end
  endfunction

  // FUNCTION: build_phase
  virtual function void build_phase (uvm_phase phase);

    writeback_in_agent_ae = new("writeback_in_agent_ae", this);
    writeback_sb_ap =new("writeback_sb_ap", this );
  // pragma uvmf custom build_phase begin
  // pragma uvmf custom build_phase end
  endfunction

  // FUNCTION: write_writeback_in_agent_ae
  // Transactions received through writeback_in_agent_ae initiate the execution of this function.
  // This function performs prediction of DUT output values based on DUT input, configuration and state
  virtual function void write_writeback_in_agent_ae(writeback_in_transaction t);
    // pragma uvmf custom writeback_in_agent_ae_predictor begin
    writeback_in_agent_ae_debug = t;
    `uvm_info("PRED", "Transaction Received through writeback_in_agent_ae", UVM_MEDIUM)
    `uvm_info("PRED", {"            Data: ",t.convert2string()}, UVM_FULL)
    // Construct one of each output transaction type.
    writeback_sb_ap_output_transaction = writeback_sb_ap_output_transaction_t::type_id::create("writeback_sb_ap_output_transaction");
    //sample pre-write outputs, then advance the model for the next clock
    begin
      bit prediction_failed;
      bit [15:0] pre_vsr1, pre_vsr2;
      bit [2:0] next_psr;

      //the dut outputs are sampled at a falling edge before the upcoming register write
      writeback_sb_ap_output_transaction.psr = predicted_psr;

      if (t.enable_writeback && t.w_control == 2'b11)
        `uvm_error("WB_MODEL", "write enabled with reserved w_control=3")

      //the reference model returns source registers before updating its static register file
      prediction_failed = lc3_prediction_pkg::writeback_model(
        t.aluout,
        t.w_control,
        t.npc,
        t.pcout,
        t.memout,
        t.enable_writeback,
        t.sr1,
        t.sr2,
        t.dr,
        pre_vsr1,
        pre_vsr2,
        next_psr
      );
      if (prediction_failed)
        `uvm_error("WB_MODEL", "writeback_model returned a failure")

      writeback_sb_ap_output_transaction.vsr1 = pre_vsr1;
      writeback_sb_ap_output_transaction.vsr2 = pre_vsr2;

      //the write and condition code update become observable at the next monitor sample
      if (t.enable_writeback && t.w_control != 2'b11)
        predicted_psr = next_psr;

      //capture model inputs and predicted outputs without changing any comparison
      // if (wb_ref_diag_count < 100) begin
      //   `uvm_info("WB_REF_DIAG",
      //     $sformatf("t=%0t n=%0d wr=%b wc=%0d dr=%0d sr1=%0d sr2=%0d alu=%04h mem=%04h pc=%04h npc=%04h exp_vsr1=%04h exp_vsr2=%04h exp_psr=%0h next_psr=%0h",
      //       $time, wb_ref_diag_count, t.enable_writeback, t.w_control,
      //       t.dr, t.sr1, t.sr2, t.aluout, t.memout, t.pcout, t.npc,
      //       writeback_sb_ap_output_transaction.vsr1,
      //       writeback_sb_ap_output_transaction.vsr2,
      //       writeback_sb_ap_output_transaction.psr, predicted_psr), UVM_LOW)
      // end
      wb_ref_diag_count++;

      //`uvm_info("WB_TIMING", $sformatf("time=%0t wr=%0b dr=%0d sr1=%0d sr2=%0d predicted_now=(%04h,%04h,%0h) next_psr=%0h", $time, t.enable_writeback, t.dr, t.sr1, t.sr2, pre_vsr1, pre_vsr2, writeback_sb_ap_output_transaction.psr, predicted_psr), UVM_HIGH)
    end
    writeback_sb_ap_output_transaction.start_time = t.start_time;
    writeback_sb_ap_output_transaction.end_time = t.end_time;

    // Code for sending output transaction out through writeback_sb_ap
    // Please note that each broadcasted transaction should be a different object than previously 
    // broadcasted transactions.  Creation of a different object is done by constructing the transaction 
    // using either new() or create().  Broadcasting a transaction object more than once to either the 
    // same subscriber or multiple subscribers will result in unexpected and incorrect behavior.
    writeback_sb_ap.write(writeback_sb_ap_output_transaction);
    // pragma uvmf custom writeback_in_agent_ae_predictor end
  endfunction


endclass 

// pragma uvmf custom external begin
// pragma uvmf custom external end