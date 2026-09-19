import Base

def say_bool(b: Bool) -> IO(Unit):
  match b:
    case True{}:
      IO.print("send=true")
    case False{}:
      IO.print("send=false")

def say_maybe(m: Maybe<&1, U32>) -> IO(Unit):
  match m:
    case Some{value}:
      IO.print("recv=" ++ U32.show(value))
    case None{}:
      IO.print("recv=none")

def main() -> IO(Unit):
  do IO<Unit>:
    +ch : Chan(U32) <- Chan.new(U32, 4)
    b : Bool <- Chan.send(U32, ch, 7)
    say_bool(b)
    m1 : Maybe<&1, U32> <- Chan.recv(U32, ch)
    say_maybe(m1)
    Chan.close(U32, ch)
    m2 : Maybe<&1, U32> <- Chan.recv(U32, ch)
    say_maybe(m2)
