#!/usr/bin/env bash
#run supported directed programs; preserve coverage and verification failures
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIM_DIR="$PROJECT_ROOT/project_benches/lc3/sim"
OUT_DIR="$SIM_DIR/regression_results"
PROGRAMS=(smoke alu branch jump indirect sti_only)

if (($# == 0)); then
  SEEDS=(12345)
else
  SEEDS=("$@")
fi

for seed in "${SEEDS[@]}"; do
  if [[ ! "$seed" =~ ^[0-9]+$ ]]; then
    printf 'invalid seed: %s\n' "$seed" >&2
    exit 2
  fi
done

mkdir -p "$OUT_DIR"
cd "$SIM_DIR" || exit 2

RUN_ID="$(date '+%Y%m%d_%H%M%S')"
if [[ -s test_top.ucdb ]]; then
  cp -p test_top.ucdb "$OUT_DIR/preexisting_test_top_${RUN_ID}.ucdb" || exit 2
fi

printf 'project=%s\nprograms=%s\nseeds=%s\n' \
  "$PROJECT_ROOT" "${PROGRAMS[*]}" "${SEEDS[*]}" \
  | tee "$OUT_DIR/run_manifest.txt"
printf 'program\tseed\tmake_exit\tuvm_errors\tuvm_fatals\tfetches\tunique_pc\tlast_pc\tmax_same_pc\tldi_fetches\tsti_fetches\tdmem_reads\tdmem_writes\tucdb\n' > "$OUT_DIR/run_summary.tsv"

if ! make build 2>&1 | tee "$OUT_DIR/build.log"; then
  printf 'build failed; no simulations executed\n' >&2
  exit 2
fi

run_failed=0
coverage_files=()
for program in "${PROGRAMS[@]}"; do
  for seed in "${SEEDS[@]}"; do
    stem="${program}_seed_${seed}"
    logfile="$OUT_DIR/${stem}.log"
    ucdbfile="$OUT_DIR/${stem}.ucdb"
    scoreboardfile="$OUT_DIR/${stem}_scoreboards.txt"

    rm -f test_top.ucdb
    printf '\nrunning program=%s seed=%s\n' "$program" "$seed"
    if make cli TEST_NAME=test_top TEST_SEED="$seed" IMEM_PROGRAM="$program" 2>&1 | tee "$logfile"; then
      status=0
    else
      status=$?
      run_failed=1
    fi

    uvm_errors="$(awk '/^# UVM_ERROR @/ {n++} END {print n+0}' "$logfile")"
    uvm_fatals="$(awk '/^# UVM_FATAL @/ {n++} END {print n+0}' "$logfile")"
    #report observable progress separately from opcode coverage and scoreboard pass/fail
    fetches="$(awk '/\[IMEM\] fetch pc=/ {n++} END {print n+0}' "$logfile")"
    unique_pc="$(awk '/\[IMEM\] fetch pc=/ {split($0,a,"fetch pc="); split(a[2],b," "); seen[b[1]]=1} END {for(k in seen)n++; print n+0}' "$logfile")"
    last_pc="$(awk '/\[IMEM\] fetch pc=/ {split($0,a,"fetch pc="); split(a[2],b," "); last=b[1]} END {if(last!="") print last; else print "none"}' "$logfile")"
    max_same_pc="$(awk '/\[IMEM\] fetch pc=/ {split($0,a,"fetch pc="); split(a[2],b," "); pc=b[1]; if(pc==last)run++; else run=1; if(run>max)max=run; last=pc} END {print max+0}' "$logfile")"
    ldi_fetches="$(awk '/\[IMEM\] fetch pc=/ && /opcode=a[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]/ {n++} END {print n+0}' "$logfile")"
    sti_fetches="$(awk '/\[IMEM\] fetch pc=/ && /opcode=b[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]/ {n++} END {print n+0}' "$logfile")"
    dmem_reads="$(awk '/\[DMEM\] read addr=/ {n++} END {print n+0}' "$logfile")"
    dmem_writes="$(awk '/\[DMEM\] write addr=/ {n++} END {print n+0}' "$logfile")"
    if ((max_same_pc >= 4)); then
      printf 'observation: repeated instruction fetch at same pc (program=%s seed=%s pc=%s streak=%s)\n' \
        "$program" "$seed" "$last_pc" "$max_same_pc" | tee -a "$OUT_DIR/run_manifest.txt"
    fi
    if ((uvm_errors > 0 || uvm_fatals > 0)); then
      #known dut discrepancies remain reportable failures, not silently waived
      run_failed=1
    fi
    grep 'SCOREBOARD_RESULTS' "$logfile" > "$scoreboardfile" || true

    if [[ -s test_top.ucdb ]]; then
      if cp -p test_top.ucdb "$ucdbfile"; then
        coverage_files+=("$ucdbfile")
      else
        run_failed=1
      fi
    else
      printf 'missing coverage file: %s\n' "$ucdbfile" >&2
      run_failed=1
    fi

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$program" "$seed" "$status" "$uvm_errors" "$uvm_fatals" \
      "$fetches" "$unique_pc" "$last_pc" "$max_same_pc" "$ldi_fetches" \
      "$sti_fetches" "$dmem_reads" "$dmem_writes" "$ucdbfile" \
      >> "$OUT_DIR/run_summary.tsv"
    printf 'program=%s seed=%s make_exit=%s uvm_errors=%s uvm_fatals=%s\n' \
      "$program" "$seed" "$status" "$uvm_errors" "$uvm_fatals" \
      | tee -a "$OUT_DIR/run_manifest.txt"
  done
done

merged="$OUT_DIR/lc3_merged.ucdb"
rm -f "$merged"
if ((${#coverage_files[@]} == 0)); then
  printf 'no coverage databases generated\n' >&2
  run_failed=1
elif ((${#coverage_files[@]} == 1)); then
  cp -p "${coverage_files[0]}" "$merged" || run_failed=1
elif ! command -v vcover >/dev/null 2>&1; then
  printf 'vcover not found in PATH: load Questa (ml questa)\n' >&2
  run_failed=1
elif ! vcover merge "$merged" "${coverage_files[@]}" > "$OUT_DIR/vcover_merge.log" 2>&1; then
  printf 'vcover merge failed, see %s/vcover_merge.log\n' "$OUT_DIR" >&2
  run_failed=1
fi

if [[ -s "$merged" ]]; then
  if command -v vcover >/dev/null 2>&1; then
    if ! vcover report -details -output "$OUT_DIR/lc3_coverage_report.txt" "$merged" \
      > "$OUT_DIR/vcover_report.log" 2>&1; then
      printf 'coverage report failed, see %s/vcover_report.log\n' "$OUT_DIR" >&2
      run_failed=1
    fi
  else
    printf 'vcover not found in PATH; report skipped\n' >&2
    run_failed=1
  fi
fi

printf '\nsummary: %s/run_summary.tsv\n' "$OUT_DIR"
printf 'coverage: %s\n' "$merged"
printf 'report: %s/lc3_coverage_report.txt\n' "$OUT_DIR"
if ((run_failed)); then
  printf 'regression contains reported verification errors or tool failures; inspect the logs\n' >&2
fi
exit "$run_failed"
