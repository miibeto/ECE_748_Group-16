#!/usr/bin/env bash
#reproducible lc3 regression using the verified stage74 configuration
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIM="$ROOT/project_benches/lc3/sim"
MODE="${1:-full}"
SEED="${2:-12345}"
TOOLS="$ROOT/regression_tools"
case "$MODE" in
  full) specs=(alu:1 smoke:1 indirect:1 jump:1 branch:0 cov72_alu:1 cov72_direct:1 cov72_indirect:1 cov72_jump:1);;
  coverage) specs=(branch:0 cov72_alu:1 cov72_direct:1 cov72_indirect:1 cov72_jump:1);;
  *) echo "usage: bash regress.sh [full|coverage] [seed]" >&2; exit 2;;
esac
[[ "$SEED" =~ ^[0-9]+$ ]] || { echo 'numeric seed required' >&2; exit 2; }
OUT="$SIM/regression_results/stage75_${MODE}_$(date +%Y%m%d_%H%M%S)_$$"
mkdir -p "$OUT" || exit 2
BUNDLE="$ROOT/Stage75_Results_Bundle_${MODE}.zip"
status=0
finish() {
  rc=$?
  printf 'runner_exit=%s\nresults=%s\n' "$rc" "$OUT" >> "$OUT/stage75_summary.txt"
  rm -f "$BUNDLE"
  if ! (cd "$OUT" && zip -q -r "$BUNDLE" .); then
    echo "bundle creation failed; logs remain in $OUT" >&2
    trap - EXIT; exit 2
  fi
  echo "STAGE75_RESULTS=$OUT"
  echo "STAGE75_BUNDLE=$BUNDLE"
}
trap finish EXIT
printf 'LC3 compile-once regression; validated Stage74 configuration\nmode=%s\nseed=%s\n' "$MODE" "$SEED" > "$OUT/stage75_summary.txt"
cp "$TOOLS/Stage70_DUT_Defect_Report.md" "$OUT/" || exit 2
cp "$TOOLS/stage72_program_manifest.tsv" "$OUT/" || exit 2
grep -q "STAGE74_NO_DMEM" "$ROOT/verification_ip/environment_packages/lc3_env_pkg/src/lc3_environment.svh" || { echo "Stage74 memory-contract source missing; restore the verified source" | tee -a "$OUT/stage75_summary.txt"; exit 2; }
cd "$SIM" || exit 2
for tool in vsim vcover make python3 zip timeout; do
  command -v "$tool" >/dev/null || { echo "missing tool: $tool" | tee -a "$OUT/stage75_summary.txt"; exit 2; }
done
#snapshot the live configurations for the next coverage iteration
for f in "$SIM/Makefile" "$ROOT/regress.sh" "$ROOT/verification_ip/environment_packages/lc3_env_pkg/src/lc3_environment.svh" "$ROOT/verification_ip/interface_packages/decode_in_pkg/src/decode_in_transaction_coverage.svh" "$ROOT/verification_ip/environment_packages/decode_env_pkg/src/decode_env_configuration.svh" "$ROOT/verification_ip/interface_packages/imem_pkg/src/imem_transaction_coverage.svh" "$ROOT/verification_ip/interface_packages/imem_pkg/src/imem_transaction.svh" "$ROOT/verification_ip/interface_packages/imem_pkg/src/imem_responder_sequence.svh" "$ROOT/verification_ip/interface_packages/imem_pkg/src/imem_monitor_bfm.sv"; do
  if [[ -f "$f" ]]; then mkdir -p "$OUT/source_snapshot"; cp "$f" "$OUT/source_snapshot/"; fi
done

regression_start=$SECONDS
start=$SECONDS
for target in libs build link optimize; do
  echo "===== LC3 SETUP $target ====="
  if ! make "$target" > "$OUT/$target.log" 2>&1; then
    echo "SETUP FAILED: $target" | tee -a "$OUT/stage75_summary.txt"; tail -60 "$OUT/$target.log"; exit 2
  fi
