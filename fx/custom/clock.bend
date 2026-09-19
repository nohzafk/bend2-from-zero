import Base

# The effect from the guide's EFFECTS.md, as written there.  Measured: the C
# side returns milliseconds since boot, the JS side milliseconds since the
# process started -- the same def, two lanes, two different quantities.
def Clock.now() -> IO(U32):
  import "./clock.c"
  import "./clock.js"

def main() -> IO(Unit):
  do IO<Unit>:
    t : U32 <- Clock.now()
    IO.print("ms since boot: " ++ U32.show(t))
