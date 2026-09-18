import Base

# Base ships the projections: Pair.fst / Pair.snd, typed by the pair's own halves.
def main() -> U32:
  a = [0 : U32*8n]
  a[5] <- 42                              # in-place write; rebinds a
  b = Pair.fst(Array<U32>, U32, a[5])     # the array half, unchanged
  Pair.snd(Array<U32>, U32, b[5])         # the element half -> the write survived
