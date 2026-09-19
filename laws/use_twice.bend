import Base

# The smallest example of a quantity mark: this law's proof hands its variable
# to two rewrite steps, so the binder must be reusable (+).  See src/laws-2.md
# for the other two marks' answers.
def add_zero_r(a: Nat) -> {a == Nat.add(a, 0n) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_zero_r(p) : {1n+p == 1n+_ : Nat}
      {==}

law use_twice:
  for +x: Nat
  {Nat.add(Nat.add(x, 0n), 0n) == x : Nat}

def use_twice(x):
  %add_zero_r(x) : {Nat.add(_, 0n) == x : Nat}
  %add_zero_r(x) : {_ == x : Nat}
  {==}
