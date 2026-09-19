import Base

def got(m: Maybe<&1, U32>) -> IO(Unit):
  match m:
    case Some{value}:
      IO.print("recv=" ++ U32.show(value))
    case None{}:
      IO.print("recv=none")

def main() -> IO(Unit):
  do IO<Unit>:
    +ch : Chan(U32) <- Chan.new(U32, 4)
    b1 : Bool <- Chan.send(U32, ch, 10)
    b2 : Bool <- Chan.send(U32, ch, 20)
    b3 : Bool <- Chan.send(U32, ch, 30)
    b4 : Bool <- Chan.send(U32, ch, 40)
    IO.print("four sends done")
    m1 : Maybe<&1, U32> <- Chan.recv(U32, ch)
    got(m1)
    m2 : Maybe<&1, U32> <- Chan.recv(U32, ch)
    got(m2)
    m3 : Maybe<&1, U32> <- Chan.recv(U32, ch)
    got(m3)
    m4 : Maybe<&1, U32> <- Chan.recv(U32, ch)
    got(m4)
