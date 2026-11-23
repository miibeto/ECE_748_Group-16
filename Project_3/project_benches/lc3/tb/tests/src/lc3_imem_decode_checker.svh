//----------------------------------------------------------------------
// lc3_imem_decode_checker
//
// Cross-checks the instruction stream delivered by instruction memory
// (imem agent) against the instructions accepted by the Decode stage
// (decode_in agent, published only when enable_decode==1).
//
// Every decoded instruction must be one of the next MAX_SKIP+1 fetched
// instructions, in order. This catches the Decode stage accepting an
// instruction twice, accepting a stale instruction, or accepting them out
// of order. Fetched instructions that are never decoded (e.g. fetched on a
// path that was then discarded) are skipped and counted, not flagged, and
// the total is printed in report_phase.
//
// Note: decode_in.dout and imem Instr_dout are the same net in hdl_top,
// so this checks enable_decode/fetch timing, not data corruption.
//----------------------------------------------------------------------

`uvm_analysis_imp_decl(_i2d_imem)
`uvm_analysis_imp_decl(_i2d_dec)

class lc3_imem_decode_checker extends uvm_component;

  `uvm_component_utils( lc3_imem_decode_checker )

  localparam int MAX_SKIP = 4;

  uvm_analysis_imp_i2d_imem #(imem_transaction,      lc3_imem_decode_checker) imem_export;
  uvm_analysis_imp_i2d_dec  #(decode_in_transaction, lc3_imem_decode_checker) dec_export;

  protected bit [15:0] fetched[$];   // delivered by imem, not yet decoded
  protected bit [15:0] decoded[$];   // decoded before its fetch was published
                                     // (both monitors fire on the same edge)
  protected int unsigned n_fetched, n_decoded, n_matched, n_skipped, n_errors;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    imem_export = new("imem_export", this);
    dec_export  = new("dec_export",  this);
  endfunction

  virtual function void write_i2d_imem(imem_transaction t);
    n_fetched++;
    fetched.push_back(t.Instr_dout);
    resolve();
  endfunction

  virtual function void write_i2d_dec(decode_in_transaction t);
    n_decoded++;
    decoded.push_back(t.dout);
    resolve();
  endfunction

  protected function void resolve();
    while (decoded.size() > 0 && fetched.size() > 0) begin
      int idx = -1;
      for (int i = 0; i < fetched.size() && i <= MAX_SKIP; i++)
        if (fetched[i] == decoded[0]) begin idx = i; break; end

      if (idx < 0) begin
        // The matching fetch may not be published yet (same-edge ordering).
        if (fetched.size() <= MAX_SKIP) return;
        n_errors++;
        `uvm_error("IMEM2DEC", $sformatf(
          "decoded instr 0x%04h is not among the next %0d fetched instructions (next fetched: 0x%04h)",
          decoded[0], MAX_SKIP+1, fetched[0]))
        void'(decoded.pop_front());
        continue;
      end

      if (idx > 0)
        `uvm_info("IMEM2DEC", $sformatf("%0d fetched instr(s) not decoded before 0x%04h (first skipped 0x%04h)",
                                        idx, decoded[0], fetched[0]), UVM_MEDIUM)
      repeat (idx) void'(fetched.pop_front());
      n_skipped += idx;
      void'(fetched.pop_front());
      void'(decoded.pop_front());
      n_matched++;
    end
  endfunction

  virtual function void check_phase(uvm_phase phase);
    if (decoded.size() > 0)
      `uvm_error("IMEM2DEC", $sformatf("%0d decoded instruction(s) never matched a fetch (first 0x%04h)",
                                       decoded.size(), decoded[0]))
    if (n_decoded > 0 && n_matched == 0)
      `uvm_error("IMEM2DEC", "no decoded instruction matched any fetch - checker not seeing both streams")
  endfunction

  virtual function void report_phase(uvm_phase phase);
    `uvm_info("IMEM2DEC", $sformatf(
      "fetched=%0d decoded=%0d matched=%0d fetched-not-decoded=%0d errors=%0d (left in fetch queue at end: %0d)",
      n_fetched, n_decoded, n_matched, n_skipped, n_errors, fetched.size()), UVM_MEDIUM)
  endfunction

endclass


//----------------------------------------------------------------------
// lc3_checked_test
//
// test_top plus the imem->decode checker. random_instr_test and the
// directed opcode tests extend this instead of test_top.
//----------------------------------------------------------------------
class lc3_checked_test extends test_top;

  `uvm_component_utils( lc3_checked_test )

  lc3_imem_decode_checker imem2dec_chk;

  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imem2dec_chk = lc3_imem_decode_checker::type_id::create("imem2dec_chk", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    environment.imem_agent.monitored_ap.connect(imem2dec_chk.imem_export);
    environment.decode_env.decode_in_agent.monitored_ap.connect(imem2dec_chk.dec_export);
  endfunction

endclass
