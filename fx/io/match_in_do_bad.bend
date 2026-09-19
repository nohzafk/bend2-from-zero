import Base

# A probe, kept on purpose: `match` is written inside the do block, which is
# not allowed -- a match heads a def body, not a term.  The fix is to pull
# each match out into its own def (see close_recv.bend for the working form).
def main() -> IO(Unit):
  do IO<Unit>:
    +ch : Chan(U32) <- Chan.new(U32, 4)
    b : Bool <- Chan.send(U32, ch, 7)
    match b:
      case True{}:
        IO.print("send=true")
      case False{}:
        IO.print("send=false")
    m1 : Maybe<&1, U32> <- Chan.recv(U32, ch)
    match m1:
      case Some{value}:
        IO.print("recv=" ++ U32.show(value))
      case None{}:
        IO.print("recv=none")
    Chan.close(U32, ch)
    m2 : Maybe<&1, U32> <- Chan.recv(U32, ch)
    match m2:
      case Some{value}:
        IO.print("after-close recv=" ++ U32.show(value))
      case None{}:
        IO.print("after-close recv=none")
