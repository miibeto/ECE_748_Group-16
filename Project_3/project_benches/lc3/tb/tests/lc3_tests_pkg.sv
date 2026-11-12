//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
// DESCRIPTION: This package contains all tests currently written for
//     the simulation project.  Once compiled, any test can be selected
//     from the vsim command line using +UVM_TESTNAME=yourTestNameHere
//
// CONTAINS:
//     -<test_top>
//     -<example_derived_test>
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//

package lc3_tests_pkg;

   import uvm_pkg::*;
   import uvmf_base_pkg::*;
   import lc3_parameters_pkg::*;
   import lc3_env_pkg::*;
   import lc3_sequences_pkg::*;
   import decode_in_pkg::*;
   import decode_in_pkg_hdl::*;
   import decode_out_pkg::*;
   import decode_out_pkg_hdl::*;
   import writeback_in_pkg::*;
   import writeback_in_pkg_hdl::*;
   import writeback_out_pkg::*;
   import writeback_out_pkg_hdl::*;
   import memaccess_in_pkg::*;
   import memaccess_in_pkg_hdl::*;
   import memaccess_out_pkg::*;
   import memaccess_out_pkg_hdl::*;
   import control_in_pkg::*;
   import control_in_pkg_hdl::*;
   import control_out_pkg::*;
   import control_out_pkg_hdl::*;
   import imem_pkg::*;
   import imem_pkg_hdl::*;
   import dmem_pkg::*;
   import dmem_pkg_hdl::*;


   `include "uvm_macros.svh"

  // pragma uvmf custom package_imports_additional begin 
  // pragma uvmf custom package_imports_additional end

   `include "src/test_top.svh"
   `include "src/register_test.svh"
   `include "src/example_derived_test.svh"

  // pragma uvmf custom package_item_additional begin
   // Instruction-coverage stimulus: constrained imem transactions + per-opcode tests.
   `include "src/imem_constrained_transaction.svh"
   `include "src/imem_single_opcode_transaction.svh"
   `include "src/random_instr_test.svh"
   `include "src/directed_opcode_tests.svh"
  // pragma uvmf custom package_item_additional end

endpackage

// pragma uvmf custom external begin
// pragma uvmf custom external end

