import Base

# Writes the file, then reads it back in two 5-byte chunks (the position
# advances) and once with read_at (an offset, position untouched).
def w_done(m: File & Result<&1, &1, U32 & String, Unit>) -> IO(File):
  (f, r) = m
  do IO<File>:
    u : Unit <- IO.pass(Unit, r)
    return f

def r5(m: File & Result<&1, &1, U32 & String, String>) -> IO(File):
  (f, r) = m
  do IO<File>:
    s : String <- IO.pass(String, r)
    IO.print("chunk: [" ++ s ++ "]")
    return f

def r_at(m: File & Result<&1, &1, U32 & String, List<&2, U32>>) -> IO(File):
  (f, r) = m
  do IO<File>:
    bs : List<&2, U32> <- IO.pass(List<&2, U32>, r)
    IO.print("at-bytes=" ++ Nat.show(List.length(&2, U32, bs)))
    return f

def main() -> IO(Unit):
  do IO<Unit>:
    h : File <- IO.try(File, File.open("out.txt", "w"))
    mw : File & Result<&1, &1, U32 & String, Unit> <- File.write(h, "hello, file")
    h2 : File <- w_done(mw)
    File.close(h2)
    g : File <- IO.try(File, File.open("out.txt", "r"))
    m1 : File & Result<&1, &1, U32 & String, String> <- File.read(g, 5)
    g2 : File <- r5(m1)
    m2 : File & Result<&1, &1, U32 & String, String> <- File.read(g2, 5)
    g3 : File <- r5(m2)
    m3 : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_at(g3, 7, 4)
    g4 : File <- r_at(m3)
    File.close(g4)
