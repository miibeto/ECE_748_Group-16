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
  // pragma uvmf custom class_item_additional end

  // FUNCTION: new
  function new(string name, uvm_component parent);
     super.new(name,parent);
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
    bit [15:0] dmem_addr_pred;
    bit [15:0] dmem_din_pred;
    bit [15:0] memout_pred;
    bit        dmem_rd_pred;
    bit        model_status;

    memaccess_in_agent_ae_debug = t;
    `uvm_info("PRED", "Transaction Received through memaccess_in_agent_ae", UVM_MEDIUM)
    `uvm_info("PRED", {"            Data: ",t.convert2string()}, UVM_FULL)
    // Construct one of each output transaction type.
    memaccess_sb_ap_output_transaction = memaccess_sb_ap_output_transaction_t::type_id::create("memaccess_sb_ap_output_transaction");

    // call the mem_access_model function to get the expected outputs
    model_status = mem_access_model(
      .M_Data(t.M_Data),
      .M_Addr(t.M_addr),
      .M_Control(t.M_Control),
      .mem_state(t.mem_state),
      .DMem_dout(t.DMem_dout),
      .DMem_addr(dmem_addr_pred),
      .DMem_din(dmem_din_pred),
      .memout(memout_pred),
      .DMem_rd(dmem_rd_pred)
      );

    memaccess_sb_ap_output_transaction.DMem_addr = dmem_addr_pred;
    memaccess_sb_ap_output_transaction.DMem_rd   = dmem_rd_pred;
    memaccess_sb_ap_output_transaction.DMem_din  = dmem_din_pred;
    memaccess_sb_ap_output_transaction.memout    = memout_pred;

    // Code for sending output transaction out through memaccess_sb_ap
    // Please note that each broadcasted transaction should be a different object than previously
    // broadcasted transactions.  Creation of a different object is done by constructing the transaction
    // using either new() or create().  Broadcasting a transaction object more than once to either the
    // same subscriber or multiple subscribers will result in unexpected and incorrect behavior.
    memaccess_sb_ap.write(memaccess_sb_ap_output_transaction);
    // pragma uvmf custom memaccess_in_agent_ae_predictor end
  endfunction


endclass 

// pragma uvmf custom external begin
// pragma uvmf custom external end

