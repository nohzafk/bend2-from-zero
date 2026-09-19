import Base

# ============================================================
# Life: a terminal animation
# The engine is life_row.bend's row-window sweep (O(n)),
# wrapped in a do IO that writes a frame, sleeps, and computes the next one.
# Run: bend life_anim.bend
# To change the length or the speed: GENS and SLEEP_MS, at the bottom of the file
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

def rot_l(+xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      app(t, Con{h, Nil{}})

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

def rows_rot1(+a: Rows) -> Rows:
  match a:
    case RNil{}:
      RNil{}
    case RCons{r, t}:
      rows_app(t, RCons{r, RNil{}})

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

# ---------- rendering ----------
# One cell -> two characters. A terminal cell is about 2:1 tall:wide, so widening
# it keeps the glider from stretching. WARNING: the scheme does one String.reverse
# at the end, and it reverses CHARACTERS, not cells -- so every cell must be a
# palindrome. "██" / "  " are; swap in something like "▐█" and every row mirrors.
def cell(+v: Nat) -> String:
  Bool.pick(String, Nat.is_eq(v, 1n), "██", "  ")

# A row is built backwards: the row head ends up innermost, so no reverse here
def rowrev(+r: List<&2, Nat>, +acc: String) -> String:
  match r:
    case Nil{}:
      acc
    case Con{h, t}:
      rowrev(t, String.append(cell(h), acc))

# The grid is built backwards too: the whole frame comes out upside down
def framerev(+rs: Rows, +acc: String) -> String:
  match rs:
    case RNil{}:
      acc
    case RCons{r, t}:
      framerev(t, String.append("\n", String.append(rowrev(r, SNil{}), acc)))

# One reverse fixes both the row order and the cell order inside each row.
# Each String.append costs only the short left side, so the whole thing is O(frame).
# \u{1B}[H = cursor to the top-left; no full clear means no flicker.
def frame(+rs: Rows) -> String:
  String.append("\u{1B}[H", String.reverse(framerev(rs, SNil{})))

# ---------- the seed: one pattern for each of the three behaviours ----------
def on(+x: Nat, +y: Nat, +ax: Nat, +ay: Nat) -> Bool:
  Bool.and(Nat.is_eq(x, ax), Nat.is_eq(y, ay))

# glider -- it moves
def glider(+x: Nat, +y: Nat) -> Bool:
  Bool.or(on(x, y, 2n, 2n),
  Bool.or(on(x, y, 3n, 3n),
  Bool.or(on(x, y, 1n, 4n),
  Bool.or(on(x, y, 2n, 4n),
          on(x, y, 3n, 4n)))))

# blinker -- period 2, in place
def blinker(+x: Nat, +y: Nat, +w: Nat) -> Bool:
  +bx = Nat.sub(w, 8n)
  Bool.and(Nat.is_eq(y, 3n),
  Bool.or(Nat.is_eq(x, bx),
  Bool.or(Nat.is_eq(x, Nat.add(bx, 1n)),
          Nat.is_eq(x, Nat.add(bx, 2n)))))

# block -- still life
def block(+x: Nat, +y: Nat, +w: Nat, +h: Nat) -> Bool:
  +bx = Nat.sub(w, 8n)
  +by = Nat.sub(h, 6n)
  Bool.and(Bool.or(Nat.is_eq(x, bx), Nat.is_eq(x, Nat.add(bx, 1n))),
           Bool.or(Nat.is_eq(y, by), Nat.is_eq(y, Nat.add(by, 1n))))

def cell0(+x: Nat, +y: Nat, +w: Nat, +h: Nat) -> Nat:
  Bool.pick(Nat,
    Bool.or(glider(x, y), Bool.or(blinker(x, y, w), block(x, y, w, h))),
    1n, 0n)

def mkrow(+n: Nat, +x: Nat, +y: Nat, +w: Nat, +h: Nat) -> List<&2, Nat>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      Con{cell0(x, y, w, h), mkrow(p, Nat.add(x, 1n), y, w, h)}

def mkgrid(+n: Nat, +y: Nat, +w: Nat, +h: Nat) -> Rows:
  match n:
    case 0n:
      RNil{}
    case 1n+p:
      RCons{mkrow(w, 0n, y, w, h), mkgrid(p, Nat.add(y, 1n), w, h)}

# ---------- the animation ----------
# the shrinking argument goes leftmost = left
def loop(+left: Nat, +k: Nat, +rs: Rows) -> IO(Unit):
  match left:
    case 0n:
      IO.write("\u{1B}[?25h\n")
    case 1n+p:
      do IO<Unit>:
        IO.write(frame(rs))
        IO.sleep(70)
        loop(p, Nat.add(k, 1n), gen(rs))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.write("\u{1B}[?25l\u{1B}[2J")
    loop(320n, 0n, mkgrid(16n, 0n, 40n, 16n))
