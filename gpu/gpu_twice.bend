import Base

def pow2(+n: Nat) -> U32:
  match n:
    case 0n:
      1
    case 1n+p:
      a b = pow2(p) pow2(p)
      (a + b : U32)

# Two `!` calls in one process, with different answers so neither can be
# shared with the other. If the entry cost is per call, this is ~2x gpu_floor.
def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(pow2!(25n)))
    IO.print(U32.show(pow2!(26n)))
