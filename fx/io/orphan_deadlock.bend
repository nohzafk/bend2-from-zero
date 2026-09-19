import Base

# A forked computation that waits forever; main returns immediately.
# Does the program end, or report a deadlock?
def forever() -> IO(U32):
  do IO<U32>:
    ch : Chan(U32) <- Chan.new(U32, 1)
    v : Maybe<&1, U32> <- Chan.recv(U32, ch)
    return 0

def main() -> IO(Unit):
  do IO<Unit>:
    c : Chan(U32) <- IO.fork(U32, forever())
    IO.print("main done")
