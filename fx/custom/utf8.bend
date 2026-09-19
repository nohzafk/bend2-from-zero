import Base

def Str.repeat2(s: String, k: U32) -> IO(String):
  import "./str_repeat2.c"
  import "./str_repeat2.js"

def Shout.upper(s: String) -> IO(String):
  import "./shout_upper.c"
  import "./shout_upper.js"

def main() -> IO(Unit):
  do IO<Unit>:
    a : String <- Str.repeat2("héllo·世界", 2)
    IO.print(a)
    b : String <- Shout.upper("héllo, wörld")
    IO.print(b)
