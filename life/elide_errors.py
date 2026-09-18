#!/usr/bin/env python3
"""Collapse the unfolded terms in a Bend proof error.

`bend FILE.bend 2>&1 | python3 elide_errors.py`

A failed proof prints expected and observed as fully unfolded terms, and
`cellnext` alone unfolds to a few thousand characters, so the part that
differs is not visible. This folds those runs into CELL.
"""
import sys, re
s = sys.stdin.read()
def elide(s, tag):
    out=[]; i=0
    while True:
        j = s.find(tag, i)
        if j < 0: out.append(s[i:]); break
        out.append(s[i:j]); k = j + len(tag) - 1; d = 0
        while k < len(s):
            if s[k]=='(': d+=1
            elif s[k]==')':
                d-=1
                if d==0: break
            k+=1
        out.append('CELL'); i = k+1
    return ''.join(out)
s = elide(s, 'Bool.pick(Nat, Cmp.is_eq(')
s = re.sub(r'life_par\.nth\(g, Nat\.add\(Nat\.mul\(Nat\.mod\.fin\(Nat\.divmod\(.*?\)\)\)\)\)\)\)\)', 'NTH', s)
print(s)
