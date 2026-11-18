#!/usr/bin/env bash
#----------------------------------------------------------------------
# regress.sh - LC3 Project 3 regression driver
#
# Builds the UVMF/Questa testbench with coverage instrumentation,
# runs every test in the suite, merges per-test UCDBs into merged.ucdb,
# and produces a text coverage report.
#
# Prerequisites (provided by the ECE 748 lab environment):
#   - Questa 2026.1 on PATH (vlib/vmap/vlog/vopt/vsim/vcover)
#   - $UVMF_HOME exported to the uvmf_2026.1 release root
#
# Usage:
#   ./regress.sh                 # full regression
#   ./regress.sh add_test ld_test  # only the listed tests
#
# Output artifacts (in the sim/ directory):
#   merged.ucdb       - merged coverage database (submit on Moodle)
#   coverage.txt      - text coverage report (submit on Moodle)
#   regress_logs/<test>.log   - per-test transcript
#   regress_ucdb/<test>.ucdb  - per-test coverage DB
#----------------------------------------------------------------------
set -euo pipefail

SIM_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SIM_DIR"

if [[ -z "${UVMF_HOME:-}" ]]; then
  echo "ERROR: UVMF_HOME is not set. Export it to the uvmf_2026.1 release root before running." >&2
  exit 1
fi

mkdir -p regress_logs regress_ucdb

# Default test suite: random stimulus + one directed test per LC3 opcode.
# random_instr_test alone will close most bins over enough cycles; the
# directed tests guarantee hard-to-hit opcodes (TRAP, JSR, etc.) land.
DEFAULT_TESTS=(
  random_instr_test
  br_test  add_test  ld_test   st_test
  jsr_test and_test  ldr_test  str_test
  not_test ldi_test  sti_test  jmp_test
  lea_test trap_test
)

if [[ $# -gt 0 ]]; then
  TESTS=("$@")
else
  TESTS=("${DEFAULT_TESTS[@]}")
fi

echo "=========================================="
echo "LC3 Project 3 regression"
echo "  sim dir : $SIM_DIR"
echo "  tests   : ${#TESTS[@]} (${TESTS[*]})"
echo "=========================================="

# ------------------------------------------------------------------
# Build using the project's existing compile.do flow (vlib/vmap/vlog),
# then re-optimize with coverage instrumentation enabled so each vsim
# run can emit a non-empty UCDB.
# ------------------------------------------------------------------
echo "[build  ] vsim -c -do compile.do"
vsim -c -do "do compile.do; quit -f" 2>&1 | tee regress_logs/build.log

echo "[vopt   ] re-optimizing with +cover instrumentation"
# -fcover: covergroup coverage
# +cover=bcesft: block/branch/condition/expression/statement/fsm/toggle code coverage
vopt +cover=bcesft -fcover hvl_top hdl_top -o optimized_cov_top_tb 2>&1 | tee -a regress_logs/build.log

# ------------------------------------------------------------------
# Run each test, writing a per-test UCDB.
# ------------------------------------------------------------------
PASS=0
FAIL=0
for t in "${TESTS[@]}"; do
  echo "[run    ] $t"
  UCDB="regress_ucdb/${t}.ucdb"
  LOG="regress_logs/${t}.log"
  rm -f "$UCDB"

  vsim -c \
       -coverage \
       -sv_seed random \
       +UVM_TESTNAME="$t" \
       +UVM_VERBOSITY=UVM_MEDIUM \
       -permit_unmatched_virtual_intf \
       +notimingchecks \
       -suppress 8887 \
       -do "coverage save -onexit $UCDB; run -all; quit -f" \
       optimized_cov_top_tb 2>&1 | tee "$LOG"

  if grep -q "UVM_FATAL :  *[1-9]" "$LOG" || ! [[ -f "$UCDB" ]]; then
    echo "  FAIL $t"
    FAIL=$((FAIL+1))
  else
    echo "  pass $t"
    PASS=$((PASS+1))
  fi
done

# ------------------------------------------------------------------
# Merge UCDBs and produce a text coverage report.
# ------------------------------------------------------------------
echo "[merge  ] vcover merge -> merged.ucdb"
rm -f merged.ucdb
vcover merge merged.ucdb regress_ucdb/*.ucdb

echo "[report ] vcover report -> coverage.txt"
vcover report -details -output coverage.txt merged.ucdb

echo "=========================================="
echo "Regression complete: $PASS passed, $FAIL failed"
echo "  Merged UCDB    : $SIM_DIR/merged.ucdb"
echo "  Coverage report: $SIM_DIR/coverage.txt"
echo "=========================================="

exit "$FAIL"
