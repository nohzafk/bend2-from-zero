import Base

# the pair may only be destructured where it is a parameter or a field
def unzip(p: Array<U32> & U32) -> Array<U32>:
  (arr, _) = p
  arr

def value(p: Array<U32> & U32) -> U32:
  (_, v) = p
  v

def main() -> U32:
  a = [0 : U32*4n]
  a[5] <- 42              # in-place write; rebinds a
  b = unzip(a[0])         # read idx 0 (0), keep the array half
  U32.add(value(b[5]), 1) # read idx 5 from the returned array -> 42
