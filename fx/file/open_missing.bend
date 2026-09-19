import Base

def main() -> IO(Unit):
  do IO<Unit>:
    f : File <- IO.try(File, File.open("/tmp/definitely-no-such-file-xyz.txt", "r"))
    IO.print("opened?!")
