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

    // Primary instruction coverage: one bin per valid LC3 opcode (bits [15:12]
    // of the instruction word delivered to Decode). See
    // lc3_prediction_pkg::opcode_t for the encoding.
    opcode: coverpoint coverage_trans.Instr_dout[15:12] {
      bins BR       = {4'b0000};
      bins ADD      = {4'b0001};
      bins LD       = {4'b0010};
      bins ST       = {4'b0011};
      bins AND      = {4'b0101};
      bins LDR      = {4'b0110};
      bins STR      = {4'b0111};
      bins NOT      = {4'b1001};
      bins LDI      = {4'b1010};
      bins STI      = {4'b1011};
      bins JMP      = {4'b1100};
      bins LEA      = {4'b1110};
      // Not valid opcodes for this project; excluded from stimulus by
      // imem_constrained_transaction::legal_opcode_c.
      ignore_bins JSR      = {4'b0100};
      ignore_bins RTI      = {4'b1000};
      ignore_bins RESERVED = {4'b1101};
      ignore_bins TRAP     = {4'b1111};
    }

    // ADD/AND immediate-mode bit (bit 5): 0 = register mode, 1 = immediate.
    // Only meaningful for ADD and AND; crossed below.
    add_and_imm_mode: coverpoint coverage_trans.Instr_dout[5] {
      bins reg_mode = {1'b0};
      bins imm_mode = {1'b1};
    }

    // BR condition code bits (bits 11:9 = N, Z, P).
    // Per Sheet 5, NZP == 000 is illegal (no-op branch) and must not be hit;
    // it is flagged as an illegal bin so the covergroup errors if it appears.
    br_nzp: coverpoint coverage_trans.Instr_dout[11:9] iff (coverage_trans.Instr_dout[15:12] == 4'b0000) {
      illegal_bins none = {3'b000};
      bins n_only  = {3'b100};
      bins z_only  = {3'b010};
      bins p_only  = {3'b001};
      bins nz      = {3'b110};
      bins np      = {3'b101};
      bins zp      = {3'b011};
      bins nzp     = {3'b111};
    }

    // ADD/AND imm5 signed field (bits [4:0]) per Sheet 5: signed -16..+15.
    // Three bins cover the sign space (negative / zero / positive).
    add_and_imm5: coverpoint $signed(coverage_trans.Instr_dout[4:0])
      iff ( (coverage_trans.Instr_dout[15:12] inside {4'b0001, 4'b0101})
             && coverage_trans.Instr_dout[5] == 1'b1 ) {
      bins neg  = {[-16:-1]};
      bins zero = {0};
      bins pos  = {[1:15]};
    }

    // PC-relative 9-bit signed offset used by LD/LDI/LEA/ST/STI (Sheet 5).
    pc_offset9: coverpoint $signed(coverage_trans.Instr_dout[8:0])
      iff ( coverage_trans.Instr_dout[15:12] inside {4'b0010,  // LD
                                                      4'b0011,  // ST
                                                      4'b1010,  // LDI
                                                      4'b1011,  // STI
                                                      4'b1110   // LEA
                                                    } ) {
      bins neg  = {[-256:-1]};
      bins zero = {0};
      bins pos  = {[1:255]};
    }

    // LDR/STR 6-bit signed base offset (Sheet 5).
    offset6: coverpoint $signed(coverage_trans.Instr_dout[5:0])
      iff ( coverage_trans.Instr_dout[15:12] inside {4'b0110, 4'b0111} ) {
      bins neg  = {[-32:-1]};
      bins zero = {0};
      bins pos  = {[1:31]};
    }

    // Destination register (bits [11:9]) exercised across all 8 values.
    dr: coverpoint coverage_trans.Instr_dout[11:9]
      iff ( coverage_trans.Instr_dout[15:12] inside {4'b0001, 4'b0101, 4'b1001,
                                                     4'b0010, 4'b1010, 4'b1110,
                                                     4'b0011, 4'b1011,
                                                     4'b0110, 4'b0111} ) {
      bins r[8] = {[0:7]};
    }

    // Crosses: opcode x imm mode (only meaningful for ADD and AND).
    add_x_mode: cross opcode, add_and_imm_mode {
      ignore_bins non_add_and = !binsof(opcode) intersect {4'b0001, 4'b0101};
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
    coverage_trans = t;
    imem_transaction_cg.sample();
  endfunction

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

