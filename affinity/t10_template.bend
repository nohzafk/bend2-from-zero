import Base

# ~f is a *template* parameter: the argument is substituted at compile time,
# not passed at runtime, so f can be called as many times as you like.
#
# The ~ has to be written on BOTH sides. See t11_templatemiss.bend for what
# happens when you forget the one at the call site.
def twice(~f: U32 -> U32, x: U32) -> U32:
  f(f(x))

def main() -> U32:
  twice(~(x => (x + 1 : U32)), 40)
