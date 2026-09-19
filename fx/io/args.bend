import Base

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print("argc=" ++ Nat.show(List.length(&1, String, xs)))
