//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: This class records memaccess_out transaction information using
//       a covergroup named memaccess_out_transaction_cg.  An instance of this
//       coverage component is instantiated in the uvmf_parameterized_agent
//       if the has_coverage flag is set.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
class memaccess_out_transaction_coverage  extends uvm_subscriber #(.T(memaccess_out_transaction ));

  `uvm_component_utils( memaccess_out_transaction_coverage )

  T coverage_trans;

  // pragma uvmf custom class_item_additional begin
  // pragma uvmf custom class_item_additional end
  
  // ****************************************************************************
  covergroup memaccess_out_transaction_cg;
    // pragma uvmf custom covergroup begin
    // UVMF_CHANGE_ME : Add coverage bins, crosses, exclusions, etc. according to coverage needs.
    option.auto_bin_max=1024;
    option.per_instance=1;
    // just a 1 bit signal so default bins are fine here
    DMem_rd: coverpoint coverage_trans.DMem_rd;
    // this is the address about to get sent to dmem, same deal as the other
    // two coverage files - bin by range instead of 1024 individual values
    cp_addr: coverpoint coverage_trans.DMem_addr {
      bins min_addr = {16'h0000};
      bins low      = {[16'h0001:16'h3FFF]};
      bins mid      = {[16'h4000:16'hBFFF]};
      bins high     = {[16'hC000:16'hFFFE]};
      bins max_addr = {16'hFFFF};
    }
    cross_rd_addr: cross DMem_rd, cp_addr;
    // pragma uvmf custom covergroup end
  endgroup

  // ****************************************************************************
  // FUNCTION : new()
  // This function is the standard SystemVerilog constructor.
  //
  function new(string name="", uvm_component parent=null);
    super.new(name,parent);
    memaccess_out_transaction_cg=new;
  endfunction

  // ****************************************************************************
  // FUNCTION : build_phase()
  // This function is the standard UVM build_phase.
  //
  function void build_phase(uvm_phase phase);
    memaccess_out_transaction_cg.set_inst_name($sformatf("memaccess_out_transaction_cg_%s",get_full_name()));
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
    memaccess_out_transaction_cg.sample();
  endfunction

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

