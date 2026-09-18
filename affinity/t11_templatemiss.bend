import Base

# A probe, kept on purpose: this does not compile.
#
# The parameter is declared as a template, but the argument at the call site
# is missing its own ~, so it is taken as an ordinary affine value -- and an
# affine value cannot be used twice, which is what twice() does with it.
#
# The error says "consumed more than once", which reads as being about the
# closure and is really about the missing ~. Compare t10_template.bend.
def twice(~f: U32 -> U32, x: U32) -> U32:
  f(f(x))

def main() -> U32:
  twice(x => (x + 1 : U32), 40)
