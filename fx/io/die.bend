import Base

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("before die")
    IO.die(Unit, 7, "custom failure message")
    IO.print("after die")
