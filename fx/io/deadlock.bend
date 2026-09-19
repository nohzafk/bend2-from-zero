import Base

# The guide says: "reports a deadlock when the remaining ones all wait".
# Here the only computation waits on a channel nobody ever sends to.
def main() -> IO(Unit):
  do IO<Unit>:
    ch : Chan(U32) <- Chan.new(U32, 1)
    v : Maybe<&1, U32> <- Chan.recv(U32, ch)
    IO.print("recv returned")
