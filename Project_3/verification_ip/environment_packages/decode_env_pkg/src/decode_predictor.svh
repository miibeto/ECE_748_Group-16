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
//   decode_in_agent_ae receives transactions of type  decode_in_transaction
//
//   This analysis component has the following analysis_ports that can broadcast 
//   the listed transaction type.
//
//  decode_sb_ap broadcasts transactions of type decode_out_transaction
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//

class decode_predictor #(
  type CONFIG_T,
  type BASE_T = uvm_component
  )
 extends BASE_T;

  // Factory registration of this class
  `uvm_component_param_utils( decode_predictor #(
                              CONFIG_T,
                              BASE_T
                              )
)


  // Instantiate a handle to the configuration of the environment in which this component resides
  CONFIG_T configuration;

  
  // Instantiate the analysis exports
  uvm_analysis_imp_decode_in_agent_ae #(decode_in_transaction, decode_predictor #(
                              .CONFIG_T(CONFIG_T),
                              .BASE_T(BASE_T)
                              )
) decode_in_agent_ae;

  
  // Instantiate the analysis ports
  uvm_analysis_port #(decode_out_transaction) decode_sb_ap;


  // Transaction variable for predicted values to be sent out decode_sb_ap
  // Once a transaction is sent through an analysis_port, another transaction should
  // be constructed for the next predicted transaction. 
  typedef decode_out_transaction decode_sb_ap_output_transaction_t;
  decode_sb_ap_output_transaction_t decode_sb_ap_output_transaction;
  // Code for sending output transaction out through decode_sb_ap
  // decode_sb_ap.write(decode_sb_ap_output_transaction);

  // Define transaction handles for debug visibility 
  decode_in_transaction decode_in_agent_ae_debug;


  // pragma uvmf custom class_item_additional begin
  //expected outputs represent the registered decode state at the current sample
  bit [15:0] expected_ir = '0;
  bit [15:0] expected_npc_out = '0;
  bit [5:0] expected_e_control = '0;
  bit [1:0] expected_w_control = '0;
  bit expected_mem_control = 0;
  int unsigned decode_prediction_count = 0;
  // pragma uvmf custom class_item_additional end

  // FUNCTION: new
  function new(string name, uvm_component parent);
     super.new(name,parent);
    `uvm_warning("PREDICTOR_REVIEW", "This predictor has been created either through generation or re-generation with merging.  Remove this warning after the predictor has been reviewed.")
  // pragma uvmf custom new begin
  // pragma uvmf custom new end
  endfunction

  // FUNCTION: build_phase
  virtual function void build_phase (uvm_phase phase);

    decode_in_agent_ae = new("decode_in_agent_ae", this);
    decode_sb_ap =new("decode_sb_ap", this );
  // pragma uvmf custom build_phase begin
  // pragma uvmf custom build_phase end
  endfunction

  // FUNCTION: write_decode_in_agent_ae
  // Transactions received through decode_in_agent_ae initiate the execution of this function.
  // This function performs prediction of DUT output values based on DUT input, configuration and state
  virtual function void write_decode_in_agent_ae(decode_in_transaction t);
    // pragma uvmf custom decode_in_agent_ae_predictor begin
    bit decode_failed;
    bit [15:0] next_ir;
    bit [15:0] next_npc_out;
    bit [5:0] next_e_control;
    bit [1:0] next_w_control;
    bit next_mem_control;

    decode_in_agent_ae_debug = t;
    decode_sb_ap_output_transaction = decode_sb_ap_output_transaction_t::type_id::create(
      "decode_sb_ap_output_transaction");

    //compare the registered value from the preceding sampling interval
    decode_sb_ap_output_transaction.ir = expected_ir;
    decode_sb_ap_output_transaction.npc_out = expected_npc_out;
    decode_sb_ap_output_transaction.e_control = expected_e_control;
    decode_sb_ap_output_transaction.w_control = expected_w_control;
    decode_sb_ap_output_transaction.mem_control = expected_mem_control;
    decode_sb_ap_output_transaction.start_time = t.start_time;
    decode_sb_ap_output_transaction.end_time = t.end_time;

    if (decode_prediction_count < 32) begin
      $display("DEC_REF_DIAG t=%0t n=%0d en=%b dout=%04h npc_in=%04h pred_ir=%04h pred_npc=%04h pred_e=%02h pred_w=%01h pred_m=%b",
        $time, decode_prediction_count, t.enable_decode, t.dout, t.npc_in,
        expected_ir, expected_npc_out, expected_e_control,
        expected_w_control, expected_mem_control);
    end
    decode_prediction_count++;
    decode_sb_ap.write(decode_sb_ap_output_transaction);

    //the decode outputs are clocked; update expected state for next sampled cycle
    if (t.enable_decode) begin
      decode_failed = lc3_prediction_pkg::decode_model(
        t.dout, t.npc_in,
        next_ir, next_npc_out, next_e_control,
        next_w_control, next_mem_control);
      if (decode_failed)
        `uvm_error("DECODE_MODEL", "decode_model returned failure")
      else begin
        expected_ir = next_ir;
        expected_npc_out = next_npc_out;
        expected_e_control = next_e_control;
        expected_w_control = next_w_control;
        expected_mem_control = next_mem_control;
      end
    end
    // pragma uvmf custom decode_in_agent_ae_predictor end
  endfunction


endclass 

// pragma uvmf custom external begin
// pragma uvmf custom external end

