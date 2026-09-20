import Base

# A probe, kept on purpose: a do-block header whose family has no .bind.
# With no binds in the block the header is erased and this runs; with the
# bind below it fails "expected : a defined name", on List.bind. See
# src/do-blocks.md.
def main() -> IO(Unit):
  do List<Unit>:
    x : U32 <- IO.now()
    return x
