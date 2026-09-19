import Base

# The first proof with a variable: two cases (`match`), the induction
# hypothesis quoting the proof itself, and {==} to close each case.
# The Life proofs carry this same fact as a plain def, with no law -- see
# ../life/LIFE_PAR_PROOF.bend for that form.
law add_zero:
  for x: Nat
  {Nat.add(x, 0n) == x : Nat}

def add_zero(x):
  match x:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}
