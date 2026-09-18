import Base

# A probe, kept on purpose: this COMPILES, RUNS, and emits the wrong bytes.
# There is no octal escape. "\033" is "\0" (NUL) followed by the two literal
# characters 3 and 3. The bytes are 00 33 33 -- not 1B. For an escape you want
# \u{1B}. See src/basics-strings.md.
def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("\033")
