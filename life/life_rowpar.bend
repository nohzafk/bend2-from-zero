import Base
import ./life_row.bend as Row

# ============================================================
# Life: the row-window engine, forked over rows.
# The same fork-join tree as life_par, one level up: the leaf computes a
# run of consecutive output rows (not cells), the join is rows_app.
#   2^d * blk = h   -- blk is rows per leaf, the granularity knob
# The clock brackets evolve only; the grid is built and counted outside it.
# Build: bend life_rowpar.bend -o life_rowpar
# Run:   ./life_rowpar --threads 10
# ============================================================

# drop the first n rows, i.e. return the list from position n on. The list is
# passed twice: x is the copy the match consumes, a is the copy that comes back
# when n reaches zero (a name cannot be both matched and returned bare) -- and
# every recursive call passes the current tail as both, so a is always the
# remainder at the current position.
def rdrop(+x: Row.Rows, +a: Row.Rows, +n: Nat) -> Row.Rows:
  match x:
    case Row.RNil{}:
      Row.RNil{}
    case Row.RCons{r, t}:
      match n:
        case 0n:
          a
        case 1n+p:
          rdrop(t, t, p)

# the first n output rows of three staggered row lists walked together
def rows3(+P: Row.Rows, +C: Row.Rows, +N: Row.Rows, +n: Nat) -> Row.Rows:
  match P:
    case Row.RNil{}:
      Row.RNil{}
    case Row.RCons{pv, pt}:
      match C:
        case Row.RNil{}:
          Row.RNil{}
        case Row.RCons{cv, ct}:
          match N:
            case Row.RNil{}:
              Row.RNil{}
            case Row.RCons{nv, nt}:
              match n:
                case 0n:
                  Row.RNil{}
                case 1n+p:
                  Row.RCons{Row.newrow(pv, cv, nv), rows3(pt, ct, nt, p)}

# 2^d * blk, by the same recursion the tree uses
def rows_in(+d: Nat, +blk: Nat) -> Nat:
  match d:
    case 0n:
      blk
    case 1n+p:
      Nat.add(rows_in(p, blk), rows_in(p, blk))

# the tree: a leaf is rows3 (blk output rows), the fork is the parallel let,
# the join is rows_app
def tree3(+d: Nat, +P: Row.Rows, +C: Row.Rows, +N: Row.Rows, +blk: Nat) -> Row.Rows:
  match d:
    case 0n:
      rows3(P, C, N, blk)
    case 1n+p:
      a b = tree3(p, P, C, N, blk) tree3(p, rdrop(P, P, rows_in(p, blk)), rdrop(C, C, rows_in(p, blk)), rdrop(N, N, rows_in(p, blk)), blk)
      Row.rows_app(a, b)

def gen_par(+a: Row.Rows, +d: Nat, +blk: Nat) -> Row.Rows:
  tree3(d, Row.rows_rotm1(a), a, Row.rows_rot1(a), blk)

def evolve_par(+gens: Nat, +a: Row.Rows, +d: Nat, +blk: Nat) -> Row.Rows:
  match gens:
    case 0n:
      a
    case 1n+q:
      evolve_par(q, gen_par(a, d, blk), d, blk)

# one benchmark line: build the grid, run the clock around evolve alone,
# count the live cells, print label + live + ms
def bench(+label: String, +w: Nat, +h: Nat, +gens: Nat, +d: Nat, +blk: Nat) -> IO(Unit):
  do IO<Unit>:
    +g : Row.Rows = Row.mkgrid(w, h, 0n)
    t0 : Nat <- IO.now()
    +r : Row.Rows = evolve_par(gens, g, d, blk)
    +t1 : Nat <- IO.now()
    +lv : Nat = Row.rcount(r, 0n)
    +ms : Nat = Nat.sub(t1, t0)
    +livepart : String = Row.cat3("  live=", Nat.show(lv), "")
    +mspart : String = Row.cat3("  ms=", Nat.show(ms), "\n")
    IO.print(Row.cat3(label, livepart, mspart))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("row-window Life, forked over rows -- the clock wraps evolve only\n")
    bench("256x256 d=0 blk=256 (the walk, 1 leaf)", 256n, 256n, 64n, 0n, 256n)
    bench("256x256 d=2 blk=64  (4 leaves)", 256n, 256n, 64n, 2n, 64n)
    bench("512x512 d=0 blk=512 (the walk, 1 leaf)", 512n, 512n, 64n, 0n, 512n)
    bench("512x512 d=2 blk=128 (4 leaves)", 512n, 512n, 64n, 2n, 128n)
    bench("512x512 d=3 blk=64  (8 leaves)", 512n, 512n, 64n, 3n, 64n)
    bench("512x512 d=4 blk=32  (16 leaves)", 512n, 512n, 64n, 4n, 32n)
