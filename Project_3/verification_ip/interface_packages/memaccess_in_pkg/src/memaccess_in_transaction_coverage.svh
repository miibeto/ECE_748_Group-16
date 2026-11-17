//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: This class records memaccess_in transaction information using
//       a covergroup named memaccess_in_transaction_cg.  An instance of this
//       coverage component is instantiated in the uvmf_parameterized_agent
//       if the has_coverage flag is set.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
class memaccess_in_transaction_coverage  extends uvm_subscriber #(.T(memaccess_in_transaction ));

  `uvm_component_utils( memaccess_in_transaction_coverage )

  T coverage_trans;

  // pragma uvmf custom class_item_additional begin
  // pragma uvmf custom class_item_additional end
  
  // ****************************************************************************
  covergroup memaccess_in_transaction_cg;
    // pragma uvmf custom covergroup begin
    // UVMF_CHANGE_ME : Add coverage bins, crosses, exclusions, etc. according to coverage needs.
    option.auto_bin_max=1024;
    option.per_instance=1;
    // mem_state and M_Control only have a few possible values so the default
    // auto bins are already fine for them by themselves. what we actually
    // care about is crossing them, since that's basically LDR vs LDI vs
    // STR vs STI vs idle from mem_access_model - want to see all of those
    mem_state: coverpoint coverage_trans.mem_state;
    M_Control: coverpoint coverage_trans.M_Control;
    cross_state_control: cross mem_state, M_Control;
    // same address-range binning trick as dmem - M_addr is 16 bits so
    // leaving it on default auto bins would never close
    cp_addr: coverpoint coverage_trans.M_addr {
      bins min_addr = {16'h0000};
      bins low      = {[16'h0001:16'h3FFF]};
      bins mid      = {[16'h4000:16'hBFFF]};
      bins high     = {[16'hC000:16'hFFFE]};
      bins max_addr = {16'hFFFF};
    }
    // pragma uvmf custom covergroup end
  endgroup

  // ****************************************************************************
  // FUNCTION : new()
  // This function is the standard SystemVerilog constructor.
  //
  function new(string name="", uvm_component parent=null);
    super.new(name,parent);
    memaccess_in_transaction_cg=new;
  endfunction

  // ****************************************************************************
  // FUNCTION : build_phase()
  // This function is the standard UVM build_phase.
  //
  function void build_phase(uvm_phase phase);
    memaccess_in_transaction_cg.set_inst_name($sformatf("memaccess_in_transaction_cg_%s",get_full_name()));
  endfunction

  // ****************************************************************************
  // FUNCTION: write (T t)
  // This function is automatically executed when a transaction arrives on the
  // analysis_export.  It copies values from the variables in the transaction 
  // to local variables used to collect functional coverage.  
  //
  virtual function void write (T t);
    `uvm_info("COV","Received transaction",UVM_HIGH);
    coverage_trans = t;
    memaccess_in_transaction_cg.sample();
  endfunction

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

