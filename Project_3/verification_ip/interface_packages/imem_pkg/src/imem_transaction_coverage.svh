//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: This class records imem transaction information using
//       a covergroup named imem_transaction_cg.  An instance of this
//       coverage component is instantiated in the uvmf_parameterized_agent
//       if the has_coverage flag is set.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
class imem_transaction_coverage  extends uvm_subscriber #(.T(imem_transaction ));

  `uvm_component_utils( imem_transaction_coverage )

  T coverage_trans;

  // pragma uvmf custom class_item_additional begin
  // pragma uvmf custom class_item_additional end
  
  // ****************************************************************************
  covergroup imem_transaction_cg;
    // pragma uvmf custom covergroup begin
    option.per_instance = 1;

    // Primary instruction coverage: one bin per LC3 opcode (bits [15:12] of
    // the instruction word delivered to Decode). Illegal/reserved opcodes
    // (RTI=0x8, RESERVED=0xD) are binned separately so tests that exclude
    // them can be verified. See lc3_prediction_pkg::opcode_t for the encoding.
    opcode: coverpoint coverage_trans.Instr_dout[15:12] {
      bins BR       = {4'b0000};
      bins ADD      = {4'b0001};
      bins LD       = {4'b0010};
      bins ST       = {4'b0011};
      bins JSR      = {4'b0100};
      bins AND      = {4'b0101};
      bins LDR      = {4'b0110};
      bins STR      = {4'b0111};
      bins RTI      = {4'b1000};
      bins NOT      = {4'b1001};
      bins LDI      = {4'b1010};
      bins STI      = {4'b1011};
      bins JMP      = {4'b1100};
      bins RESERVED = {4'b1101};
      bins LEA      = {4'b1110};
      bins TRAP     = {4'b1111};
    }

    // ADD/AND immediate-mode bit (bit 5): 0 = register mode, 1 = immediate.
    // Only meaningful for ADD and AND; crossed below.
    add_and_imm_mode: coverpoint coverage_trans.Instr_dout[5] {
      bins reg_mode = {1'b0};
      bins imm_mode = {1'b1};
    }

    // BR condition code bits (bits 11:9 = N, Z, P).
    br_nzp: coverpoint coverage_trans.Instr_dout[11:9] iff (coverage_trans.Instr_dout[15:12] == 4'b0000) {
      bins nop     = {3'b000};
      bins n_only  = {3'b100};
      bins z_only  = {3'b010};
      bins p_only  = {3'b001};
      bins nz      = {3'b110};
      bins np      = {3'b101};
      bins zp      = {3'b011};
      bins nzp     = {3'b111};
    }

    // JSR vs JSRR distinguishing bit (bit 11).
    jsr_mode: coverpoint coverage_trans.Instr_dout[11] iff (coverage_trans.Instr_dout[15:12] == 4'b0100) {
      bins jsrr = {1'b0};
      bins jsr  = {1'b1};
    }

    // Crosses that give meaningful per-opcode coverage of the mode bit.
    add_x_mode: cross opcode, add_and_imm_mode {
      ignore_bins non_add_and = binsof(opcode) intersect {4'b0000, 4'b0010, 4'b0011, 4'b0100,
                                                          4'b0110, 4'b0111, 4'b1000, 4'b1001,
                                                          4'b1010, 4'b1011, 4'b1100, 4'b1101,
                                                          4'b1110, 4'b1111};
    }
    // pragma uvmf custom covergroup end
  endgroup

  // ****************************************************************************
  // FUNCTION : new()
  // This function is the standard SystemVerilog constructor.
  //
  function new(string name="", uvm_component parent=null);
    super.new(name,parent);
    imem_transaction_cg=new;
    `uvm_warning("COVERAGE_MODEL_REVIEW", "A covergroup has been constructed which may need review because of either generation or re-generation with merging.  Please note that transaction variables added as a result of re-generation and merging are not automatically added to the covergroup.  Remove this warning after the covergroup has been reviewed.")
  endfunction

  // ****************************************************************************
  // FUNCTION : build_phase()
  // This function is the standard UVM build_phase.
  //
  function void build_phase(uvm_phase phase);
    imem_transaction_cg.set_inst_name($sformatf("imem_transaction_cg_%s",get_full_name()));
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
    imem_transaction_cg.sample();
  endfunction

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

