import Base

# A probe: how an array read feels. a[i] returns Array<U32> & U32 (a Sigma).
def main() -> IO(Unit):
  do IO<Unit>:
    a = [0 : U32*8n]
    a[5] <- 42
    IO.print(U32.show(a[5] : U32))
