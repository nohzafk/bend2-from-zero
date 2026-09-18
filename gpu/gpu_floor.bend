import Base

# The floor cost of one `!` call: the same shape as pow2, but it computes
# almost nothing. Whatever this takes is overhead, not work.
def pow2(+n: Nat) -> U32:
  match n:
    case 0n:
      1
    case 1n+p:
      a b = pow2(p) pow2(p)
      (a + b : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(pow2!(2n)))
