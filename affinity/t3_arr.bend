import Base
def main() -> U32:
  a = [0 : U32*4n]
  a1 = a[5] <- 42
  p = a1[0]
  (a2, b) = p
  (b + 42 : U32)
