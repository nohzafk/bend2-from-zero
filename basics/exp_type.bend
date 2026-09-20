import Base

# The no-parameter shape: every type declaration carries `is`, even
# when there is nothing to parameterise.

type Shape is Data:
  Circle{+r: Nat}
  Square{+s: Nat}

def area(x: Shape) -> Nat:
  match x:
    case Circle{r}:  (r * r : Nat)
    case Square{s}:  (s * s : Nat)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Nat.show(area(Square{5n})))
