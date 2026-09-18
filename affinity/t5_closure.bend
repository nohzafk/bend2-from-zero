import Base
def main() -> U32:
  f = {x => (x + 1 : U32) : U32 -> U32}
  (f(1) + f(2) : U32)
