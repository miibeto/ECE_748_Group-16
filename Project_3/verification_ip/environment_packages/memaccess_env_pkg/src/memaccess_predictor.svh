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
//   memaccess_in_agent_ae receives transactions of type  memaccess_in_transaction
//
//   This analysis component has the following analysis_ports that can broadcast 
//   the listed transaction type.
//
//  memaccess_sb_ap broadcasts transactions of type memaccess_out_transaction
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//

class memaccess_predictor #(
  type CONFIG_T,
  type BASE_T = uvm_component
  )
 extends BASE_T;

  // Factory registration of this class
  `uvm_component_param_utils( memaccess_predictor #(
                              CONFIG_T,
                              BASE_T
                              )
)


  // Instantiate a handle to the configuration of the environment in which this component resides
  CONFIG_T configuration;

  
  // Instantiate the analysis exports
  uvm_analysis_imp_memaccess_in_agent_ae #(memaccess_in_transaction, memaccess_predictor #(
                              .CONFIG_T(CONFIG_T),
                              .BASE_T(BASE_T)
                              )
) memaccess_in_agent_ae;

  
  // Instantiate the analysis ports
  uvm_analysis_port #(memaccess_out_transaction) memaccess_sb_ap;


  // Transaction variable for predicted values to be sent out memaccess_sb_ap
  // Once a transaction is sent through an analysis_port, another transaction should
  // be constructed for the next predicted transaction. 
  typedef memaccess_out_transaction memaccess_sb_ap_output_transaction_t;
  memaccess_sb_ap_output_transaction_t memaccess_sb_ap_output_transaction;
  // Code for sending output transaction out through memaccess_sb_ap
  // memaccess_sb_ap.write(memaccess_sb_ap_output_transaction);

  // Define transaction handles for debug visibility 
  memaccess_in_transaction memaccess_in_agent_ae_debug;


  // pragma uvmf custom class_item_additional begin
  int unsigned memaccess_prediction_count = 0;
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

    memaccess_in_agent_ae = new("memaccess_in_agent_ae", this);
    memaccess_sb_ap =new("memaccess_sb_ap", this );
  // pragma uvmf custom build_phase begin
  // pragma uvmf custom build_phase end
  endfunction

  // FUNCTION: write_memaccess_in_agent_ae
  // Transactions received through memaccess_in_agent_ae initiate the execution of this function.
  // This function performs prediction of DUT output values based on DUT input, configuration and state
  virtual function void write_memaccess_in_agent_ae(memaccess_in_transaction t);
    // pragma uvmf custom memaccess_in_agent_ae_predictor begin
    bit model_failed;
    bit [15:0] expected_addr;
    bit [15:0] expected_din;
    bit [15:0] expected_memout;
    bit expected_rd;

    memaccess_in_agent_ae_debug = t;
    memaccess_sb_ap_output_transaction = memaccess_sb_ap_output_transaction_t::type_id::create(
      "memaccess_sb_ap_output_transaction");

    //the memory access unit is combinational; predict this sample directly
    model_failed = lc3_prediction_pkg::mem_access_model(
      t.M_Data,
      t.M_addr,
      t.M_Control,
      t.mem_state,
      t.DMem_dout,
      expected_addr,
      expected_din,
      expected_memout,
      expected_rd);

    if (model_failed)
      `uvm_error("MEMACCESS_MODEL", "mem_access_model returned failure")

    memaccess_sb_ap_output_transaction.DMem_addr = expected_addr;
    memaccess_sb_ap_output_transaction.DMem_din = expected_din;
    memaccess_sb_ap_output_transaction.memout = expected_memout;
    memaccess_sb_ap_output_transaction.DMem_rd = expected_rd;
    memaccess_sb_ap_output_transaction.start_time = t.start_time;
    memaccess_sb_ap_output_transaction.end_time = t.end_time;

    if (memaccess_prediction_count < 80) begin
      $display("MEM_REF_DIAG t=%0t n=%0d ms=%0h mc=%b md=%04h ma=%04h dout=%04h pred_addr=%04h pred_rd=%b pred_din=%04h pred_memout=%04h",
        $time, memaccess_prediction_count, t.mem_state, t.M_Control,
        t.M_Data, t.M_addr, t.DMem_dout, expected_addr, expected_rd,
        expected_din, expected_memout);
    end
    memaccess_prediction_count++;
    memaccess_sb_ap.write(memaccess_sb_ap_output_transaction);
    // pragma uvmf custom memaccess_in_agent_ae_predictor end
  endfunction


endclass 

// pragma uvmf custom external begin
// pragma uvmf custom external end

