# LC-3 defect report: duplicate instruction admission after control transfer

Status: independently reproduced architectural failure; probable DUT defect. Internal RTL root cause unconfirmed because the supplied DUT is encrypted.

## Specification
LC3_DesignSpec(2).pdf, pp. 28–30: control instructions stop younger fetch/decode/execute activity until resolution; taken control flow updates PC to the Execute target, and the next fetch uses that address. Instruction memory supplies a new instruction on the next positive clock edge after an active read. A branch or jump must not execute a subsequent ADD twice without a corresponding architectural control transfer.

## Evidence
Both the UVMF Stage 67 full-LC-3 tests and the independent Stage 69 public-port tests return the same incorrect completed-store values at x3020. All Stage 69 simulator exits were 0 and the limited checker recorded zero protocol errors.

| Program | Expected | Stage 67 actual | Stage 69 actual | Stage 69 store cycle |
|---|---|---|---|---|
| Straight-line | 0003 | not run | 0003 | 16 |
| cf67_taken | 0002 | 0004 | 0004 | 17 |
| cf67_not_taken | 0003 | 0004 | 0004 | 20 |
| cf67_never | 0003 | 0004 | 0004 | 20 |
| cf67_jump | 0002 | 0004 | 0004 | 17 |
| cf67_chain | 0002 | 3009 | 3009 | 24 |

Taken branch: x3004=0403 (BRz +3); target x3008=1022 (ADD R0,R0,#2). R0 was initialized to zero. Stage 69 observes public read requests for x3008 at cycles 10 and 11, then completes a store of x0004 at cycle 17. Stage 67 correlates the target with Decode admissions 12 and 13, and Execute observations 13 and 14. Expected: one ADD and store x0002. Observed: two ADDs and store x0004.

Non-taken and mask-zero cases execute the fall-through ADD twice. JMP similarly duplicates the target ADD. The consecutive-branch case exhibits extra admissions and an incorrect stored value; its exact internal root cause is not established.

## Reproduction and limitations
Use Stage67_Results_Bundle.zip and Stage69_Results_Bundle.zip for full original evidence. The standalone Stage 69 bench and runner are in Stage69_Public_Port_Confirmation.zip. Neither changes encrypted RTL. Its single-store DMEM service waits for bus release; the trace shows continued active store signals after completion. This means zero reported protocol errors is a limited check, not proof of general DMEM correctness or forward progress after the store. Wrong values are observed before this later stall. No claim is made that every spec-compliant memory schedule reproduces the failure.

Stage-local scoreboards agree in four of five Stage 67 directed failing cases. That does not certify architectural execution. Preserve all raw UVM errors and directed failures; do not change the reference model solely to match the faulty sequence. Report this result to the instructor/TA for confirmation and grading guidance.

## Stage 73 expanded JMP observation (additional evidence, not independently isolated)
The cov72_jump program has 24 Control mismatches in four six-cycle windows (28–33, 48–53, 68–73, 88–93), starting on instructions C040, C0C0, C140, C1C0 (JMP R1/R3/R5/R7). Initial mismatch mask C00 (PC and Fetch enables); resolution mismatch mask 7C0 (Fetch, Decode, Execute, WriteBack and br_taken). All four sequences have identical mismatch-mask progression. JMP R0/R2/R4/R6 match the Control predictor in this program. This is an observed correlation with the program's order and register selection, not proof of an odd-register RTL bug. The independent Stage69 results establish incorrect architectural control-flow outcomes but do not isolate these additional failures. Preserve the 24 mismatches; no grading waiver assumed.
