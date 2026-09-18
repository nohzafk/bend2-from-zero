import Base
# What exactly does a write return? Its second half, printed.
def main() -> U32:
  a = [0 : U32*8n]
  a[5] <- 42
  Pair.snd(Array<U32>, U32, a[9] <- 7)    # write idx 9, look at the second half
