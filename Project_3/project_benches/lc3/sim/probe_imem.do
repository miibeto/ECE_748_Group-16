# probe_imem.do - print key LC3 fetch/imem signals each clock around reset release.
# Usage (from sim dir, after ./regress.sh has built 'work'):
#   vsim -c -voptargs=+acc +UVM_TESTNAME=random_instr_test -permit_unmatched_virtual_intf \
#        -suppress 8887 -do probe_imem.do hvl_top hdl_top > probe.log 2>&1

proc s {p {r bin}} { return [examine -radix $r $p] }

run 155ns
for {set i 0} {$i < 16} {incr i} {
  run 10ns
  echo [format "t=%-7s rst=%s | ef=%s eu=%s rd_dut=%s rd_bus=%s pc=%s | ci=%s dout=%s | ed=%s ir=%s ms=%s cd=%s" \
    $now [s /hdl_top/rst] \
    [s /hdl_top/dut/enable_fetch] [s /hdl_top/dut/enable_updatePC] \
    [s /hdl_top/dut/instrmem_rd] [s /hdl_top/imem_agent_bus/instrmem_rd] [s /hdl_top/dut/pc hex] \
    [s /hdl_top/imem_agent_bus/complete_instr] [s /hdl_top/imem_agent_bus/Instr_dout hex] \
    [s /hdl_top/dut/enable_decode] [s /hdl_top/dut/IR hex] \
    [s /hdl_top/dut/mem_state] [s /hdl_top/dut/complete_data]]
}
echo "---- drivers of instrmem_rd / complete_instr / Instr_dout @ $now ----"
drivers /hdl_top/imem_agent_bus/instrmem_rd
drivers /hdl_top/imem_agent_bus/complete_instr
drivers /hdl_top/imem_agent_bus/Instr_dout
echo "imem drv mode = [examine /hdl_top/imem_agent_drv_bfm/initiator_responder]"
echo "dmem drv mode = [examine /hdl_top/dmem_agent_drv_bfm/initiator_responder]"
quit -f
