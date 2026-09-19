import Base

def one() -> IO(U32):
  do IO<U32>:
    return 41

# A probe, kept on purpose: the channel is consumed by the first join, so
# the second call does not compile.  (`+chan` on IO.join's parameter means
# the CALLEE may use it once; it does not let the CALLER pass it twice.)
def main() -> IO(Unit):
  do IO<Unit>:
    ch : Chan(U32) <- IO.fork(U32, one())
    r1 : U32 <- IO.join(U32, ch)
    IO.print("first join=" ++ U32.show(r1))
    r2 : U32 <- IO.join(U32, ch)
    IO.print("second join=" ++ U32.show(r2))
