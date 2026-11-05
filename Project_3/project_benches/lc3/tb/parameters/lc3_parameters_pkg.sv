//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
// DESCRIPTION: This package contains test level parameters
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//


package lc3_parameters_pkg;

  import uvmf_base_pkg_hdl::*;

  // pragma uvmf custom package_imports_additional begin 
  // pragma uvmf custom package_imports_additional end


  // These parameters are used to uniquely identify each interface.  The monitor_bfm and
  // driver_bfm are placed into and retrieved from the uvm_config_db using these string 
  // names as the field_name. The parameter is also used to enable transaction viewing 
  // from the command line for selected interfaces using the UVM command line processing.
  parameter string decode_env_decode_in_agent_BFM  = "decode_env_decode_in_agent_BFM"; /* [0] */
  parameter string decode_env_decode_out_agent_BFM  = "decode_env_decode_out_agent_BFM"; /* [1] */
  parameter string writeback_env_writeback_in_agent_BFM  = "writeback_env_writeback_in_agent_BFM"; /* [2] */
  parameter string writeback_env_writeback_out_agent_BFM  = "writeback_env_writeback_out_agent_BFM"; /* [3] */
  parameter string memaccess_env_memaccess_in_agent_BFM  = "memaccess_env_memaccess_in_agent_BFM"; /* [4] */
  parameter string memaccess_env_memaccess_out_agent_BFM  = "memaccess_env_memaccess_out_agent_BFM"; /* [5] */
  parameter string control_env_control_in_agent_BFM  = "control_env_control_in_agent_BFM"; /* [6] */
  parameter string control_env_control_out_agent_BFM  = "control_env_control_out_agent_BFM"; /* [7] */
  parameter string imem_agent_BFM  = "imem_agent_BFM"; /* [8] */
  parameter string dmem_agent_BFM  = "dmem_agent_BFM"; /* [9] */

  // pragma uvmf custom package_item_additional begin
  // pragma uvmf custom package_item_additional end

endpackage

// pragma uvmf custom external begin
// pragma uvmf custom external end

