import Base

# ============================================================
# Conway's Game of Life
# The grid is a flat List<&2, Nat> of length w*h, holding 0 or 1.
# Coordinate (x,y) -> index y*w + x; out of bounds wraps, so the world is a torus.
# ============================================================

# ---- element i; walking past the end returns 0n ----
def nth(+xs: List<&2, Nat>, +i: Nat) -> Nat:
  match xs:
    case Nil{}:
      0n
    case Con{h, t}:
      match i:
        case 0n:
          h
        case 1n+p:
          nth(t, p)

# ---- coordinate -> value, wrapping ----
def at(+g: List<&2, Nat>, +w: Nat, +h: Nat, +x: Nat, +y: Nat) -> Nat:
  nth(g, Nat.add(Nat.mul(Nat.mod(y, h), w), Nat.mod(x, w)))

# ---- the sum of the eight neighbours ----
def nb(+g: List<&2, Nat>, +w: Nat, +h: Nat, +x: Nat, +y: Nat) -> Nat:
  +xm = Nat.sub(Nat.add(x, w), 1n)
  +ym = Nat.sub(Nat.add(y, h), 1n)
  +xp = Nat.add(x, 1n)
  +yp = Nat.add(y, 1n)
  Nat.add(at(g, w, h, xm, ym),
  Nat.add(at(g, w, h, x, ym),
  Nat.add(at(g, w, h, xp, ym),
  Nat.add(at(g, w, h, xm, y),
  Nat.add(at(g, w, h, xp, y),
  Nat.add(at(g, w, h, xm, yp),
  Nat.add(at(g, w, h, x, yp),
          at(g, w, h, xp, yp))))))))

# ---- the survival rule ----
# exactly 3 neighbours -> alive (whatever it was); exactly 2 -> unchanged; else dead
def rule(+alive: Nat, +n: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_eq(n, 3n), 1n,
    Bool.pick(Nat, Nat.is_eq(n, 2n), alive, 0n))

# ---- the next generation: n cells, starting at index k ----
def step(+g: List<&2, Nat>, +w: Nat, +h: Nat, +n: Nat, +k: Nat) -> List<&2, Nat>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      +x = Nat.mod(k, w)
      +y = Nat.div(k, w)
      v = rule(at(g, w, h, x, y), nb(g, w, h, x, y))
      Con{v, step(g, w, h, p, Nat.add(k, 1n))}

# ---- the seed: one glider, at (1,0) (2,1) (0,2) (1,2) (2,2) ----
def hit(+x: Nat, +y: Nat, +a: Nat, +b: Nat) -> Bool:
  Bool.and(Nat.is_eq(x, a), Nat.is_eq(y, b))

def cell0(+w: Nat, +k: Nat) -> Nat:
  +x = Nat.mod(k, w)
  +y = Nat.div(k, w)
  Bool.pick(Nat,
    Bool.or(hit(x, y, 1n, 0n),
    Bool.or(hit(x, y, 2n, 1n),
    Bool.or(hit(x, y, 0n, 2n),
    Bool.or(hit(x, y, 1n, 2n),
            hit(x, y, 2n, 2n))))),
    1n, 0n)

def seed(+w: Nat, +n: Nat, +k: Nat) -> List<&2, Nat>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      Con{cell0(w, k), seed(w, p, Nat.add(k, 1n))}

# ---- render as a string, w characters per line ----
def one(+c: U32) -> String:
  SCon{Char.from_u32(c), SNil{}}

def nl() -> String:
  one(10)

def wrap_nl(+k: Nat, +w: Nat) -> String:
  Bool.pick(String, Bool.and(Nat.is_ne(k, 0n), Nat.is_eq(Nat.mod(k, w), 0n)), nl(), SNil{})

def render(+g: List<&2, Nat>, +w: Nat, +k: Nat) -> String:
  match g:
    case Nil{}:
      SNil{}
    case Con{h, t}:
      c = Bool.pick(U32, Nat.is_eq(h, 0n), 46, 35)
      String.append(wrap_nl(k, w), String.append(one(c), render(t, w, Nat.add(k, 1n))))

# ---- evolve gens generations. gens stays leftmost: the checker wants the shrinking arg first ----
def evolve(
  +gens: Nat, +g: List<&2, Nat>, +w: Nat, +h: Nat, +n: Nat, +k: Nat
) -> List<&2, Nat>:
  match gens:
    case 0n:
      g
    case 1n+q:
      evolve(q, step(g, w, h, n, k), w, h, n, k)

def gen_n(+w: Nat, +h: Nat, +gens: Nat) -> String:
  render(evolve(gens, seed(w, Nat.mul(w, h), 0n), w, h, Nat.mul(w, h), 0n), w, 0n)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("generation 0\n")
    IO.print(gen_n(8n, 8n, 0n))
    IO.print("\ngeneration 1\n")
    IO.print(gen_n(8n, 8n, 1n))
    IO.print("\ngeneration 2\n")
    IO.print(gen_n(8n, 8n, 2n))
    IO.print("\ngeneration 4\n")
    IO.print(gen_n(8n, 8n, 4n))
    IO.print("\n")
