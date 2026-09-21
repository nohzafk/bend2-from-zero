import Base

# A probe: how an array read feels. a[i] returns Array<U32> & U32 (a Sigma).
#
# The binding carries its type because an array is `Type`, not `Data`: in a
# `do` block a bare `a = [..]` is read as a pattern, and the checker refuses it
# with `expected : a pattern (a binder or a constructor)`. The read below is
# what this probe is about, and it is refused too.
def main() -> IO(Unit):
  do IO<Unit>:
    a : Array<U32> = [0 : U32*8n]
    a[5] <- 42
    IO.print(U32.show(a[5] : U32))
