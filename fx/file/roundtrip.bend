import Base

# A fallible effect hands back (handle & Result): destructure in a parameter
# position, then IO.pass the Result.  These three defs are that pattern for
# the three result types File's effects produce.
def w_done(m: File & Result<&1, &1, U32 & String, Unit>) -> IO(File):
  (f, r) = m
  do IO<File>:
    u : Unit <- IO.pass(Unit, r)
    return f

def s_done(m: File & Result<&1, &1, U32 & String, U32>) -> IO(File):
  (f, r) = m
  do IO<File>:
    n : U32 <- IO.pass(U32, r)
    IO.print("size=" ++ U32.show(n))
    return f

def r_done(m: File & Result<&1, &1, U32 & String, String>) -> IO(Unit):
  (f, r) = m
  do IO<Unit>:
    s : String <- IO.pass(String, r)
    IO.print("read back: " ++ s)
    File.close(f)

def main() -> IO(Unit):
  do IO<Unit>:
    +path : String = "out.txt"
    f  : File <- IO.try(File, File.open(path, "w"))
    m  : File & Result<&1, &1, U32 & String, Unit> <- File.write(f, "hello, file")
    f2 : File <- w_done(m)
    m2 : File & Result<&1, &1, U32 & String, U32> <- File.size(f2)
    f3 : File <- s_done(m2)
    File.close(f3)
    g  : File <- IO.try(File, File.open(path, "r"))
    m3 : File & Result<&1, &1, U32 & String, String> <- File.read(g, 4096)
    r_done(m3)
