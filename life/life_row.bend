import Base

# ============================================================
# Life: a row-window sweep -- O(n), not O(n^2)
# Each cell does O(1) reads per generation:
#   pass 1  vertical sum      s[x] = prev[x] + cur[x] + next[x]
#   pass 2  horizontal window new[x] = rule(cur[x], s[x-1] + s[x] + s[x+1] - cur[x])
# The grid is a list of rows; each row is one pass, with no index lookup at all.
# Build: bend life_row.bend -o life_row
# ============================================================

# ---------- list helpers ----------
def app(+xs: List<&2, Nat>, +ys: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      ys
    case Con{h, t}:
      Con{h, app(t, ys)}

def rev(+xs: List<&2, Nat>, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      acc
    case Con{h, t}:
      rev(t, Con{h, acc})

# rotate a row one step left:  s[1],...,s[w-1],s[0]
def rot_l(+xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      app(t, Con{h, Nil{}})

# rotate a row one step right: s[w-1],s[0],...,s[w-2]
def rot_r(+xs: List<&2, Nat>) -> List<&2, Nat>:
  rev(rot_l(rev(xs, Nil{})), Nil{})

def rule(+alive: Nat, +n: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_eq(n, 3n), 1n,
    Bool.pick(Nat, Nat.is_eq(n, 2n), alive, 0n))

# ---------- the grid = a list of rows ----------
type Rows is Data:
  RNil{}
  RCons{row: List<&2, Nat>, tail: Rows}

def rows_app(+a: Rows, +b: Rows) -> Rows:
  match a:
    case RNil{}:
      b
    case RCons{r, t}:
      RCons{r, rows_app(t, b)}

def rows_rev(+a: Rows, +acc: Rows) -> Rows:
  match a:
    case RNil{}:
      acc
    case RCons{r, t}:
      rows_rev(t, RCons{r, acc})

# rotate the row list one step left: r1,...,r(h-1),r0
def rows_rot1(+a: Rows) -> Rows:
  match a:
    case RNil{}:
      RNil{}
    case RCons{r, t}:
      rows_app(t, RCons{r, RNil{}})

# the other direction: two reversals instead of O(h) single rotations
def rows_rotm1(+a: Rows) -> Rows:
  rows_rev(rows_rot1(rows_rev(a, RNil{})), RNil{})

# ---------- pass 1: three rows summed column by column ----------
def colsum(
  +p: List<&2, Nat>, +c: List<&2, Nat>, +n: List<&2, Nat>, +acc: List<&2, Nat>
) -> List<&2, Nat>:
  match p:
    case Nil{}:
      rev(acc, Nil{})
    case Con{hp, tp}:
      match c:
        case Nil{}:
          rev(acc, Nil{})
        case Con{hc, tc}:
          match n:
            case Nil{}:
              rev(acc, Nil{})
            case Con{hn, tn}:
              colsum(tp, tc, tn, Con{Nat.add(hp, Nat.add(hc, hn)), acc})

# ---------- pass 2: the horizontal three-cell window ----------
# sl = s shifted right one (s[x-1]), sr = s shifted left one (s[x+1])
def rowstep(
  +sl: List<&2, Nat>, +s: List<&2, Nat>, +sr: List<&2, Nat>, +c: List<&2, Nat>,
  +acc: List<&2, Nat>
) -> List<&2, Nat>:
  match sl:
    case Nil{}:
      rev(acc, Nil{})
    case Con{hl, tl}:
      match s:
        case Nil{}:
          rev(acc, Nil{})
        case Con{hs, ts}:
          match sr:
            case Nil{}:
              rev(acc, Nil{})
            case Con{hr, tr}:
              match c:
                case Nil{}:
                  rev(acc, Nil{})
                case Con{hc, tc}:
                  +alive = hc
                  +nb = Nat.sub(Nat.add(hl, Nat.add(hs, hr)), alive)
                  rowstep(tl, ts, tr, tc, Con{rule(alive, nb), acc})

def newrow(+p: List<&2, Nat>, +c: List<&2, Nat>, +n: List<&2, Nat>) -> List<&2, Nat>:
  +s = colsum(p, c, n, Nil{})
  rowstep(rot_r(s), s, rot_l(s), c, Nil{})

# ---------- one generation: three staggered row lists walking together ----------
def zip3(+P: Rows, +C: Rows, +N: Rows) -> Rows:
  match P:
    case RNil{}:
      RNil{}
    case RCons{p, pt}:
      match C:
        case RNil{}:
          RNil{}
        case RCons{c, ct}:
          match N:
            case RNil{}:
              RNil{}
            case RCons{n, nt}:
              RCons{newrow(p, c, n), zip3(pt, ct, nt)}

def gen(+a: Rows) -> Rows:
  zip3(rows_rotm1(a), a, rows_rot1(a))

def evolve(+gens: Nat, +a: Rows) -> Rows:
  match gens:
    case 0n:
      a
    case 1n+q:
      evolve(q, gen(a))

# ---------- the seed: one glider ----------
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

def mkrow(+w: Nat, +n: Nat, +k: Nat) -> List<&2, Nat>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      Con{cell0(w, k), mkrow(w, p, Nat.add(k, 1n))}

def mkgrid(+w: Nat, +h: Nat, +y: Nat) -> Rows:
  match h:
    case 0n:
      RNil{}
    case 1n+p:
      RCons{mkrow(w, w, Nat.mul(y, w)), mkgrid(w, p, Nat.add(y, 1n))}

# ---------- live cell count ----------
def count(+g: List<&2, Nat>, +acc: Nat) -> Nat:
  match g:
    case Nil{}:
      acc
    case Con{h, t}:
      count(t, Nat.add(acc, h))

def rcount(+rs: Rows, +acc: Nat) -> Nat:
  match rs:
    case RNil{}:
      acc
    case RCons{r, t}:
      rcount(t, Nat.add(acc, count(r, 0n)))

def run(+w: Nat, +h: Nat, +gens: Nat) -> Nat:
  rcount(evolve(gens, mkgrid(w, h, 0n)), 0n)

def cat3(+a: String, +b: String, +c: String) -> String:
  String.append(a, String.append(b, c))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("row-window Life, 64 generations -- O(n)?\n")
    t0 : Nat <- IO.now()
    +c0 : Nat = run(32n, 32n, 64n)
    +t1 : Nat <- IO.now()
    +c1 : Nat = run(64n, 64n, 64n)
    +t2 : Nat <- IO.now()
    +c2 : Nat = run(128n, 128n, 64n)
    +t3 : Nat <- IO.now()
    +c3 : Nat = run(256n, 256n, 64n)
    t4 : Nat <- IO.now()
    IO.print(cat3("  32x32  live=", Nat.show(c0), cat3("  ms=", Nat.show(Nat.sub(t1, t0)), "\n")))
    IO.print(cat3("  64x64  live=", Nat.show(c1), cat3("  ms=", Nat.show(Nat.sub(t2, t1)), "\n")))
    IO.print(cat3("128x128  live=", Nat.show(c2), cat3("  ms=", Nat.show(Nat.sub(t3, t2)), "\n")))
    IO.print(cat3("256x256  live=", Nat.show(c3), cat3("  ms=", Nat.show(Nat.sub(t4, t3)), "\n")))
    IO.print("\n64x64, 16 generations -- head to head with the naive version\n")
    t5 : Nat <- IO.now()
    +c4 : Nat = run(64n, 64n, 16n)
    t6 : Nat <- IO.now()
    IO.print(cat3("  64x64  live=", Nat.show(c4), cat3("  ms=", Nat.show(Nat.sub(t6, t5)), "\n")))
