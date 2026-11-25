//instruction-field coverage sampled from admitted decode input transactions
//coverage records observed stimulus, not architectural retirement or correctness
class decode_in_transaction_coverage extends uvm_subscriber #(.T(decode_in_transaction));
  `uvm_component_utils(decode_in_transaction_coverage)
  T coverage_trans;
  int unsigned admitted_count = 0;

  covergroup decode_in_transaction_cg with function sample(bit [15:0] instr);
    option.per_instance = 1;
    opcode: coverpoint instr[15:12] {
      bins br = {4'h0};
      bins add = {4'h1};
      bins ld = {4'h2};
      bins st = {4'h3};
      bins and_op = {4'h5};
      bins ldr = {4'h6};
      bins str = {4'h7};
      bins not_op = {4'h9};
      bins ldi = {4'ha};
      bins sti = {4'hb};
      bins jmp = {4'hc};
      bins lea = {4'he};
      illegal_bins unsupported = {4'h4, 4'h8, 4'hd, 4'hf};
    }
    br_mask: coverpoint instr[11:9] iff (instr[15:12] == 4'h0) {
      bins masks[] = {[0:7]};
    }
    br_offset9: coverpoint instr[8:0] iff (instr[15:12] == 4'h0) {
      bins zero = {0}; bins positive = {[1:254]}; bins negative = {[257:511]}; bins min_negative = {256}; bins max_positive = {255};
    }
    add_dr: coverpoint instr[11:9] iff (instr[15:12] == 4'h1) {
      bins registers[] = {[0:7]};
    }
    add_sr1_base: coverpoint instr[8:6] iff (instr[15:12] == 4'h1) {
      bins registers[] = {[0:7]};
    }
    add_form: coverpoint instr[5] iff (instr[15:12] == 4'h1) {
      bins reg_form = {0}; bins imm_form = {1};
    }
    add_sr2: coverpoint instr[2:0] iff (instr[15:12] == 4'h1 && !instr[5]) {
      bins registers[] = {[0:7]};
    }
    add_imm5: coverpoint instr[4:0] iff (instr[15:12] == 4'h1 && instr[5]) {
      bins values[] = {[0:31]};
    }
    ld_dr: coverpoint instr[11:9] iff (instr[15:12] == 4'h2) {
      bins registers[] = {[0:7]};
    }
    ld_offset9: coverpoint instr[8:0] iff (instr[15:12] == 4'h2) {
      bins zero = {0}; bins positive = {[1:254]}; bins negative = {[257:511]}; bins min_negative = {256}; bins max_positive = {255};
    }
    st_store_sr: coverpoint instr[11:9] iff (instr[15:12] == 4'h3) {
      bins registers[] = {[0:7]};
    }
    st_offset9: coverpoint instr[8:0] iff (instr[15:12] == 4'h3) {
      bins zero = {0}; bins positive = {[1:254]}; bins negative = {[257:511]}; bins min_negative = {256}; bins max_positive = {255};
    }
    and_op_dr: coverpoint instr[11:9] iff (instr[15:12] == 4'h5) {
      bins registers[] = {[0:7]};
    }
    and_op_sr1_base: coverpoint instr[8:6] iff (instr[15:12] == 4'h5) {
      bins registers[] = {[0:7]};
    }
    and_op_form: coverpoint instr[5] iff (instr[15:12] == 4'h5) {
      bins reg_form = {0}; bins imm_form = {1};
    }
    and_op_sr2: coverpoint instr[2:0] iff (instr[15:12] == 4'h5 && !instr[5]) {
      bins registers[] = {[0:7]};
    }
    and_op_imm5: coverpoint instr[4:0] iff (instr[15:12] == 4'h5 && instr[5]) {
      bins values[] = {[0:31]};
    }
    ldr_dr: coverpoint instr[11:9] iff (instr[15:12] == 4'h6) {
      bins registers[] = {[0:7]};
    }
    ldr_sr1_base: coverpoint instr[8:6] iff (instr[15:12] == 4'h6) {
      bins registers[] = {[0:7]};
    }
    ldr_offset6: coverpoint instr[5:0] iff (instr[15:12] == 4'h6) {
      bins zero = {0}; bins positive = {[1:30]}; bins negative = {[33:63]}; bins min_negative = {32}; bins max_positive = {31};
    }
    str_sr1_base: coverpoint instr[8:6] iff (instr[15:12] == 4'h7) {
      bins registers[] = {[0:7]};
    }
    str_store_sr: coverpoint instr[11:9] iff (instr[15:12] == 4'h7) {
      bins registers[] = {[0:7]};
    }
    str_offset6: coverpoint instr[5:0] iff (instr[15:12] == 4'h7) {
      bins zero = {0}; bins positive = {[1:30]}; bins negative = {[33:63]}; bins min_negative = {32}; bins max_positive = {31};
    }
    not_op_dr: coverpoint instr[11:9] iff (instr[15:12] == 4'h9) {
      bins registers[] = {[0:7]};
    }
    not_op_sr1_base: coverpoint instr[8:6] iff (instr[15:12] == 4'h9) {
      bins registers[] = {[0:7]};
    }
    ldi_dr: coverpoint instr[11:9] iff (instr[15:12] == 4'ha) {
      bins registers[] = {[0:7]};
    }
    ldi_offset9: coverpoint instr[8:0] iff (instr[15:12] == 4'ha) {
      bins zero = {0}; bins positive = {[1:254]}; bins negative = {[257:511]}; bins min_negative = {256}; bins max_positive = {255};
    }
    sti_store_sr: coverpoint instr[11:9] iff (instr[15:12] == 4'hb) {
      bins registers[] = {[0:7]};
    }
    sti_offset9: coverpoint instr[8:0] iff (instr[15:12] == 4'hb) {
      bins zero = {0}; bins positive = {[1:254]}; bins negative = {[257:511]}; bins min_negative = {256}; bins max_positive = {255};
    }
    jmp_sr1_base: coverpoint instr[8:6] iff (instr[15:12] == 4'hc) {
      bins registers[] = {[0:7]};
    }
    lea_dr: coverpoint instr[11:9] iff (instr[15:12] == 4'he) {
      bins registers[] = {[0:7]};
    }
    lea_offset9: coverpoint instr[8:0] iff (instr[15:12] == 4'he) {
      bins zero = {0}; bins positive = {[1:254]}; bins negative = {[257:511]}; bins min_negative = {256}; bins max_positive = {255};
    }
  endgroup

  function new(string name="", uvm_component parent=null);
    super.new(name,parent);
    decode_in_transaction_cg = new;
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    decode_in_transaction_cg.set_inst_name($sformatf("decode_in_transaction_cg_%s",get_full_name()));
  endfunction

  virtual function void write(T t);
    if (t == null) return;
    if (!t.enable_decode) return;
    coverage_trans = t;
    admitted_count++;
    decode_in_transaction_cg.sample(t.dout);
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("STAGE71_DECODE_COV", $sformatf("admitted=%0d instance_coverage=%0.2f",admitted_count,decode_in_transaction_cg.get_inst_coverage()), UVM_LOW)
  endfunction
endclass
