// pins the imem opcode to memory ops only, so we actually get back-to-back
// loads/stores hitting memaccess instead of mostly ALU junk.

// any memory opcode: LD, ST, LDR, STR, LDI, STI
class imem_tx_mem_ops_only extends imem_transaction;
  `uvm_object_utils(imem_tx_mem_ops_only)
  constraint mem_ops_only_c {
    Instr_dout[15:12] inside {4'b0010, 4'b0011, 4'b0110, 4'b0111, 4'b1010, 4'b1011};
  }
  function new(string name = "imem_tx_mem_ops_only"); super.new(name); endfunction
endclass

// reads only (LD, LDR) - back to back direct reads
class imem_tx_mem_read_only extends imem_transaction;
  `uvm_object_utils(imem_tx_mem_read_only)
  constraint mem_read_only_c {
    Instr_dout[15:12] inside {4'b0010, 4'b0110};
  }
  function new(string name = "imem_tx_mem_read_only"); super.new(name); endfunction
endclass

// writes only (ST, STR) - back to back direct writes
class imem_tx_mem_write_only extends imem_transaction;
  `uvm_object_utils(imem_tx_mem_write_only)
  constraint mem_write_only_c {
    Instr_dout[15:12] inside {4'b0011, 4'b0111};
  }
  function new(string name = "imem_tx_mem_write_only"); super.new(name); endfunction
endclass

// indirect only (LDI, STI) - back to back pointer-fetch accesses, each
// one is actually 2 memory accesses (fetch the pointer, then the real one)
class imem_tx_mem_indirect_only extends imem_transaction;
  `uvm_object_utils(imem_tx_mem_indirect_only)
  constraint mem_indirect_only_c {
    Instr_dout[15:12] inside {4'b1010, 4'b1011};
  }
  function new(string name = "imem_tx_mem_indirect_only"); super.new(name); endfunction
endclass

`define MEMACCESS_DIRECTED_TEST(TEST_NAME, TX_T) \
class TEST_NAME extends test_top; \
  `uvm_component_utils( TEST_NAME ) \
  function new(string name = "", uvm_component parent = null); \
    super.new(name, parent); \
  endfunction \
  virtual function void build_phase(uvm_phase phase); \
    imem_transaction::type_id::set_type_override( TX_T::get_type() ); \
    super.build_phase(phase); \
  endfunction \
endclass

`MEMACCESS_DIRECTED_TEST(mem_ops_only_test,      imem_tx_mem_ops_only)
`MEMACCESS_DIRECTED_TEST(mem_read_only_test,     imem_tx_mem_read_only)
`MEMACCESS_DIRECTED_TEST(mem_write_only_test,    imem_tx_mem_write_only)
`MEMACCESS_DIRECTED_TEST(mem_indirect_only_test, imem_tx_mem_indirect_only)
