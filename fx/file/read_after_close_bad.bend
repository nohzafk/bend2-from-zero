import Base

# A probe, kept on purpose: the handle is used after File.close.  It does not
# compile -- a handle is affine, so close consumes it and the checker refuses
# the second use.  Handle misuse is caught statically, not at runtime.
def main() -> IO(Unit):
  do IO<Unit>:
    f : File <- IO.try(File, File.open("out.txt", "r"))
    File.close(f)
    m : File & Result<&1, &1, U32 & String, String> <- File.read(f, 16)
    IO.print("read after close attempted")
