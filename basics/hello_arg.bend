import Base

# A probe, kept on purpose: 42 is a U32, not a String, and not a Nat.
# IO.print wants a String. See src/basics-hello.md.
def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(42)
