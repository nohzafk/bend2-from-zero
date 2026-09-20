import Base

# The do-block from src/do-blocks.md, with the call the chapter quotes in
# main.  add_strs_bad.bend is the same def on input that will not parse.

def add_strs(a: String, b: String) -> Maybe<&2, U32>:
  do Maybe<&2, U32>:
    x : U32 <- U32.read(a)
    y : U32 <- U32.read(b)
    return (x + y : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Maybe.show(~&2, ~U32, ~U32.show, add_strs("42", "0")))
