import Base

# A probe: destructuring an array read. `(a2, v) = a[5]` is refused because the
# pair is a computed value, and a match may only scrutinize a parameter or a
# field bound by a pattern -- the error says so, and says what to do instead:
# give it its own def. `b_ok.bend` is that def.
def read() -> U32:
  a = [0 : U32*8n]
  a[5] <- 42
  (a2, v) = a[5]
  v

def main() -> IO(Unit):
  IO.print(U32.show(read()))