done
printf 'one_time_setup_wall_seconds=%s\n' "$((SECONDS-start))" >> "$OUT/stage75_summary.txt"
coverage=()
printf 'program\tseed\tmake_exit\twall_seconds\tcontrol_samples\tcontrol_mismatches\tuvm_errors\tuvm_fatals\tucdb\n' > "$OUT/run_summary.tsv"
#use the same branch classification as the historical stage66 baseline, not a new optimization
for spec in "${specs[@]}"; do
  IFS=: read -r program brmode <<< "$spec"
  echo "===== LC3 $program ====="
  rm -f test_top.ucdb || exit 2
  log="$OUT/${program}_contract.log"
  start=$SECONDS
  timeout "${REGRESS_TIMEOUT_SECONDS:-300}s" make cli_run \
    TEST_NAME=test_top TEST_SEED="$SEED" IMEM_PROGRAM="$program" \
    CTRL64_HOLD_DURING_DMEM=1 CTRL63_SYNC_IMEM=1 CTRL61_HANDSHAKE=1 CTRL59_USE_LEGACY=1 \
    ACCEPT_IMEM_ACK=1 CANCEL_REDIRECTED_IMEM=1 CTRL52_LATCH_ACK=1 CTRL55_CLEAN_IMEM=1 CTRL57_PRE_WAIT_NEGEDGES=2 \
    CTRL32_EDGE_INSTR=1 CTRL32_EDGE_DATA=1 CTRL38_INPUT_PHASE=2 CTRL49_BRNEVER_NOP="$brmode" TRACE50_BRANCH=1 EXEC_COVERAGE=1 \
    DMEM_ACK_HOLD_CYCLES=1 DMEM_RESPONSE_DELAY_CYCLES=0 DMEM_REQ_QUALIFIER=0 DMEM_ZERO_WAIT=0 TRACE39_DMEM=1 \
    > "$log" 2>&1
  rc=$?; elapsed=$((SECONDS-start))
  counts=$(sed -n 's/.*CTRL31_TOTAL\] samples=\([0-9]*\) transactions_with_any_mismatch=\([0-9]*\).*/\1 \2/p' "$log" | tail -1)
  read -r samples misses <<< "${counts:-MISSING MISSING}"
  errors=$(grep -c 'UVM_ERROR @' "$log" || true)
  fatals=$(grep -c 'UVM_FATAL @' "$log" || true)
  ucdb=MISSING
  if [[ $rc -eq 0 && "$samples" == 400 && "$fatals" == 0 && -s test_top.ucdb ]]; then
    if cp -p test_top.ucdb "$OUT/$program.ucdb"; then coverage+=("$OUT/$program.ucdb"); ucdb="$program.ucdb"; else status=2; fi
  else status=2; fi
  if [[ "$misses" != 0 || "$errors" != 0 ]]; then [[ $status -eq 2 ]] || status=1; fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$program" "$SEED" "$rc" "$elapsed" "$samples" "$misses" "$errors" "$fatals" "$ucdb" | tee -a "$OUT/run_summary.tsv"
done
if ((${#coverage[@]}==0)); then
  echo 'No fresh coverage files' | tee -a "$OUT/stage75_summary.txt"; status=2
elif ((${#coverage[@]}==1)); then
  cp "${coverage[0]}" "$OUT/lc3_merged.ucdb" || status=2
else
  vcover merge "$OUT/lc3_merged.ucdb" "${coverage[@]}" > "$OUT/vcover_merge.log" 2>&1 || status=2
fi
if [[ -s "$OUT/lc3_merged.ucdb" ]]; then
  vcover report -details -output "$OUT/lc3_coverage_report.txt" "$OUT/lc3_merged.ucdb" > "$OUT/vcover_report.log" 2>&1 || status=2
fi
python3 "$TOOLS/stage71_audit.py" "$OUT" > "$OUT/stage75_trace_audit.txt" || status=2
python3 "$TOOLS/stage72_check.py" "$OUT" "$TOOLS/stage72_program_manifest.tsv" > "$OUT/stage75_targeted_coverage.txt"
audit_rc=$?
if [[ $audit_rc == 2 ]]; then status=2; elif [[ $audit_rc != 0 && $status != 2 ]]; then status=1; fi
if [[ -s "$OUT/lc3_coverage_report.txt" ]]; then
  grep -E '^ TYPE|^    Coverpoint opcode |^    Coverpoint executed_opcode |^    Coverpoint [a-z_]+_(dr|sr1_base|store_sr|form|sr2|imm5|mask|offset9|offset6) ' "$OUT/lc3_coverage_report.txt" > "$OUT/stage75_coverage_highlights.txt" || status=2
fi
for entry in "${specs[@]}"; do
  spec="${entry%%:*}"
  if ! grep -q 'STAGE71_DECODE_COV.*admitted=' "$OUT/${spec}_contract.log"; then
    echo "missing decode coverage report: $spec" >> "$OUT/stage75_summary.txt"; status=2
  fi
done
#obtain independent bin sets from each fresh UCDB, without running more simulations
for entry in "${specs[@]}"; do
  program="${entry%%:*}"
  if [[ ! -s "$OUT/$program.ucdb" ]]; then status=2; continue; fi
  vcover report -details -output "$OUT/${program}_coverage.txt" "$OUT/$program.ucdb" > "$OUT/${program}_report.log" 2>&1 || status=2
  if grep -Eq '^make (libs|build|link|optimize)( |$)|^vlog |^vopt ' "$OUT/${program}_contract.log"; then
    echo "unexpected repeated compilation/optimization: $program" >> "$OUT/stage75_summary.txt"; status=2
  fi
done
python3 "$TOOLS/stage75_validate.py" "$OUT" "$TOOLS/stage75_baseline.json" "$SEED" "$MODE" > "$OUT/stage75_equivalence.txt"
validation_rc=$?
if [[ $validation_rc == 2 ]]; then status=2; elif [[ $validation_rc != 0 && $status != 2 ]]; then status=1; fi
printf 'total_regression_wall_seconds=%s\n' "$((SECONDS-regression_start))" >> "$OUT/stage75_summary.txt"
cat "$OUT/run_summary.tsv" >> "$OUT/stage75_summary.txt"
printf 'fresh_ucdbs=%s\nmerged_coverage=%s\nstatus_0_clean_1_verification_fail_2_tool_or_incomplete=%s\n' "${#coverage[@]}" "$([[ -s "$OUT/lc3_coverage_report.txt" ]] && echo yes || echo no)" "$status" >> "$OUT/stage75_summary.txt"
cat "$OUT/stage75_summary.txt"
exit "$status"
