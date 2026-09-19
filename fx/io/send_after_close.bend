import Base

def say_bool(b: Bool) -> IO(Unit):
  match b:
    case True{}:
      IO.print("send-after-close=true")
    case False{}:
      IO.print("send-after-close=false")

def main() -> IO(Unit):
  do IO<Unit>:
    +ch : Chan(U32) <- Chan.new(U32, 1)
    Chan.close(U32, ch)
    b : Bool <- Chan.send(U32, ch, 9)
    say_bool(b)
