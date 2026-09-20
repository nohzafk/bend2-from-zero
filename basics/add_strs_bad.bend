import Base
import ./add_strs.bend as M

# add_strs.bend again, called with a string that is not a number.  U32.read
# answers None{}, Maybe.bind skips the rest of the block, and the whole
# thing comes back empty -- "fail fast" is one `case None{}: None{}` in
# Maybe.bind's own definition, not machinery in the header.
#
# See src/do-blocks.md.

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Maybe.show(~&2, ~U32, ~U32.show, M.add_strs("nope", "2")))
