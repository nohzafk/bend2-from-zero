import Base

def main() -> IO(Unit):
  do IO<Unit>:
    v : String <- IO.try(String, IO.get_env("NO_SUCH_XYZ_12345"))
    IO.print("env=" ++ v)
