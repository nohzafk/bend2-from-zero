import Base
def main() -> U32:
  a = [0 : U32*8n]
  a[5] <- 42
  b = Pair.fst(Array<U32>, U32, a[5])
  Pair.snd(Array<U32>, U32, b[5])
