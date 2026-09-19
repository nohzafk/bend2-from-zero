import Base

# ============================================================
# Life: a fork-join granularity experiment
# 64x64 = 4096 = 2^12 cells, and every generation joins once (the next needs the last).
# Variables: (a) thread count  (b) cells per leaf task, blk
#   2^d * blk = w*h  -- larger blk means fewer, coarser tasks
# Build: bend life_par.bend -o life_par
# Run: ./life_par --threads 8
# ============================================================

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

# coordinate -> value. Note this is an O(y*w+x) list walk -- see the accounting at the end.
def at(+g: List<&2, Nat>, +w: Nat, +h: Nat, +x: Nat, +y: Nat) -> Nat:
  nth(g, Nat.add(Nat.mul(Nat.mod(y, h), w), Nat.mod(x, w)))

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

def rule(+alive: Nat, +n: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_eq(n, 3n), 1n,
    Bool.pick(Nat, Nat.is_eq(n, 2n), alive, 0n))

def cellnext(+g: List<&2, Nat>, +w: Nat, +h: Nat, +k: Nat) -> Nat:
  +x = Nat.mod(k, w)
  +y = Nat.div(k, w)
  rule(at(g, w, h, x, y), nb(g, w, h, x, y))

# ---------- the leaf: n consecutive cells, serially ----------
def block(+g: List<&2, Nat>, +w: Nat, +h: Nat, +n: Nat, +k: Nat) -> List<&2, Nat>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      Con{cellnext(g, w, h, k), block(g, w, h, p, Nat.add(k, 1n))}

# ---------- the seed ----------
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

def count(+g: List<&2, Nat>, +acc: Nat) -> Nat:
  match g:
    case Nil{}:
      acc
    case Con{h, t}:
      count(t, Nat.add(acc, h))

# ---------- parallel: 2^d leaves, one task each ----------
def app(+xs: List<&2, Nat>, +ys: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      ys
    case Con{h, t}:
      Con{h, app(t, ys)}

# A fork-join tree of depth d: each leaf runs blk consecutive cells serially, and a
# join pastes the two halves together -- 2^d * blk cells covered. That is the function
# the proofs are about: how many cells a tree of depth d covers. It is the same
# recursion as the tree, so no multiplication -- and no distributivity to prove: the
def cells_in(+d: Nat, +blk: Nat) -> Nat:
  match d:
    case 0n:
      blk
    case 1n+p:
      Nat.add(cells_in(p, blk), cells_in(p, blk))

def tree_cells(+d: Nat, +g: List<&2, Nat>, +w: Nat, +h: Nat, +blk: Nat, +k: Nat) -> List<&2, Nat>:
  match d:
    case 0n:
      block(g, w, h, blk, k)
    case 1n+p:
      a b = tree_cells(p, g, w, h, blk, k) tree_cells(p, g, w, h, blk, Nat.add(k, cells_in(p, blk)))
      app(a, b)

def step_par(+d: Nat, +g: List<&2, Nat>, +w: Nat, +h: Nat, +blk: Nat) -> List<&2, Nat>:
  tree_cells(d, g, w, h, blk, 0n)

def evolve_par(+gens: Nat, +g: List<&2, Nat>, +d: Nat, +w: Nat, +h: Nat, +blk: Nat) -> List<&2, Nat>:
  match gens:
    case 0n:
      g
    case 1n+q:
      evolve_par(q, step_par(d, g, w, h, blk), d, w, h, blk)

# ---------- benchmarks ----------
def run_par(+w: Nat, +h: Nat, +gens: Nat, +d: Nat, +blk: Nat) -> Nat:
  count(evolve_par(gens, seed(w, Nat.mul(w, h), 0n), d, w, h, blk), 0n)

def cat3(+a: String, +b: String, +c: String) -> String:
  String.append(a, String.append(b, c))

def report(+label: String, +c: Nat, +ms: Nat) -> IO(Unit):
  do IO<Unit>:
    IO.print(cat3(label, Nat.show(c), cat3("  ms=", Nat.show(ms), "\n")))

# 64x64 = 4096。d = log2(4096/blk)：blk=1→12, blk=16→8, blk=64→6
def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("64x64, 4 generations\n")
    t0 : Nat <- IO.now()
    +a : Nat = run_par(64n, 64n, 4n, 12n, 1n)
    +t1 : Nat <- IO.now()
    +b : Nat = run_par(64n, 64n, 4n, 8n, 16n)
    +t2 : Nat <- IO.now()
    +c : Nat = run_par(64n, 64n, 4n, 6n, 64n)
    t3 : Nat <- IO.now()
    report("blk=1  (4096 tasks)  live=", a, Nat.sub(t1, t0))
    report("blk=16 ( 256 tasks)  live=", b, Nat.sub(t2, t1))
    report("blk=64 (  64 tasks)  live=", c, Nat.sub(t3, t2))

    # The same naive algorithm with no forking at all (d=0, one block for the whole
    # grid), to measure the O(n^2) scaling and contrast it with life_row's O(n).
    IO.print("\nnaive, no fork (d=0, blk=w*h)\n")
    t4 : Nat <- IO.now()
    +s32 : Nat = run_par(32n, 32n, 16n, 0n, 1024n)
    +t5 : Nat <- IO.now()
    +s64 : Nat = run_par(64n, 64n, 16n, 0n, 4096n)
    t6 : Nat <- IO.now()
    report("  32x32 16gen  live=", s32, Nat.sub(t5, t4))
    report("  64x64 16gen  live=", s64, Nat.sub(t6, t5))
