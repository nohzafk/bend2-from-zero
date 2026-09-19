import Base

def one() -> IO(U32):
  do IO<U32>:
    return 41

# Marking the channel + lets both joins compile, and then the second join
# dies at runtime: join is receive-once-then-close, so the channel it reads
# is closed, and IO.join.go exits with "IO.join: the channel was closed".
def main() -> IO(Unit):
  do IO<Unit>:
    +ch : Chan(U32) <- IO.fork(U32, one())
    r1 : U32 <- IO.join(U32, ch)
    IO.print("first join=" ++ U32.show(r1))
    r2 : U32 <- IO.join(U32, ch)
    IO.print("second join=" ++ U32.show(r2))
