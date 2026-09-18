import Base
# x 在【两个分支里都出现】，但任何一条执行路径上只走一次
def describe(c: Bool, x: U32) -> U32:
  match c:
    case True{}:
      (x + 1 : U32)
    case False{}:
      (x + 2 : U32)

def main() -> U32:
  describe(True{}, 10)
