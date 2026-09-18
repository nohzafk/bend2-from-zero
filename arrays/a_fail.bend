import Base
def main() -> U32:
  a = [0 : U32*4n]
  p = a[5] <- 42
  (a2, b) = p
  (b + 42 : U32)
