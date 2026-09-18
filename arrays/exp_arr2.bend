import Base

def main() -> IO(Unit):
  do IO<Unit>:
    a = [0 : U32*8n]
    a[5] <- 42
    (a2, v) = a[5]
    IO.print(U32.show(v))
