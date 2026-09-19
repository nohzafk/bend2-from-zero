import Base

# A probe, kept on purpose: {==} demands that both sides of the goal be the
# same term, and `x + 0` cannot run while `x` is a variable -- `Nat.add`
# matches on its first argument.  The proof with two cases is add_zero.bend.
law add_zero:
  for x: Nat
  {Nat.add(x, 0n) == x : Nat}

def add_zero(x):
  {==}
