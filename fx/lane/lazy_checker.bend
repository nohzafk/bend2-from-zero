import Base

def spin(+n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      Nat.add(spin(p), 1n)

def apply1(f: Nat -> Nat, +x: Nat) -> Nat:
  f(x)

def main() -> Nat:
  apply1((y: Nat) => (7n : Nat), spin(200000000n))
