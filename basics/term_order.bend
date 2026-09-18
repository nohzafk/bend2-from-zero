import Base

# A probe, kept on purpose: this does not compile.
# gens is the argument that shrinks, but it is not the leftmost one, and g --
# which sits to its left -- is replaced by a computed value on the way past.
# See src/basics-numbers.md.
def step(+g: Nat) -> Nat:
  Nat.add(g, 1n)

def evolve(+g: Nat, +gens: Nat) -> Nat:
  match gens:
    case 0n:
      g
    case 1n+q:
      evolve(step(g), q)
