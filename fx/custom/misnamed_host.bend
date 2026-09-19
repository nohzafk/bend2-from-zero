import Base

# A probe, kept on purpose: the JS host function is named shout_upperX, so the
# lane finds no `shout_upper` to call.  Run it to see what that error looks
# like -- it is a raw one from the JS runtime, not from Bend's checker.
def Shout.upper(s: String) -> IO(String):
  import "./shout_upper.c"
  import "./shout_upper_broken.js"

def main() -> IO(Unit):
  do IO<Unit>:
    a : String <- Shout.upper("hello")
    IO.print(a)
