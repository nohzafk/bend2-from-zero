import Base
# trying to mark an array as reusable
def main() -> U32:
  +a = [0 : U32*4n]
  b = a[0]
  c = a[1]
  (b + c : U32)
