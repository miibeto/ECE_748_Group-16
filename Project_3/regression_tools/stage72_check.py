#!/usr/bin/env python3
"""Check real UCDB report, and separately inspect coverage ROM progress in logs."""
from pathlib import Path
from collections import defaultdict, Counter
import csv,re,sys
TYPE='/decode_in_pkg/decode_in_transaction_coverage/decode_in_transaction_cg'
NAMES={0:'br',1:'add',2:'ld',3:'st',5:'and_op',6:'ldr',7:'str',9:'not_op',10:'ldi',11:'sti',12:'jmp',14:'lea'}

def report_bins(path):
    s=path.read_text(errors='replace'); m=re.search(r'^ TYPE '+re.escape(TYPE)+r'\s*$',s,re.M)
    if not m: raise ValueError('Decode covergroup type missing')
    segment=s[m.end():]; end=re.search(r'^ (?:TYPE|INSTANCE) ',segment,re.M)
    # first type report contains coverpoints before next type/instance
    if end: segment=segment[:end.start()]
    total=re.search(r'covered/total bins:\s*(\d+)\s+(\d+)',segment)
    if not total: raise ValueError('coverage bin totals missing')
    bins={}; cp=None
    for line in segment.splitlines():
        a=re.match(r'\s*Coverpoint\s+(\w+)\s+',line)
        if a: cp=a[1]
        b=re.match(r'\s+bin\s+(\S+)\s+(\d+)\s+',line)
        if b and cp: bins[(cp,b[1])]=int(b[2])
    if len(bins)!=int(total[2]): raise ValueError(f'expected {total[2]} bin records, parsed {len(bins)}')
    if sum(v>0 for v in bins.values())!=int(total[1]): raise ValueError('bin count inconsistent with report')
    return bins, total.groups()

def word_bins(word):
    op=word>>12; n=NAMES[op]; dr=(word>>9)&7; sr1=(word>>6)&7
    yield 'opcode',n
    if op in (1,2,5,6,9,10,14): yield n+'_dr',f'registers[{dr}]'
    if op in (1,5,6,7,9,12): yield n+'_sr1_base',f'registers[{sr1}]'
    if op in (3,7,11): yield n+'_store_sr',f'registers[{dr}]'
    if op in (1,5):
        mode=bool(word&32); yield n+'_form','imm_form' if mode else 'reg_form'
        yield (n+'_imm5',f'values[{word&31}]') if mode else (n+'_sr2',f'registers[{word&7}]')
    if op==0: yield 'br_mask',f'masks[{dr}]'
    if op in (0,2,3,10,11,14,6,7):
        width=6 if op in (6,7) else 9; x=word&((1<<width)-1); sign=1<<(width-1)
        cat='zero' if x==0 else 'min_negative' if x==sign else 'max_positive' if x==sign-1 else 'negative' if x>sign else 'positive'
        yield n+f'_offset{width}',cat

def read_manifest(path):
    m=defaultdict(dict)
    with path.open() as f:
        for r in csv.DictReader(f,delimiter='\t'): m[r['program']][int(r['pc'],16)]=int(r['word'],16)
    return m

def plan(report,manifest):
    bins,total=report_bins(report); missing={b for b,c in bins.items() if not c}; seen=set()
    for name,rom in read_manifest(manifest).items():
        hits={b for w in rom.values() for b in word_bins(w)}
        print(name, 'newly targeted bins vs Stage71:',len(hits&missing), 'ROM words:',len(rom)); seen |= hits
    print('Stage71 bins:',total,'uncovered targeted:',len(missing&seen),'remaining untargeted:',sorted(missing-seen)); return not (missing-seen)

def audit(out,manifest):
    bins,total=report_bins(out/'lc3_coverage_report.txt'); missing=[b for b,c in bins.items() if not c]
    print(f'ACTUAL MERGED DECODE BINS {total[0]}/{total[1]}'); print('Missing:', missing)
    ok=not missing
    for name,rom in read_manifest(manifest).items():
        s=(out/(name+'_contract.log')).read_text(errors='replace')
        observed=defaultdict(set)
        for p,w in re.findall(r'STAGE63_RETURN t=[\d.]+ns pc=([\da-f]+) data=([\da-f]+)',s,re.I): observed[int(p,16)].add(int(w,16))
        mismatched=[f'{p:04x}' for p,ws in observed.items() if p in rom and ws!={rom[p]}]
        last=max(rom); progress=last in observed and rom[last] in observed[last]
        print(name,'ROM last PC',f'{last:04x}','returned=',progress,'wrong ROM word addresses=',mismatched)
        if not progress or mismatched: ok=False
        # actual enabled Decode admissions: show planned bins reached, not retirement claims
        rows=re.findall(r'\[STAGE50_CYCLE\] n=(\d+) ci=(\d) cd=(\d) ir=([\da-f]+) ie=([\da-f]+) im=([\da-f]+) psr=([01]+) nzp=([01]+) expected=([\da-f]+) actual=([\da-f]+)',s,re.I)
        if not rows: raise ValueError('missing Control trace '+name)
        actual={b for r in rows if r[1]=='1' and int(r[-1],16)&0x200 and int(r[5],16)>>12 in NAMES for b in word_bins(int(r[5],16))}
        intended={b for w in rom.values() for b in word_bins(w)}
        if intended-actual: ok=False
        print('  observed intended field bins:',len(actual&intended),'/',len(intended),'unobserved:',sorted(intended-actual))
    print('TARGETED_COVERAGE_AND_ROM_PROGRESS_PASS='+str(int(ok)))
    return ok
if __name__=='__main__':
    try:
        if sys.argv[1]=='--plan': ok=plan(Path(sys.argv[2]),Path(sys.argv[3]))
        else: ok=audit(Path(sys.argv[1]),Path(sys.argv[2]))
        sys.exit(0 if ok else 1)
    except (ValueError,OSError,IndexError) as e:
        print('AUDIT_INCOMPLETE:',e); sys.exit(2)
