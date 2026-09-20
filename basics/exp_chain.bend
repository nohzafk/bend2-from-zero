import Base

# The smallest parameterised type that checks. Read the header as:
# "Chain is parameterised by a quantity `a` and by an element type `A`
# whose values may be used `a` times; the Chain itself may be used
# `a` times -- a chain is exactly as reusable as its elements."
# Fields are typed `A`. The self-reference passes both parameters.

type Chain<a, -A: Kind(a)> is Kind(a):
  End{}
  Cell{head: A, tail: Chain<a, A>}

def len(a, -A: Kind(a), xs: Chain<a, A>) -> Nat:
  match xs:
    case End{}:      0n
    case Cell{h, t}: 1n + len(a, A, t)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Nat.show(len(&2, Nat, Cell{1n, Cell{2n, End{}}}))
)
