onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider decode_env_decode_in_agent
add wave -noupdate /uvm_root/uvm_test_top/environment/decode_env/decode_in_agent/decode_in_agent_monitor/txn_stream
add wave -noupdate -group decode_env_decode_in_agent_bus /hdl_top/decode_env_decode_in_agent_bus/clock
add wave -noupdate -group decode_env_decode_in_agent_bus /hdl_top/decode_env_decode_in_agent_bus/reset
add wave -noupdate -group decode_env_decode_in_agent_bus /hdl_top/decode_env_decode_in_agent_bus/enable_decode
add wave -noupdate -group decode_env_decode_in_agent_bus /hdl_top/decode_env_decode_in_agent_bus/dout
add wave -noupdate -group decode_env_decode_in_agent_bus /hdl_top/decode_env_decode_in_agent_bus/npc_in
add wave -noupdate -divider decode_env_decode_out_agent
add wave -noupdate /uvm_root/uvm_test_top/environment/decode_env/decode_out_agent/decode_out_agent_monitor/txn_stream
add wave -noupdate -group decode_env_decode_out_agent_bus /hdl_top/decode_env_decode_out_agent_bus/clock
add wave -noupdate -group decode_env_decode_out_agent_bus /hdl_top/decode_env_decode_out_agent_bus/reset
add wave -noupdate -group decode_env_decode_out_agent_bus /hdl_top/decode_env_decode_out_agent_bus/enable_decode
add wave -noupdate -group decode_env_decode_out_agent_bus /hdl_top/decode_env_decode_out_agent_bus/w_control
add wave -noupdate -group decode_env_decode_out_agent_bus /hdl_top/decode_env_decode_out_agent_bus/mem_control
add wave -noupdate -group decode_env_decode_out_agent_bus /hdl_top/decode_env_decode_out_agent_bus/e_control
add wave -noupdate -group decode_env_decode_out_agent_bus /hdl_top/decode_env_decode_out_agent_bus/ir
add wave -noupdate -group decode_env_decode_out_agent_bus /hdl_top/decode_env_decode_out_agent_bus/npc_out
add wave -noupdate -divider writeback_env_writeback_in_agent
add wave -noupdate /uvm_root/uvm_test_top/environment/writeback_env/writeback_in_agent/writeback_in_agent_monitor/txn_stream
add wave -noupdate -group writeback_env_writeback_in_agent_bus /hdl_top/writeback_env_writeback_in_agent_bus/clock
add wave -noupdate -group writeback_env_writeback_in_agent_bus /hdl_top/writeback_env_writeback_in_agent_bus/reset
add wave -noupdate -group writeback_env_writeback_in_agent_bus /hdl_top/writeback_env_writeback_in_agent_bus/aluout
add wave -noupdate -group writeback_env_writeback_in_agent_bus /hdl_top/writeback_env_writeback_in_agent_bus/memout
add wave -noupdate -group writeback_env_writeback_in_agent_bus /hdl_top/writeback_env_writeback_in_agent_bus/pcout
add wave -noupdate -group writeback_env_writeback_in_agent_bus /hdl_top/writeback_env_writeback_in_agent_bus/w_control
add wave -noupdate -group writeback_env_writeback_in_agent_bus /hdl_top/writeback_env_writeback_in_agent_bus/dr
add wave -noupdate -group writeback_env_writeback_in_agent_bus /hdl_top/writeback_env_writeback_in_agent_bus/sr1
add wave -noupdate -group writeback_env_writeback_in_agent_bus /hdl_top/writeback_env_writeback_in_agent_bus/sr2
add wave -noupdate -group writeback_env_writeback_in_agent_bus /hdl_top/writeback_env_writeback_in_agent_bus/enable_writeback
add wave -noupdate -divider writeback_env_writeback_out_agent
add wave -noupdate /uvm_root/uvm_test_top/environment/writeback_env/writeback_out_agent/writeback_out_agent_monitor/txn_stream
add wave -noupdate -group writeback_env_writeback_out_agent_bus /hdl_top/writeback_env_writeback_out_agent_bus/clock
add wave -noupdate -group writeback_env_writeback_out_agent_bus /hdl_top/writeback_env_writeback_out_agent_bus/reset
add wave -noupdate -group writeback_env_writeback_out_agent_bus /hdl_top/writeback_env_writeback_out_agent_bus/vsr1
add wave -noupdate -group writeback_env_writeback_out_agent_bus /hdl_top/writeback_env_writeback_out_agent_bus/vsr2
add wave -noupdate -group writeback_env_writeback_out_agent_bus /hdl_top/writeback_env_writeback_out_agent_bus/psr
add wave -noupdate -divider memaccess_env_memaccess_in_agent
add wave -noupdate /uvm_root/uvm_test_top/environment/memaccess_env/memaccess_in_agent/memaccess_in_agent_monitor/txn_stream
add wave -noupdate -group memaccess_env_memaccess_in_agent_bus /hdl_top/memaccess_env_memaccess_in_agent_bus/clock
add wave -noupdate -group memaccess_env_memaccess_in_agent_bus /hdl_top/memaccess_env_memaccess_in_agent_bus/reset
add wave -noupdate -group memaccess_env_memaccess_in_agent_bus /hdl_top/memaccess_env_memaccess_in_agent_bus/mem_state
add wave -noupdate -group memaccess_env_memaccess_in_agent_bus /hdl_top/memaccess_env_memaccess_in_agent_bus/M_Control
add wave -noupdate -group memaccess_env_memaccess_in_agent_bus /hdl_top/memaccess_env_memaccess_in_agent_bus/M_Data
add wave -noupdate -group memaccess_env_memaccess_in_agent_bus /hdl_top/memaccess_env_memaccess_in_agent_bus/M_addr
add wave -noupdate -group memaccess_env_memaccess_in_agent_bus /hdl_top/memaccess_env_memaccess_in_agent_bus/DMem_dout
add wave -noupdate -divider memaccess_env_memaccess_out_agent
add wave -noupdate /uvm_root/uvm_test_top/environment/memaccess_env/memaccess_out_agent/memaccess_out_agent_monitor/txn_stream
add wave -noupdate -group memaccess_env_memaccess_out_agent_bus /hdl_top/memaccess_env_memaccess_out_agent_bus/clock
add wave -noupdate -group memaccess_env_memaccess_out_agent_bus /hdl_top/memaccess_env_memaccess_out_agent_bus/reset
add wave -noupdate -group memaccess_env_memaccess_out_agent_bus /hdl_top/memaccess_env_memaccess_out_agent_bus/DMem_addr
add wave -noupdate -group memaccess_env_memaccess_out_agent_bus /hdl_top/memaccess_env_memaccess_out_agent_bus/DMem_rd
add wave -noupdate -group memaccess_env_memaccess_out_agent_bus /hdl_top/memaccess_env_memaccess_out_agent_bus/DMem_din
add wave -noupdate -group memaccess_env_memaccess_out_agent_bus /hdl_top/memaccess_env_memaccess_out_agent_bus/memout
add wave -noupdate -divider control_env_control_in_agent
add wave -noupdate /uvm_root/uvm_test_top/environment/control_env/control_in_agent/control_in_agent_monitor/txn_stream
add wave -noupdate -group control_env_control_in_agent_bus /hdl_top/control_env_control_in_agent_bus/clock
add wave -noupdate -group control_env_control_in_agent_bus /hdl_top/control_env_control_in_agent_bus/reset
add wave -noupdate -group control_env_control_in_agent_bus /hdl_top/control_env_control_in_agent_bus/complete_data
add wave -noupdate -group control_env_control_in_agent_bus /hdl_top/control_env_control_in_agent_bus/complete_instr
add wave -noupdate -group control_env_control_in_agent_bus /hdl_top/control_env_control_in_agent_bus/IR
add wave -noupdate -group control_env_control_in_agent_bus /hdl_top/control_env_control_in_agent_bus/psr
add wave -noupdate -group control_env_control_in_agent_bus /hdl_top/control_env_control_in_agent_bus/IR_Exec
add wave -noupdate -group control_env_control_in_agent_bus /hdl_top/control_env_control_in_agent_bus/IMem_dout
add wave -noupdate -group control_env_control_in_agent_bus /hdl_top/control_env_control_in_agent_bus/NZP
add wave -noupdate -divider control_env_control_out_agent
add wave -noupdate /uvm_root/uvm_test_top/environment/control_env/control_out_agent/control_out_agent_monitor/txn_stream
add wave -noupdate -group control_env_control_out_agent_bus /hdl_top/control_env_control_out_agent_bus/clock
add wave -noupdate -group control_env_control_out_agent_bus /hdl_top/control_env_control_out_agent_bus/reset
add wave -noupdate -group control_env_control_out_agent_bus /hdl_top/control_env_control_out_agent_bus/enable_updatePC
add wave -noupdate -group control_env_control_out_agent_bus /hdl_top/control_env_control_out_agent_bus/enable_fetch
add wave -noupdate -group control_env_control_out_agent_bus /hdl_top/control_env_control_out_agent_bus/enable_decode
add wave -noupdate -group control_env_control_out_agent_bus /hdl_top/control_env_control_out_agent_bus/enable_execute
add wave -noupdate -group control_env_control_out_agent_bus /hdl_top/control_env_control_out_agent_bus/enable_writeback
add wave -noupdate -group control_env_control_out_agent_bus /hdl_top/control_env_control_out_agent_bus/br_taken
add wave -noupdate -group control_env_control_out_agent_bus /hdl_top/control_env_control_out_agent_bus/bypass_alu_1
add wave -noupdate -group control_env_control_out_agent_bus /hdl_top/control_env_control_out_agent_bus/bypass_alu_2
add wave -noupdate -group control_env_control_out_agent_bus /hdl_top/control_env_control_out_agent_bus/bypass_mem_1
add wave -noupdate -group control_env_control_out_agent_bus /hdl_top/control_env_control_out_agent_bus/bypass_mem_2
add wave -noupdate -group control_env_control_out_agent_bus /hdl_top/control_env_control_out_agent_bus/mem_state
add wave -noupdate -divider imem_agent
add wave -noupdate /uvm_root/uvm_test_top/environment/imem_agent/imem_agent_monitor/txn_stream
add wave -noupdate -expand -group imem_agent_bus /hdl_top/imem_agent_bus/clock
add wave -noupdate -expand -group imem_agent_bus /hdl_top/imem_agent_bus/reset
add wave -noupdate -expand -group imem_agent_bus /hdl_top/imem_agent_bus/PC
add wave -noupdate -expand -group imem_agent_bus /hdl_top/imem_agent_bus/instrmem_rd
add wave -noupdate -expand -group imem_agent_bus /hdl_top/imem_agent_bus/I_macc
add wave -noupdate -expand -group imem_agent_bus /hdl_top/imem_agent_bus/Instr_dout
add wave -noupdate -expand -group imem_agent_bus /hdl_top/imem_agent_bus/complete_instr
add wave -noupdate -divider dmem_agent
add wave -noupdate /uvm_root/uvm_test_top/environment/dmem_agent/dmem_agent_monitor/txn_stream
add wave -noupdate -expand -group dmem_agent_bus /hdl_top/dmem_agent_bus/clock
add wave -noupdate -expand -group dmem_agent_bus /hdl_top/dmem_agent_bus/reset
add wave -noupdate -expand -group dmem_agent_bus /hdl_top/dmem_agent_bus/Data_addr
add wave -noupdate -expand -group dmem_agent_bus /hdl_top/dmem_agent_bus/Data_din
add wave -noupdate -expand -group dmem_agent_bus /hdl_top/dmem_agent_bus/Data_rd
add wave -noupdate -expand -group dmem_agent_bus /hdl_top/dmem_agent_bus/D_macc
add wave -noupdate -expand -group dmem_agent_bus /hdl_top/dmem_agent_bus/Data_dout
add wave -noupdate -expand -group dmem_agent_bus /hdl_top/dmem_agent_bus/complete_data
add wave -noupdate /hdl_top/ir
add wave -noupdate /hdl_top/IR_Exec
add wave -noupdate /hdl_top/mem_state
add wave -noupdate /hdl_top/DMem_addr
add wave -noupdate /hdl_top/DMem_rd
add wave -noupdate /hdl_top/enable_updatePC
add wave -noupdate /hdl_top/enable_fetch
add wave -noupdate /hdl_top/enable_decode
add wave -noupdate /hdl_top/enable_execute
add wave -noupdate /hdl_top/enable_writeback
add wave -noupdate /hdl_top/w_control
add wave -noupdate /hdl_top/dr
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {222 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 472
configure wave -valuecolwidth 38
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
WaveRestoreZoom {153 ns} {301 ns}
