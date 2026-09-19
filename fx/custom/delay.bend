import Base

def Clock.now() -> IO(U32):
  import "./clock.c"
  import "./clock.js"

# A custom effect with a NEED: park for f[0] ms (the IO.sleep mechanism).
def Delay.ms(ms: U32) -> IO(Unit):
  import "./delay_ms.c"
  import "./delay_ms.js"

def main() -> IO(Unit):
  do IO<Unit>:
    +t0 : U32 <- Clock.now()
    IO.sleep(300)
    +t1 : U32 <- Clock.now()
    Delay.ms(300)
    +t2 : U32 <- Clock.now()
    IO.print("t0=" ++ U32.show(t0) ++ " d_builtin=" ++ U32.show(U32.sub(t1, t0)) ++ " d_custom=" ++ U32.show(U32.sub(t2, t1)))
