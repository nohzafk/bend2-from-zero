import Base

def nth(xs: List<Nat>, i: Nat) -> Nat:
  match xs:
    case Nil{}:
      0n
    case Con{h, t}:
      match i:
        case 0n:
          h
        case 1n+p:
          nth(t, p)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Nat.show(nth([1n, 2n, 3n], 1n)))
