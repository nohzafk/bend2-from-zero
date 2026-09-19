import Base

def quick() -> IO(Unit):
  do IO<Unit>:
    IO.sleep(300)
    IO.print("spawned ran after 300ms")

def main() -> IO(Unit):
  do IO<Unit>:
    IO.spawn(Unit, quick())
    IO.print("main done")
