import Base

# The claim on its own, with no proof anywhere in the file: it does not
# compile, and the message is the whole of what "open claim" means.  Proof
# and claim live in one file, two_plus_two.bend, which is this plus a def
# with no return type and the same name.  See src/laws-1.md.

law two_plus_two:
  {Nat.add(2n, 2n) == 4n : Nat}
