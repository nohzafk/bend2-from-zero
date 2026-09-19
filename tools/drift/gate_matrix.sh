#!/bin/sh
# gate_matrix.sh — the adversarial matrix for `bend PROOF.bend`.
#
# What the gate really catches, and what can slip past it.  Each case is a
# tiny project; the script runs the gate on each and prints one stable
# summary line per case (checked by tools/drift/manifest.py):
#
#   <case> rc=<exit code> out=<stdout first line> err=<stderr first line>
#
# Known findings this matrix pins (2026-09-19, Bend 2.0.16):
#   t2  a FALSE law 'proven' by an @unsafe non-terminating recursion passes
#       with rc=0; the only signal is the degraded stdout message.
#   t5  an emptied law set passes: nothing to prove, nothing rejected.
#   t6  the unsafe count is book-wide: an unrelated @unsafe def degrades the
#       message even when every proof is legitimate.
# Any change in these lines is a change in the gate's semantics — that is
# what a drift report should show.
#
# Usage: sh gate_matrix.sh [scratch-dir]      (default: ~/drift-bend2/gate)
set -u
BEND=${BEND:-$HOME/.bend/bin/bend}
G=${1:-$HOME/drift-bend2/gate}
rm -rf "$G"; mkdir -p "$G"

# ---- t1: a true law, properly proved.  (control)
mkdir -p "$G/t1_ok"
cat > "$G/t1_ok/LAWS.bend" <<'X'
import Base

law add_zero_law:
  for x: Nat
  {Nat.add(x, 0n) == x : Nat}
X
cat > "$G/t1_ok/PROOF.bend" <<'X'
import Base
import ./LAWS.bend as Laws

def Laws.add_zero_law(x):
  match x:
    case 0n:
      {==}
    case 1n+p:
      %Laws.add_zero_law(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}
X

# ---- t2: a FALSE law, "proved" by @unsafe non-termination.
mkdir -p "$G/t2_unsafe"
cat > "$G/t2_unsafe/LAWS.bend" <<'X'
import Base

# Deliberately false: x == 1 for every Nat.
law false_law:
  for x: Nat
  {x == 1n : Nat}
X
cat > "$G/t2_unsafe/PROOF.bend" <<'X'
import Base
import ./LAWS.bend as Laws

@unsafe
def Laws.false_law(x):
  Laws.false_law(x)
X

# ---- t3: the law left open with ?TODO.
mkdir -p "$G/t3_todo"
cat > "$G/t3_todo/LAWS.bend" <<'X'
import Base

law pending_law:
  for x: Nat
  {Nat.add(x, 0n) == x : Nat}
X
cat > "$G/t3_todo/PROOF.bend" <<'X'
import Base
import ./LAWS.bend as Laws

def Laws.pending_law(x):
  ?TODO
X

# ---- t4: PROOF.bend beside LAWS.bend, not importing it.
mkdir -p "$G/t4_noimport"
cat > "$G/t4_noimport/LAWS.bend" <<'X'
import Base

law some_law:
  for x: Nat
  {Nat.add(x, 0n) == x : Nat}
X
cat > "$G/t4_noimport/PROOF.bend" <<'X'
import Base

def dummy() -> U32:
  1
X

# ---- t5: the law quietly deleted; nothing left to prove.
mkdir -p "$G/t5_vacuous"
cat > "$G/t5_vacuous/LAWS.bend" <<'X'
import Base
X
cat > "$G/t5_vacuous/PROOF.bend" <<'X'
import Base
import ./LAWS.bend as Laws
X

# ---- t6: a legitimate proof, plus one @unsafe def sitting nearby (unused).
mkdir -p "$G/t6_nearby_unsafe"
cat > "$G/t6_nearby_unsafe/LAWS.bend" <<'X'
import Base

law add_zero_law:
  for x: Nat
  {Nat.add(x, 0n) == x : Nat}
X
cat > "$G/t6_nearby_unsafe/PROOF.bend" <<'X'
import Base
import ./LAWS.bend as Laws

@unsafe
def scratch(+x: Nat) -> Nat:
  match x:
    case 0n:
      0n
    case 1n+p:
      scratch(x)

def Laws.add_zero_law(x):
  match x:
    case 0n:
      {==}
    case 1n+p:
      %Laws.add_zero_law(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}
X

# ---- t7: proof def kept, law quietly deleted from LAWS.bend.
mkdir -p "$G/t7_straydef"
cat > "$G/t7_straydef/LAWS.bend" <<'X'
import Base
X
cat > "$G/t7_straydef/PROOF.bend" <<'X'
import Base
import ./LAWS.bend as Laws

def Laws.add_zero_law(x):
  match x:
    case 0n:
      {==}
    case 1n+p:
      %Laws.add_zero_law(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}
X

# ---- run all, print stable summary lines
for d in t1_ok t2_unsafe t3_todo t4_noimport t5_vacuous t6_nearby_unsafe t7_straydef; do
  cd "$G/$d"
  "$BEND" PROOF.bend > out.txt 2> err.txt
  rc=$?
  o=$(head -1 out.txt | sed 's/[[:space:]]*$//')
  e=$(head -1 err.txt | sed 's/[[:space:]]*$//')
  printf '%s rc=%s out=%s err=%s\n' "$d" "$rc" "$o" "$e"
done
