//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
//instruction coverage for completed, observed instruction-memory fetches
//----------------------------------------------------------------------
class imem_transaction_coverage extends uvm_subscriber #(.T(imem_transaction));

  `uvm_component_utils(imem_transaction_coverage)

  T coverage_trans;

  bit [3:0] opcode_sample;
  bit [2:0] dr_sample;
  bit [2:0] sr1_sample;
  bit immediate_sample;
  bit [2:0] branch_mask_sample;
  bit [1:0] offset_class_sample;
  bit has_offset_sample;
  bit [2:0] memory_type_sample;
  bit is_memory_sample;
  int unsigned completed_fetch_count = 0;

  //the lc3 design specification supports exactly twelve instructions
  covergroup imem_transaction_cg;
    option.per_instance = 1;

    opcode: coverpoint opcode_sample {
      bins br   = {4'h0};
      bins add  = {4'h1};
      bins ld   = {4'h2};
      bins st   = {4'h3};
      bins and_ = {4'h5};
      bins ldr  = {4'h6};
      bins str  = {4'h7};
      bins not_ = {4'h9};
      bins ldi  = {4'ha};
      bins sti  = {4'hb};
      bins jmp  = {4'hc};
      bins lea  = {4'he};
      illegal_bins unsupported_opcode = {4'h4, 4'h8, 4'hd, 4'hf};
    }

    destination_register: coverpoint dr_sample
      iff (opcode_sample inside {4'h1, 4'h2, 4'h5, 4'h6, 4'h9, 4'ha, 4'he}) {
      bins r0_to_r7[] = {[0:7]};
    }

    source_register: coverpoint sr1_sample
      iff (opcode_sample inside {4'h1, 4'h5, 4'h6, 4'h7, 4'h9, 4'hc}) {
      bins r0_to_r7[] = {[0:7]};
    }

    alu_operand_form: coverpoint immediate_sample
      iff (opcode_sample inside {4'h1, 4'h5}) {
      bins register = {0};
      bins immediate = {1};
    }

    branch_condition: coverpoint branch_mask_sample iff (opcode_sample == 4'h0) {
      bins never = {3'b000};
      bins n = {3'b100};
      bins z = {3'b010};
      bins p = {3'b001};
      bins nz = {3'b110};
      bins np = {3'b101};
      bins zp = {3'b011};
      bins unconditional = {3'b111};
    }


    memory_operation: coverpoint memory_type_sample iff (is_memory_sample) {
      bins ld  = {0};
      bins st  = {1};
      bins ldr = {2};
      bins str = {3};
      bins ldi = {4};
      bins sti = {5};
    }

    offset_sign: coverpoint offset_class_sample iff (has_offset_sample) {
      bins zero = {0};
      bins positive = {1};
      bins negative = {2};
    }

  endgroup

  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);
    imem_transaction_cg = new;
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imem_transaction_cg.set_inst_name($sformatf("imem_transaction_cg_%s", get_full_name()));
  endfunction

  virtual function void write(T t);
    bit [15:0] instr;
    int signed offset_value;

    if (t == null)
      return;
    if (!t.instrmem_rd || !t.complete_instr)
      return;

    coverage_trans = t;
    instr = t.Instr_dout;
    opcode_sample = instr[15:12];
    dr_sample = instr[11:9];
    sr1_sample = instr[8:6];
    immediate_sample = instr[5];
    branch_mask_sample = instr[11:9];
    has_offset_sample = 0;
    offset_value = 0;
    is_memory_sample = 0;
    memory_type_sample = 0;

    case (opcode_sample)
      4'h0, 4'h2, 4'h3, 4'ha, 4'hb, 4'he: begin
        has_offset_sample = 1;
        offset_value = $signed({{23{instr[8]}}, instr[8:0]});
      end
      4'h6, 4'h7: begin
        has_offset_sample = 1;
        offset_value = $signed({{26{instr[5]}}, instr[5:0]});
      end
      default: begin
      end
    endcase

    case (opcode_sample)
      4'h2: begin is_memory_sample = 1; memory_type_sample = 0; end
      4'h3: begin is_memory_sample = 1; memory_type_sample = 1; end
      4'h6: begin is_memory_sample = 1; memory_type_sample = 2; end
      4'h7: begin is_memory_sample = 1; memory_type_sample = 3; end
      4'ha: begin is_memory_sample = 1; memory_type_sample = 4; end
      4'hb: begin is_memory_sample = 1; memory_type_sample = 5; end
      default: begin
      end
    endcase

    if (offset_value < 0)
      offset_class_sample = 2;
    else if (offset_value > 0)
      offset_class_sample = 1;
    else
      offset_class_sample = 0;

    completed_fetch_count++;
    imem_transaction_cg.sample();
    if (completed_fetch_count <= 24)
      `uvm_info("INSTR_COV", $sformatf("fetch=%0d pc=%04h instr=%04h opcode=%h", 
        completed_fetch_count, t.PC, instr, opcode_sample), UVM_MEDIUM)
  endfunction

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end
