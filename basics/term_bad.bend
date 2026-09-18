import Base

# A probe, kept on purpose: this does not compile.
# p really is smaller than 1n+p -- but the checker reads arguments left to
# right, and Nat.add(p, 1n) is not *syntactically* p. See src/basics-numbers.md.
def loop(+x: Nat) -> Nat:
  match x:
    case 0n:
      0n
    case 1n+p:
      loop(Nat.add(p, 1n))
