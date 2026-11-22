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
      // Not valid opcodes; excluded from stimulus (see imem_constrained_transaction).
      ignore_bins JSR      = {4'b0100};
      ignore_bins RTI      = {4'b1000};
      ignore_bins RESERVED = {4'b1101};
      ignore_bins TRAP     = {4'b1111};
    }

    // ADD/AND register vs immediate mode, crossed with opcode below.
    imm_mode: coverpoint coverage_trans.dout[5] {
      bins reg_mode = {1'b0};
      bins imm_mode = {1'b1};
    }
    add_and_x_mode: cross opcode, imm_mode {
      ignore_bins non_add_and = !binsof(opcode) intersect {4'b0001, 4'b0101};
    }

    // Source register SR1 / BaseR (bits [8:6]) for instructions that read it.
    sr1: coverpoint coverage_trans.dout[8:6]
      iff (coverage_trans.dout[15:12] inside {4'b0001, 4'b0101, 4'b1001,   // ADD AND NOT
                                              4'b0110, 4'b0111, 4'b1100}) { // LDR STR JMP
      bins r[8] = {[0:7]};
    }

    // Instruction class of this instruction and of the one decoded before it.
    // The 4x4 cross covers every back-to-back combination, including
    // memory-op followed by memory-op (the case that stalled the DUT on Sheet 3).
    cur_class: coverpoint coverage_trans.dout[15:12] {
      bins alu   = {4'b0001, 4'b0101, 4'b1001, 4'b1110};  // ADD AND NOT LEA
      bins load  = {4'b0010, 4'b0110, 4'b1010};           // LD LDR LDI
      bins store = {4'b0011, 4'b0111, 4'b1011};           // ST STR STI
      bins ctrl  = {4'b0000, 4'b1100};                    // BR JMP
      ignore_bins other = {4'b0100, 4'b1000, 4'b1101, 4'b1111};
    }
    prev_class: coverpoint prev_opcode iff (prev_valid) {
      bins alu   = {4'b0001, 4'b0101, 4'b1001, 4'b1110};
      bins load  = {4'b0010, 4'b0110, 4'b1010};
      bins store = {4'b0011, 4'b0111, 4'b1011};
      bins ctrl  = {4'b0000, 4'b1100};
      ignore_bins other = {4'b0100, 4'b1000, 4'b1101, 4'b1111};
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

