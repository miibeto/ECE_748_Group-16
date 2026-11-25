#!/usr/bin/env python3
"""Validate selected regression against the actual Stage 74 baseline."""
import csv, hashlib, itertools, json, re, sys
from pathlib import Path
from stage72_check import report_bins
from stage71_audit import ROW, RET, SB

FULL_CASES = ('alu','smoke','indirect','jump','branch','cov72_alu','cov72_direct','cov72_indirect','cov72_jump')

COVERAGE_CASES = ('branch','cov72_alu','cov72_direct','cov72_indirect','cov72_jump')

def signature(path):
    s = path.read_text(errors='replace')
    rows = ROW.findall(s)
    returns = RET.findall(s)
    sb = [list(x) for x in sorted(SB.findall(s))]
    errors = [line.split('ns:',1)[-1].strip() for line in s.splitlines() if 'UVM_ERROR @' in line]
    digest = lambda x: hashlib.sha256(json.dumps(x, separators=(',',':')).encode()).hexdigest()
    return {'cycles':len(rows),'cycle_sha256':digest(rows),'returns':len(returns),'return_sha256':digest(returns),
            'scoreboards':sb,'errors':len(errors),'error_sha256':digest(errors),
            'fatals':len(re.findall(r'UVM_FATAL @',s))}

def main():
    out, baseline, seed = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
    cases=FULL_CASES if sys.argv[4]=='full' else COVERAGE_CASES
    old=json.loads(baseline.read_text()); ok=True; complete=True
    print('STAGE75 TRACE EQUIVALENCE AND COVERAGE-ONLY SUBSET AUDIT')
    for case in cases:
        try: now=signature(out/(case+'_contract.log'))
        except OSError as e: print(case,'MISSING',e); complete=False; continue
        if case in ('cov72_alu','cov72_jump'):
            content=(out/(case+'_contract.log')).read_text(errors='replace')
            if not re.search(r'\[STAGE74_NO_DMEM\] '+case+r' PASS zero memory transactions',content):
                print(case,'MISSING memory-free contract PASS'); ok=False
        required={'decode_sb','writeback_sb','memaccess_sb','control_sb'}
        scores={x[0].split('.')[-1]: x[1:] for x in now['scoreboards']}
        if not required <= set(scores) or any(int(scores[k][0])!=400 or int(scores[k][1])+int(scores[k][2])!=400 for k in required if k in scores):
            print(case,'MISSING_OR_INCOMPLETE_REQUIRED_SCOREBOARD'); complete=False
        if now['cycles']!=400 or not now['scoreboards'] or now['fatals']:
            print(case,'INCOMPLETE trace/scoreboard/fatal'); complete=False
        if seed==old['seed']:
            changed=[k for k,v in old['cases'][case].items() if now[k]!=v]
            print(case, 'IDENTICAL' if not changed else 'DIFFERENT: '+','.join(changed), 'cycles=',now['cycles'],'errors=',now['errors'])
            ok &= not changed
        else: print(case,'baseline equivalence not evaluated for seed',seed)
    try:
        merged,_=report_bins(out/'lc3_coverage_report.txt')
        universe=set(merged); hits={}
        if len(universe)!=272: raise ValueError('verified Decode bin universe must contain 272 bins')
        for case in cases:
            bins,_=report_bins(out/(case+'_coverage.txt'))
            if set(bins)!=universe: raise ValueError(case+' bin universe differs')
            hits[case]={b for b,n in bins.items() if n>0}
            print(case,'individual Decode bins',len(hits[case]),'/',len(universe))
        allhits=set().union(*hits.values())
        if allhits != {b for b,n in merged.items() if n>0}: raise ValueError('individual vs merged hit set differs')
        print('Merged hit set:',len(allhits),'/',len(universe))
        ok &= allhits==universe
        if allhits==universe:
            choices=[]
            for n in range(1,len(cases)+1):
                choices=[c for c in itertools.combinations(cases,n) if set().union(*(hits[x] for x in c))==universe]
                if choices: break
            print('Minimum number of tests for these Decode bins:',len(choices[0]))
            for c in choices: print('COVERAGE_ONLY_CANDIDATE='+','.join(c))
            print('Do not remove directed functional/defect regressions merely because their bins overlap.')
    except (OSError,ValueError) as e: print('COVERAGE_SUBSET_INCOMPLETE:',e); complete=False
    print('STAGE75_EQUIVALENCE='+('NOT_EVALUATED_DIFFERENT_SEED' if seed!=old['seed'] else str(int(ok and complete))))
    print('STAGE75_VALIDATION='+str(int(ok and complete)))
    return 2 if not complete else 0 if ok else 1
if __name__=='__main__': sys.exit(main())
