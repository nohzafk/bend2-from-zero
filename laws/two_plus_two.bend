import Base

# The smallest law in the book: a claim with no variables, and its one-line
# proof.  See src/laws-1.md.
law two_plus_two:
  {Nat.add(2n, 2n) == 4n : Nat}

def two_plus_two():
  {==}
