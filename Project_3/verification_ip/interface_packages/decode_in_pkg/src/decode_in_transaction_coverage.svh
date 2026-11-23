//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: This class records decode_in transaction information using
//       a covergroup named decode_in_transaction_cg.  An instance of this
//       coverage component is instantiated in the uvmf_parameterized_agent
//       if the has_coverage flag is set.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
class decode_in_transaction_coverage  extends uvm_subscriber #(.T(decode_in_transaction ));

  `uvm_component_utils( decode_in_transaction_coverage )

  T coverage_trans;

  // pragma uvmf custom class_item_additional begin
  // pragma uvmf custom class_item_additional end
  
  // ****************************************************************************
  // Previous decoded opcode, for back-to-back instruction-class coverage.
  bit [3:0] prev_opcode;
  bit       prev_valid = 1'b0;

  // ****************************************************************************
  // Counts instructions the Decode stage actually ACCEPTED (the monitor only
  // publishes when enable_decode==1), as opposed to imem_transaction_cg, which
  // counts instructions delivered by instruction memory.
  covergroup decode_in_transaction_cg;
    // pragma uvmf custom covergroup begin
    option.per_instance = 1;

    opcode: coverpoint coverage_trans.dout[15:12] {
      bins BR   = {4'b0000};
      bins ADD  = {4'b0001};
      bins LD   = {4'b0010};
      bins ST   = {4'b0011};
      bins AND  = {4'b0101};
      bins LDR  = {4'b0110};
      bins STR  = {4'b0111};
      bins NOT  = {4'b1001};
      bins LDI  = {4'b1010};
      bins STI  = {4'b1011};
      bins JMP  = {4'b1100};
      bins LEA  = {4'b1110};
      // Excluded from stimulus (see imem_constrained_transaction).
      ignore_bins RTI      = {4'b1000};
      ignore_bins RESERVED = {4'b1101};
      ignore_bins TRAP     = {4'b1111};
      ignore_bins JSR      = {4'b0100};
    }

    // ADD/AND register vs immediate mode, crossed with opcode below.
    imm_mode: coverpoint coverage_trans.dout[5] {
      bins reg_mode = {1'b0};
      bins imm_mode = {1'b1};
    }
    imm_sign: coverpoint coverage_trans.dout[4]
      iff (coverage_trans.dout[15:12] inside {4'b0001, 4'b0101} && coverage_trans.dout[5] == 1'b1) {
      bins negative     = {1'b1};
      bins non_negative = {1'b0};
    }
    add_and_x_mode: cross opcode, imm_mode {
      ignore_bins non_add_and = !binsof(opcode) intersect {4'b0001, 4'b0101};
    }

    // Source register SR1 / BaseR (bits [8:6]) for instructions that read it.
    sr1: coverpoint coverage_trans.dout[8:6]
      iff (coverage_trans.dout[15:12] inside {4'b0001, 4'b0101, 4'b1001,   // ADD AND NOT
                                              4'b0110, 4'b0111, 4'b1100}) { // LDR STR JMP
      bins r[8] = {[0:7]};  // Creates eight automatically named bins (r[0], r[1], ... r[7])
    }
    // Source register SR2 / BaseR (bits [2:0]) for instructions that read it.
    sr2: coverpoint coverage_trans.dout[2:0]
      iff ( (coverage_trans.dout[15:12] inside {4'b0001, 4'b0101}) // ADD AND
            && coverage_trans.dout[5] == 1'b0 ) { // Non-immediate mode
      bins r[8] = {[0:7]};
    }
    // Desintation register DR for instructions that write to it.
    dr: coverpoint coverage_trans.dout[11:9]
      iff (coverage_trans.dout[15:12] inside {
        4'b0001, 4'b0101, 4'b1001, 4'b0010, // ADD AND NOT LD LDI LEA
        4'b1010, 4'b1110
      }) {
      bins r[8] = {[0:7]};
    }

    store_sr: coverpoint coverage_trans.dout[11:9]
      iff (coverage_trans.dout[15:12] inside {4'b0011, 4'b0111, 4'b1011}) { // ST STR STI
      bins r[8] = {[0:7]};
    }

    // BR condition code bits (bits 11:9 = N, Z, P).
    // NZP == 000 is illegal (no-op branch) and must not be hit;
    // it is flagged as an illegal bin so the covergroup errors if it appears.
    br_nzp: coverpoint coverage_trans.dout[11:9] iff (coverage_trans.dout[15:12] == 4'b0000) {
      illegal_bins none = {3'b000};
      bins n_only  = {3'b100};
      bins z_only  = {3'b010};
      bins p_only  = {3'b001};
      bins nz      = {3'b110};
      bins np      = {3'b101};
      bins zp      = {3'b011};
      bins nzp     = {3'b111};
    }

    // Source register is the same as the destination
    source_is_destination: coverpoint
      (coverage_trans.dout[8:6] == coverage_trans.dout[11:9])
      iff (coverage_trans.dout[15:12] inside {4'b0001, 4'b0101, 4'b1001,
                                             4'b0110, 4'b0111, 4'b1100}) {
      bins same = {1'b1};
      bins different = {1'b0};
    }
    // PC-relative 9-bit signed offset used by LD/LDI/LEA/ST/STI 
    pc_offset9: coverpoint $signed(coverage_trans.dout[8:0])
      iff ( coverage_trans.dout[15:12] inside {4'b0010,  // LD
                                                      4'b0011,  // ST
                                                      4'b1010,  // LDI
                                                      4'b1011,  // STI
                                                      4'b1110   // LEA
                                                    } ) {
      bins neg  = {[-256:-1]};
      bins zero = {0};
      bins pos  = {[1:255]};
    }
    // LDR/STR 6-bit signed base offset
    offset6: coverpoint $signed(coverage_trans.dout[5:0])
      iff ( coverage_trans.dout[15:12] inside {4'b0110, 4'b0111} ) {
      bins neg  = {[-32:-1]};
      bins zero = {0};
      bins pos  = {[1:31]};
    }

    // Instruction class of this instruction and of the one decoded before it.
    // The 4x4 cross covers every back-to-back combination, including
    // memory-op followed by memory-op 
    cur_class: coverpoint coverage_trans.dout[15:12] {
      bins alu   = {4'b0001, 4'b0101, 4'b1001, 4'b1110};  // ADD AND NOT LEA
      bins load  = {4'b0010, 4'b0110, 4'b1010};           // LD LDR LDI
      bins store = {4'b0011, 4'b0111, 4'b1011};           // ST STR STI
      bins ctrl  = {4'b0000, 4'b0100, 4'b1100, 4'b1111};  // BR JSR JMP TRAP
      ignore_bins other = {4'b1000, 4'b1101};
    }
    prev_class: coverpoint prev_opcode iff (prev_valid) {
      bins alu   = {4'b0001, 4'b0101, 4'b1001, 4'b1110};
      bins load  = {4'b0010, 4'b0110, 4'b1010};
      bins store = {4'b0011, 4'b0111, 4'b1011};
      bins ctrl  = {4'b0000, 4'b0100, 4'b1100, 4'b1111};
      ignore_bins other = {4'b1000, 4'b1101};
    }
    back_to_back: cross prev_class, cur_class;
    // pragma uvmf custom covergroup end
  endgroup

  // ****************************************************************************
  // FUNCTION : new()
  // This function is the standard SystemVerilog constructor.
  //
  function new(string name="", uvm_component parent=null);
    super.new(name,parent);
    decode_in_transaction_cg=new;
  endfunction

  // ****************************************************************************
  // FUNCTION : build_phase()
  // This function is the standard UVM build_phase.
  //
  function void build_phase(uvm_phase phase);
    decode_in_transaction_cg.set_inst_name($sformatf("decode_in_transaction_cg_%s",get_full_name()));
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
    decode_in_transaction_cg.sample();
    prev_opcode = t.dout[15:12];
    prev_valid  = 1'b1;
  endfunction

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

