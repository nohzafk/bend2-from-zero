import Base

# The call-site `~` is optional: the parameter is declared as a template
# and the compiler specializes the argument with or without the mark.
# Same output as t10_template.bend. Compare t10_template.bend.
def twice(~f: U32 -> U32, x: U32) -> U32:
  f(f(x))

def main() -> U32:
  twice(x => (x + 1 : U32), 40)
