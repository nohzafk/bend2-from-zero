import Base

def main() -> IO(Unit):
  do IO<Unit>:
    s : Socket <- IO.try(Socket, TCP.connect("127.0.0.1", 7799))
    IO.print("connected?!")
