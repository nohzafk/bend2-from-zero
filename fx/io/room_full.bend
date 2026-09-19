import Base

def say_bool(b: Bool) -> IO(Unit):
  match b:
    case True{}:
      IO.print("send=true")
    case False{}:
      IO.print("send=false")

# room=1: what does the second send do with nobody receiving?
def main() -> IO(Unit):
  do IO<Unit>:
    +ch : Chan(U32) <- Chan.new(U32, 1)
    b1 : Bool <- Chan.send(U32, ch, 1)
    say_bool(b1)
    b2 : Bool <- Chan.send(U32, ch, 2)
    say_bool(b2)
