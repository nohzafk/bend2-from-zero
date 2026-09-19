import Base

# A probe, kept on purpose: the .c file defines the run function but never
# registers it with io_eff, so the compiled program has no handler for the
# def.  It compiles; it dies at the first use (run mode is unaffected -- the
# JS lane never looks at the .c file).
def Shout.upper(s: String) -> IO(String):
  import "./shout_upper_noreg.c"
  import "./shout_upper.js"

def main() -> IO(Unit):
  do IO<Unit>:
    a : String <- Shout.upper("hello")
    IO.print(a)
