 

onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -divider decode_env_decode_in_agent 
add wave -noupdate /uvm_root/uvm_test_top/environment.decode_env/decode_in_agent/decode_in_agent_monitor/txn_stream
add wave -noupdate -group decode_env_decode_in_agent_bus /hdl_top/decode_env_decode_in_agent_bus/*
add wave -noupdate -divider decode_env_decode_out_agent 
add wave -noupdate /uvm_root/uvm_test_top/environment.decode_env/decode_out_agent/decode_out_agent_monitor/txn_stream
add wave -noupdate -group decode_env_decode_out_agent_bus /hdl_top/decode_env_decode_out_agent_bus/*
add wave -noupdate -divider writeback_env_writeback_in_agent 
add wave -noupdate /uvm_root/uvm_test_top/environment.writeback_env/writeback_in_agent/writeback_in_agent_monitor/txn_stream
add wave -noupdate -group writeback_env_writeback_in_agent_bus /hdl_top/writeback_env_writeback_in_agent_bus/*
add wave -noupdate -divider writeback_env_writeback_out_agent 
add wave -noupdate /uvm_root/uvm_test_top/environment.writeback_env/writeback_out_agent/writeback_out_agent_monitor/txn_stream
add wave -noupdate -group writeback_env_writeback_out_agent_bus /hdl_top/writeback_env_writeback_out_agent_bus/*
add wave -noupdate -divider memaccess_env_memaccess_in_agent 
add wave -noupdate /uvm_root/uvm_test_top/environment.memaccess_env/memaccess_in_agent/memaccess_in_agent_monitor/txn_stream
add wave -noupdate -group memaccess_env_memaccess_in_agent_bus /hdl_top/memaccess_env_memaccess_in_agent_bus/*
add wave -noupdate -divider memaccess_env_memaccess_out_agent 
add wave -noupdate /uvm_root/uvm_test_top/environment.memaccess_env/memaccess_out_agent/memaccess_out_agent_monitor/txn_stream
add wave -noupdate -group memaccess_env_memaccess_out_agent_bus /hdl_top/memaccess_env_memaccess_out_agent_bus/*
add wave -noupdate -divider control_env_control_in_agent 
add wave -noupdate /uvm_root/uvm_test_top/environment.control_env/control_in_agent/control_in_agent_monitor/txn_stream
add wave -noupdate -group control_env_control_in_agent_bus /hdl_top/control_env_control_in_agent_bus/*
add wave -noupdate -divider control_env_control_out_agent 
add wave -noupdate /uvm_root/uvm_test_top/environment.control_env/control_out_agent/control_out_agent_monitor/txn_stream
add wave -noupdate -group control_env_control_out_agent_bus /hdl_top/control_env_control_out_agent_bus/*
add wave -noupdate -divider imem_agent 
add wave -noupdate /uvm_root/uvm_test_top/environment/imem_agent/imem_agent_monitor/txn_stream
add wave -noupdate -group imem_agent_bus /hdl_top/imem_agent_bus/*
add wave -noupdate -divider dmem_agent 
add wave -noupdate /uvm_root/uvm_test_top/environment/dmem_agent/dmem_agent_monitor/txn_stream
add wave -noupdate -group dmem_agent_bus /hdl_top/dmem_agent_bus/*



TreeUpdate [SetDefaultTree]
quietly wave cursor active 0
configure wave -namecolwidth 472
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {27 ns} {168 ns}

