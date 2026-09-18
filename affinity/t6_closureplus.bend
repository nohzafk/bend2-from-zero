import Base
# 试图把闭包标成可重用
def main() -> U32:
  +f = (x: U32) => (x + 1 : U32)
  (f(1) + f(2) : U32)
