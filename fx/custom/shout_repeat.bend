import Base

# A new effect, not in Base: uppercase a string (ASCII).
def Shout.upper(s: String) -> IO(String):
  import "./shout_upper.c"
  import "./shout_upper.js"

# Two arguments: string and U32.
def Str.repeat2(s: String, k: U32) -> IO(String):
  import "./str_repeat2.c"
  import "./str_repeat2.js"

def main() -> IO(Unit):
  do IO<Unit>:
    a : String <- Shout.upper("hello, bend")
    IO.print(a)
    b : String <- Str.repeat2("ab", 5)
    IO.print(b)
    d : String <- Str.repeat2("x", 3)
    c : String <- Shout.upper(d)
    IO.print(c)
