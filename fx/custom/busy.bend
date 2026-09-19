import Base

# block a helper thread for n ms (io_work), then return on the loop
def Busy.ms(n: U32) -> IO(Unit):
  import "./busy_ms.c"
  import "./busy_ms.js"

def ticker() -> IO(Unit):
  do IO<Unit>:
    IO.sleep(300)
    IO.print("tick 300")
    IO.sleep(300)
    IO.print("tick 600")
    IO.sleep(300)
    IO.print("tick 900")

def main() -> IO(Unit):
  do IO<Unit>:
    c : Chan(Unit) <- IO.fork(Unit, ticker())
    +t0 : Nat <- IO.now()
    Busy.ms(1000)
    +t1 : Nat <- IO.now()
    IO.print("busy done after " ++ Nat.show(Nat.sub(t1, t0)) ++ " ms")
    IO.join(Unit, c)
