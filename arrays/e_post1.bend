import Base
def main() -> Array<U32> & U32:
  a = [0 : U32*8n]
  a[5] <- 42       # an in-place rewrite, not a copy
  a[5]             # returns the array AND the element
