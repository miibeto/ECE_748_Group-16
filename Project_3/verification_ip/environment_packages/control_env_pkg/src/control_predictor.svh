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
//   control_in_agent_ae receives transactions of type  control_in_transaction
//
//   This analysis component has the following analysis_ports that can broadcast 
//   the listed transaction type.
//
//  control_sb_ap broadcasts transactions of type control_out_transaction
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//

class control_predictor #(
  type CONFIG_T,
  type BASE_T = uvm_component
  )
 extends BASE_T;

  // Factory registration of this class
  `uvm_component_param_utils( control_predictor #(
                              CONFIG_T,
                              BASE_T
                              )
)


  // Instantiate a handle to the configuration of the environment in which this component resides
  CONFIG_T configuration;

  
  // Instantiate the analysis exports
  uvm_analysis_imp_control_in_agent_ae #(control_in_transaction, control_predictor #(
                              .CONFIG_T(CONFIG_T),
                              .BASE_T(BASE_T)
                              )
) control_in_agent_ae;

  
  // Instantiate the analysis ports
  uvm_analysis_port #(control_out_transaction) control_sb_ap;


  // Transaction variable for predicted values to be sent out control_sb_ap
  // Once a transaction is sent through an analysis_port, another transaction should
  // be constructed for the next predicted transaction. 
  typedef control_out_transaction control_sb_ap_output_transaction_t;
  control_sb_ap_output_transaction_t control_sb_ap_output_transaction;
  // Code for sending output transaction out through control_sb_ap
  // control_sb_ap.write(control_sb_ap_output_transaction);

  // Define transaction handles for debug visibility 
  control_in_transaction control_in_agent_ae_debug;


  // pragma uvmf custom class_item_additional begin
  //limit temporary predictor diagnostics to the first 36 transactions
  int unsigned control_trace_count = 0;
  // pragma uvmf custom class_item_additional end

  // FUNCTION: new
  function new(string name, uvm_component parent);
     super.new(name,parent);
  // pragma uvmf custom new begin
  // pragma uvmf custom new end
  endfunction

  // FUNCTION: build_phase
  virtual function void build_phase (uvm_phase phase);

    control_in_agent_ae = new("control_in_agent_ae", this);
    control_sb_ap =new("control_sb_ap", this );
  // pragma uvmf custom build_phase begin
  // pragma uvmf custom build_phase end
  endfunction

  // FUNCTION: write_control_in_agent_ae
  // Transactions received through control_in_agent_ae initiate the execution of this function.
  // This function performs prediction of DUT output values based on DUT input, configuration and state
  virtual function void write_control_in_agent_ae(control_in_transaction t);
    // pragma uvmf custom control_in_agent_ae_predictor begin
    control_in_agent_ae_debug = t;
    `uvm_info("PRED", "Transaction Received through control_in_agent_ae", UVM_MEDIUM)
    `uvm_info("PRED", {"            Data: ",t.convert2string()}, UVM_FULL)
    // Construct one of each output transaction type.
    control_sb_ap_output_transaction = control_sb_ap_output_transaction_t::type_id::create("control_sb_ap_output_transaction");
    //predict a control transaction from the provided reference model
    begin
      bit prediction_failed;
      prediction_failed = lc3_prediction_pkg::controller_model(
        t.complete_data,
        t.complete_instr,
        t.IR,
        t.psr,
        t.IR_Exec,
        t.IMem_dout,
        t.NZP,
        control_sb_ap_output_transaction.enable_updatePC,
        control_sb_ap_output_transaction.enable_fetch,
        control_sb_ap_output_transaction.enable_decode,
        control_sb_ap_output_transaction.enable_execute,
        control_sb_ap_output_transaction.enable_writeback,
        control_sb_ap_output_transaction.bypass_alu_1,
        control_sb_ap_output_transaction.bypass_alu_2,
        control_sb_ap_output_transaction.bypass_mem_1,
        control_sb_ap_output_transaction.bypass_mem_2,
        control_sb_ap_output_transaction.mem_state,
        control_sb_ap_output_transaction.br_taken
      );
      if (prediction_failed)
        `uvm_error("CTRL_MODEL", "controller_model returned a failure")

      //the reference model assumes pc advancement is always permitted after reset
      //the actual fetch interface requires completion of a pending instruction fetch
      //branch redirects remain eligible to update the pc without a new instruction response
      if (!t.complete_instr && !control_sb_ap_output_transaction.br_taken)
        control_sb_ap_output_transaction.enable_updatePC = 1'b0;
    end
    control_sb_ap_output_transaction.start_time = t.start_time;
    control_sb_ap_output_transaction.end_time = t.end_time;

    // Code for sending output transaction out through control_sb_ap
    // Please note that each broadcasted transaction should be a different object than previously 
    // broadcasted transactions.  Creation of a different object is done by constructing the transaction 
    // using either new() or create().  Broadcasting a transaction object more than once to either the 
    // same subscriber or multiple subscribers will result in unexpected and incorrect behavior.
    //temporary trace: keep the independent expected outputs unchanged
    // if (control_trace_count < 36) begin
    //   $display("CTRL_REF_DIAG t=%0t n=%0d ci=%b cd=%b ir=%04h ie=%04h id=%04h psr=%01h nzp=%01h pc=%b f=%b d=%b e=%b w=%b br=%b ba1=%b ba2=%b bm1=%b bm2=%b ms=%01h",
    //     $time, control_trace_count,
    //     t.complete_instr, t.complete_data, t.IR, t.IR_Exec, t.IMem_dout,
    //     t.psr, t.NZP,
    //     control_sb_ap_output_transaction.enable_updatePC,
    //     control_sb_ap_output_transaction.enable_fetch,
    //     control_sb_ap_output_transaction.enable_decode,
    //     control_sb_ap_output_transaction.enable_execute,
    //     control_sb_ap_output_transaction.enable_writeback,
    //     control_sb_ap_output_transaction.br_taken,
    //     control_sb_ap_output_transaction.bypass_alu_1,
    //     control_sb_ap_output_transaction.bypass_alu_2,
    //     control_sb_ap_output_transaction.bypass_mem_1,
    //     control_sb_ap_output_transaction.bypass_mem_2,
    //     control_sb_ap_output_transaction.mem_state);
    //   control_trace_count++;
    // end
    control_sb_ap.write(control_sb_ap_output_transaction);
    // pragma uvmf custom control_in_agent_ae_predictor end
  endfunction


endclass 

// pragma uvmf custom external begin
// pragma uvmf custom external end