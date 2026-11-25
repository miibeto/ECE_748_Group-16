#!/usr/bin/env python3
"""Trace-level diagnostic, not the instructor's UCDB coverage metric."""
from pathlib import Path
from collections import Counter, defaultdict
import re, sys, zipfile
OP = dict(zip([0,1,2,3,5,6,7,9,10,11,12,14], 'BR ADD LD ST AND LDR STR NOT LDI STI JMP LEA'.split()))
ROW = re.compile(r'\[STAGE50_CYCLE\] n=(\d+) ci=(\d) cd=(\d) ir=([\da-f]+) ie=([\da-f]+) im=([\da-f]+) psr=([01]+) nzp=([01]+) expected=([\da-f]+) actual=([\da-f]+)', re.I)
RET = re.compile(r'STAGE63_RETURN t=[\d.]+ns pc=([\da-f]+) data=([\da-f]+)',re.I)
SB = re.compile(r'(\S+) \[SCBD\] SCOREBOARD_RESULTS: +PREDICTED_TRANSACTIONS=(\d+) MATCHES=(\d+) MISMATCHES=(\d+)')

def logs(p):
    if p.is_dir():
        for f in sorted(p.glob('*_contract.log')):
            yield f.name, f.read_text(errors='replace')
    else:
        with zipfile.ZipFile(p) as z:
            for n in sorted(z.namelist()):
                if n.endswith('_contract.log'):
                    yield Path(n).name,z.read(n).decode(errors='replace')

def analyze(paths):
    admitted=Counter(); returns=Counter(); fields=defaultdict(set); missing_trace=0
    print('STAGE71 TRACE AUDIT — opcode/field observations, NOT UCDB coverage or architectural retirement')
    print('case | samples | ctrl mismatches | decode admissions | invalid ci | stage scoreboards (pred/match/mismatch)')
    for p in paths:
        for n,s in logs(p):
            rows=ROW.findall(s)
            if not rows: missing_trace+=1
            for _,word in RET.findall(s): returns[int(word,16)>>12]+=1
            dec=0; invalid=0
            for r in rows:
                if not int(r[-1],16)&0x200: continue
                if r[1]!='1': invalid+=1; continue
                word=int(r[5],16); o=word>>12; admitted[o]+=1; dec+=1
                if o in (1,2,5,6,9,10,14): fields[o,'DR'].add((word>>9)&7)
                if o in (1,5,6,7,9,12): fields[o,'SR1/base'].add((word>>6)&7)
                if o in (3,7,11): fields[o,'store SR'].add((word>>9)&7)
                if o in (1,5):
                    mode=(word>>5)&1; fields[o,'form'].add(mode)
                    if not mode: fields[o,'SR2'].add(word&7)
                    else: fields[o,'imm5'].add(word&31)
                if o==0: fields[o,'mask'].add((word>>9)&7)
                if o in (0,2,3,10,11,14):
                    v=word&511; fields[o,'offset9 sign'].add(0 if v==0 else -1 if v&256 else 1)
                if o in (6,7):
                    v=word&63; fields[o,'offset6 sign'].add(0 if v==0 else -1 if v&32 else 1)
            total=re.search(r'CTRL31_TOTAL\] samples=(\d+) transactions_with_any_mismatch=(\d+)',s)
            scores=[f'{a.split(".")[-1]}={b}/{c}/{d}' for a,b,c,d in SB.findall(s)]
            print(f'{n} | {len(rows)} | {total[2] if total else "MISSING"} | {dec} | {invalid} | '+', '.join(scores))
    print('\nOpcode observations (memory responses vs valid Decode admissions):')
    for o,name in OP.items(): print(f'{name:4} returned={returns[o]:5} admitted={admitted[o]:5}')
    print('Unsupported admitted opcodes:',{hex(o):n for o,n in admitted.items() if o not in OP})
    print('Missing decode opcodes:', [name for o,name in OP.items() if not admitted[o]])
    print('Missing trace files:',missing_trace)
    print('\nPer-instruction field gaps (diagnostic targets, not claimed grading bins):')
    for o,name in OP.items():
        checks=[]
        if o in (1,2,5,6,9,10,14): checks.append(('DR',set(range(8))))
        if o in (1,5,6,7,9,12): checks.append(('SR1/base',set(range(8))))
        if o in (3,7,11): checks.append(('store SR',set(range(8))))
        if o in (1,5): checks.extend([('form',{0,1}),('SR2',set(range(8))),('imm5',set(range(32)))])
        if o==0: checks.append(('mask',set(range(8))))
        if o in (0,2,3,10,11,14): checks.append(('offset9 sign',{-1,0,1}))
        if o in (6,7): checks.append(('offset6 sign',{-1,0,1}))
        for label,target in checks:
            hit=fields[o,label]&target
            print(f'{name:4} {label:14} {len(hit):2}/{len(target):2} missing={sorted(target-hit)}')
    print('\nNotes: field observations do not establish correct execution, branch outcomes, operand crosses, or UCDB closure. Decode admissions use the existing coherent Control trace convention. Retained invalid or duplicate words are not interpreted as unique architectural instructions.')

if __name__=='__main__':
    if len(sys.argv)<2: sys.exit('usage: stage70_audit.py <results-directory-or-zip> [...]')
    analyze([Path(a) for a in sys.argv[1:]])
