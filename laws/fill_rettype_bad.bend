import Base

# A probe, kept on purpose: a law's fill may not carry its own return type.
# The law already supplies it, and the compiler rejects the redundancy.
law two_plus_two:
  {Nat.add(2n, 2n) == 4n : Nat}

def two_plus_two() -> {Nat.add(2n, 2n) == 4n : Nat}:
  {==}
