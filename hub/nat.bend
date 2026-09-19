# Nat.add — the laws of Base's Nat.add, as a callable lemma set.
#
# Base ships a term library and no reasoning library: not one fact about
# Nat.add is stated anywhere in it.  These six defs are the facts every
# proof over Nat.add ends up writing by hand — zero, succ, assoc, comm —
# plus the two that fall out of the first two by one rewrite.
# (First written for the Life proofs of bend2-from-zero; extracted here so
# the next proof can import them.)
#
# The rewrite rule, because it decides each statement's orientation:
#   %lem(args) : P    P is the goal AFTER the rewrite, with `_` at the
#   position the lemma's LEFT side was put in.  So a lemma is written
#   {target == what-the-goal-holds-now}: its right side is the form being
#   eliminated, its left side replaces it.
#
#   add_zero    {a + 0 == a}            replaces `a` with `a + 0`
#   add_zero_r  {a == a + 0}            replaces `a + 0` with `a`
#   add_succ    {a + (1+p) == 1+(a+p)}  replaces `1+(a+p)` with `a + (1+p)`
#   add_succ_r  {1+(a+p) == a + (1+p)}  replaces `a + (1+p)` with `1+(a+p)`
#   add_assoc   {(a+b)+c == a+(b+c)}    replaces `a+(b+c)` with `(a+b)+c`
#   add_comm    {a + b == b + a}        replaces `b + a` with `a + b`

import Base

def add_zero(a: Nat) -> {Nat.add(a, 0n) == a : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}

def add_zero_r(a: Nat) -> {a == Nat.add(a, 0n) : Nat}:
  %add_zero(a) : {_ == Nat.add(a, 0n) : Nat}
  {==}

def add_succ(a: Nat, -p: Nat) -> {Nat.add(a, 1n+p) == 1n+Nat.add(a, p) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+q:
      %add_succ(q, p) : {1n+Nat.add(q, 1n+p) == 1n+_ : Nat}
      {==}

def add_succ_r(a: Nat, -p: Nat) -> {1n+Nat.add(a, p) == Nat.add(a, 1n+p) : Nat}:
  %add_succ(a, p) : {_ == Nat.add(a, 1n+p) : Nat}
  {==}

def add_assoc(a: Nat, -b: Nat, -c: Nat) -> {Nat.add(Nat.add(a, b), c) == Nat.add(a, Nat.add(b, c)) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_assoc(p, b, c) : {1n+Nat.add(Nat.add(p, b), c) == 1n+_ : Nat}
      {==}

def add_comm(a: Nat, +b: Nat) -> {Nat.add(a, b) == Nat.add(b, a) : Nat}:
  match a:
    case 0n:
      %add_zero_r(b) : {b == _ : Nat}
      {==}
    case 1n+p:
      %add_succ_r(b, p) : {1n+Nat.add(p, b) == _ : Nat}
      %add_comm(p, b) : {1n+Nat.add(p, b) == 1n+_ : Nat}
      {==}
