import Base

# A probe, kept on purpose: this COMPILES, RUNS, and gives the wrong answer.
# `1n+p` is not "equals 1" -- it is "one or more", and it swallows 2n before
# the next case is ever considered. f(2n) is 1, not 2. See src/basics-numbers.md.
def f(+x: Nat) -> Nat:
  match x:
    case 0n:
      0n
    case 1n+p:
      1n
    case 2n+p:
      2n

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Nat.show(f(2n)))
