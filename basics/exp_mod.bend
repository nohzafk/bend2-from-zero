import Base

# A probe, kept on purpose: x mod n is not structurally recursive in any obvious
# way, so it is written as one -- recurse on the shrinking x, accumulate in k.
def bump(+k: Nat, n: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_lt(k, Nat.sub(n, 1n)), 1n+k, 0n)

def mod(x: Nat, +n: Nat, k: Nat) -> Nat:
  match x:
    case 0n:
      k
    case 1n+p:
      mod(p, n, bump(k, n))

def main() -> Nat:
  mod(9n, 4n, 0n)
