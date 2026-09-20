import Base

# ~f is a *template* parameter: the argument is substituted at compile time,
# not passed at runtime, so f can be called as many times as you like.
#
# The parameter-side ~ makes f a template. The call-site mark is optional;
# t11_template_implicit.bend shows the same call without it.
def twice(~f: U32 -> U32, x: U32) -> U32:
  f(f(x))

def main() -> U32:
  twice(~(x => (x + 1 : U32)), 40)
