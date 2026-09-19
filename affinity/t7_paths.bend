import Base
# x appears in BOTH branches, but no single path takes both
def describe(c: Bool, x: U32) -> U32:
  match c:
    case True{}:
      (x + 1 : U32)
    case False{}:
      (x + 2 : U32)

def main() -> U32:
  describe(True{}, 10)
