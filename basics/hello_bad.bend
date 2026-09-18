import Base

# A probe, kept on purpose: the return type is IO(Unit), with parentheses.
# Writing IO<Unit> there does not compile. See src/basics-hello.md.
def main() -> IO<Unit>:
  do IO<Unit>:
    IO.print("hello, bend 2")
