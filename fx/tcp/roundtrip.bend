import Base

def srv_done(m: Socket & Result<&1, &1, U32 & String, Unit>) -> IO(Unit):
  (s, r) = m
  do IO<Unit>:
    u : Unit <- IO.pass(Unit, r)
    Socket.close(s)

def srv_send(s: Socket, msg: String) -> IO(Unit):
  do IO<Unit>:
    sm : Socket & Result<&1, &1, U32 & String, Unit> <- TCP.send(s, msg)
    srv_done(sm)

def srv_recv(m: Socket & Result<&1, &1, U32 & String, String>) -> IO(Unit):
  (s, r) = m
  do IO<Unit>:
    msg : String <- IO.pass(String, r)
    IO.print("server got: " ++ msg)
    srv_send(s, "pong")

def srv_start(s: Socket) -> IO(Unit):
  do IO<Unit>:
    m : Socket & Result<&1, &1, U32 & String, String> <- TCP.recv(s, 4096)
    srv_recv(m)

def acc_done(m: Listener & Result<&1, &1, U32 & String, Socket>) -> IO(Unit):
  (l, r) = m
  do IO<Unit>:
    s : Socket <- IO.pass(Socket, r)
    IO.spawn(Unit, srv_start(s))

def server_once(l: Listener) -> IO(Unit):
  do IO<Unit>:
    m : Listener & Result<&1, &1, U32 & String, Socket> <- TCP.accept(l)
    acc_done(m)

def cli_got(m: Socket & Result<&1, &1, U32 & String, String>) -> IO(Unit):
  (s, r) = m
  do IO<Unit>:
    msg : String <- IO.pass(String, r)
    IO.print("client got: " ++ msg)
    Socket.close(s)

def cli_sent(m: Socket & Result<&1, &1, U32 & String, Unit>) -> IO(Unit):
  (s, r) = m
  do IO<Unit>:
    u : Unit <- IO.pass(Unit, r)
    rm : Socket & Result<&1, &1, U32 & String, String> <- TCP.recv(s, 4096)
    cli_got(rm)

def cli_send(s: Socket) -> IO(Unit):
  do IO<Unit>:
    sm : Socket & Result<&1, &1, U32 & String, Unit> <- TCP.send(s, "ping")
    cli_sent(sm)

def main() -> IO(Unit):
  do IO<Unit>:
    l : Listener <- IO.try(Listener, TCP.listen(7811))
    IO.print("listening on 127.0.0.1:7811")
    c : Chan(Unit) <- IO.fork(Unit, server_once(l))
    s : Socket <- IO.try(Socket, TCP.connect("127.0.0.1", 7811))
    cli_send(s)
    u : Unit <- IO.join(Unit, c)
    IO.print("done")
