# ECE 748 Project 3 — Group 16

## Reproduce the verification results

This submission candidate preserves the captured Stage 75 source/build/configuration files except for one build-order correction in `verification_ip/environment_packages/lc3_env_pkg/Makefile`. All SystemVerilog and DUT files remain byte-identical. The fresh-directory attempt exposed missing prediction-package prerequisites for Decode and MemAccess; these are now declared explicitly alongside the existing Control and WriteBack prerequisites. The updated source manifest covers the corrected Makefile. Historical results below are unchanged; a fresh Questa run of this corrected archive is required. The bench was generated with UVMF 2026.1 and the recorded runs used QuestaSim 2026.1, not UVMF 2023.4. From the extracted project root on Grendel:

```bash
ml questa
export UVMF_HOME=/mnt/apps/public/COE/mg_apps/questa2026.1/questasim/examples/UVM_Framework/UVMF_2026.1
unset UVMF_VIP_LIBRARY_HOME UVMF_PROJECT_DIR ECE748_PROJECT_HOME
sha256sum -c SOURCE_SHA256.txt > source_check.log && bash regress.sh full 12345
```

If using a different installation, set `UVMF_HOME` to the matching UVMF release with its `scripts/Makefile` and `uvmf_base_pkg` directory. The script requires Bash, make, Python 3, zip, timeout and Questa/vcover on PATH. Run from a fresh extracted directory; do not regenerate the customized SystemVerilog from YAML. The `regress.sh` script compiles and optimizes once, runs the tests, saves individual UCDBs, merges coverage and produces text reports and a ZIP bundle. Its default mode is full, with seed 12345. For the five-test coverage-only regression:

```bash
bash regress.sh coverage 12345
```

Exit 0 means clean; exit 1 means verification/audit failures; exit 2 means tool/incomplete regression. Exit 1 is expected for both recorded modes due to 114 reported Control mismatches. These failures are not waived or suppressed. A clean extracted-directory rerun is still required before submission; the bundled evidence was generated on the original live project, not by compiling this newly assembled archive.

## Recorded results (seed 12345)

| Metric | Full | Coverage-only |
|---|---:|---:|
| Tests | 9 | 5 |
| Wall time (recorded setup + regression) | 141 s | 92 s |
| Decode comparisons / matches | 3600 / 3600 | 2000 / 2000 |
| WriteBack comparisons / matches | 3600 / 3600 | 2000 / 2000 |
| MemAccess comparisons / matches | 3600 / 3600 | 2000 / 2000 |
| Control comparisons / matches | 3600 / 3486 | 2000 / 1886 |
| UVM errors | 114 | 114 |
| UVM fatals | 0 | 0 |
| Decode coverage | 272/272 | 272/272 |
| IMEM coverage | 47/47 | 47/47 |
| Execute opcode coverage | 12/12 | 12/12 |

The detailed Decode model covers supported opcodes, per-instruction register indices, ALU operand forms, immediate encodings, branch masks and signed-offset categories. It does not cover every possible cross or offset value. Coverage is measured on admitted Decode instructions, not architectural retirement. This is 100% of the implemented covergroups, not an independently confirmed grade. The coverage-only mode retains all three covergroups and uses 5 x 400 sampled cycles, versus 9 x 400 in full mode. Wall-clock time varies with the machine and includes setup and reporting.

## Archive layout

- `project_benches/lc3`: bench, RTL, configuration, test/sequence packages and simulation Makefile.
- `verification_ip`: passive stage interfaces and four EOL-required stage environments, active IMEM/DMEM responders, LC3 top-level environment and prediction package.
- `regress.sh`, `regression_tools/`: verified runner and audit scripts.
- `results/full/`, `results/coverage/`: original transcripts, individual and merged UCDBs, coverage reports, and regression/equivalence summaries. Source snapshots embedded in the original result bundles were checked against the included source and omitted here as duplicates.
- `results/dut_reproduction/`: independent public-port reproducer and original Stage 67/69 evidence; see the defect report.
- `SOURCE_SHA256.txt`: hash manifest of the packaged source, including the build-order correction. The capture exclusion list is in `results/SOURCE_CAPTURE_SKIPPED.txt`.

The archive contains no compiled simulator libraries. Build descriptors (`.compile`, `.mtlb`, `.vinfo`, `.f`) and YAML are retained because they are part of the generated project structure. UCDBs are submitted coverage data, not compiled libraries.

## Verification limitations / instructor review

1. Branch regression: 90 Control mismatches. Expanded JMP: 24 Control mismatches. Independent public-port reproduction shows wrong architectural stores after taken and non-taken branches and JMP, but does not establish the internal RTL root cause or prove all remaining Control mismatches are DUT defects. The limited standalone checker reports zero protocol errors, but its single-store service does not validate all memory behavior. See the defect report. Data-checking points require no mismatches under the grading sheet; instructor confirmation is needed.
2. All nine regression programs generate deterministic directed instruction words from the IMEM responder sequence. The DMEM responder uses a sparse word-addressable memory. This satisfies response-sequence stimulus generation in the rubric, but the assignment slide 9 describes transaction-class extensions and factory overrides for instruction constraints; the main regression instead selects ROM programs with plusargs. Instructor approval of that implementation approach has not been established.
3. The verified runner selects `CTRL49_BRNEVER_NOP=0` for the repeated-branch test and `1` for other tests. This is a remaining predictor-mode dependency, not a resolved universal interpretation of the zero-mask BR control hazard. The historical experimental switches and diagnostic traces remain in the source so the recorded configuration is reproducible. Do not treat this as a fully refactored implementation.
4. Coverage does not establish correctness of every program. Stage-local scoreboards can miss duplicated architectural instructions. The standalone defect reproducer is intentionally separate from the coverage regression.
5. The project assignment slide 10 describes a coverage test plan; the team has previously reported that this is waived for the EOL project. Confirm any remaining submission-specific requirements with the instructor. No waiver of the data-checking criterion is assumed.

## Optional independent reproduction

In the project root, extract `results/dut_reproduction/Stage69_Public_Port_Confirmation.zip` and run `bash stage69_run.sh` with Questa loaded. It creates a separate simulation directory. The original Stage 69 runner reports simulator completion independently of the per-case architectural pass flags; consult `stage69_summary.txt` and each `STAGE69_RESULT` line. No main project source is changed.
