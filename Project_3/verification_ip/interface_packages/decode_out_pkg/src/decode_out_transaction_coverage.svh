//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: This class records decode_out transaction information using
//       a covergroup named decode_out_transaction_cg.  An instance of this
//       coverage component is instantiated in the uvmf_parameterized_agent
//       if the has_coverage flag is set.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
class decode_out_transaction_coverage  extends uvm_subscriber #(.T(decode_out_transaction ));

  `uvm_component_utils( decode_out_transaction_coverage )

  T coverage_trans;

  // pragma uvmf custom class_item_additional begin
  // pragma uvmf custom class_item_additional end
  
  // ****************************************************************************
  covergroup decode_out_transaction_cg;
    // pragma uvmf custom covergroup begin
    // Every control value the reference decode_model can produce was seen
    // at the decoder output (ir/npc_out are checked by decode_sb, not covered).
    option.per_instance = 1;
    w_control: coverpoint coverage_trans.w_control {
      bins alu_or_none = {2'd0};   // ALU result / no writeback select
      bins mem         = {2'd1};   // LD LDR LDI
      bins pc          = {2'd2};   // LEA
      illegal_bins bad = {2'd3};
    }
    mem_control: coverpoint coverage_trans.mem_control {
      bins direct   = {1'b0};
      bins indirect = {1'b1};      // LDI STI
    }
    e_control: coverpoint coverage_trans.e_control {
      bins add_imm  = {6'b000000};
      bins add_reg  = {6'b000001};
      bins and_imm  = {6'b010000};
      bins and_reg  = {6'b010001};
      bins not_op   = {6'b100000};
      bins pc_off9  = {6'b000110};  // BR LD LDI LEA ST STI
      bins base_off = {6'b001000};  // LDR STR
      bins jmp      = {6'b001100};
    }
    // pragma uvmf custom covergroup end
  endgroup

  // ****************************************************************************
  // FUNCTION : new()
  // This function is the standard SystemVerilog constructor.
  //
  function new(string name="", uvm_component parent=null);
    super.new(name,parent);
    decode_out_transaction_cg=new;
  endfunction

  // ****************************************************************************
  // FUNCTION : build_phase()
  // This function is the standard UVM build_phase.
  //
  function void build_phase(uvm_phase phase);
    decode_out_transaction_cg.set_inst_name($sformatf("decode_out_transaction_cg_%s",get_full_name()));
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
    decode_out_transaction_cg.sample();
  endfunction

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

