import Base

def nap(ms: U32) -> IO(U32):
  do IO<U32>:
    IO.sleep(ms)
    return 1

# Two 700 ms sleeps, forked.  Concurrent event loop: ~700 ms total;
# serial: ~1400 ms.
def main() -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    c1 : Chan(U32) <- IO.fork(U32, nap(700))
    c2 : Chan(U32) <- IO.fork(U32, nap(700))
    r1 : U32 <- IO.join(U32, c1)
    r2 : U32 <- IO.join(U32, c2)
    t1 : Nat <- IO.now()
    IO.print("total ms=" ++ Nat.show(Nat.sub(t1, t0)))
