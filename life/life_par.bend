import Base

# ============================================================
# 生命游戏：fork-join 的粒度实验
# 64x64 = 4096 = 2^12 个格子，每代都要 join 一次（下一代依赖上一代）。
# 变量：(a) 线程数  (b) 每个叶子任务算多少格子  blk
#   2^d * blk = w*h  —— blk 越大，任务越少越粗
# 编译：bend life_par.bend -o life_par
# 运行：./life_par --threads 8
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

# 坐标 → 值。注意这是一次 O(y*w+x) 的链表行走 —— 见文末记账。
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

# ---------- 叶子：串行算连续 n 个格子 ----------
def block(+g: List<&2, Nat>, +w: Nat, +h: Nat, +n: Nat, +k: Nat) -> List<&2, Nat>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      Con{cellnext(g, w, h, k), block(g, w, h, p, Nat.add(k, 1n))}

# ---------- 种子 ----------
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

# ---------- 并行：2^d 个叶子，每个叶子一个任务 ----------
def app(+xs: List<&2, Nat>, +ys: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      ys
    case Con{h, t}:
      Con{h, app(t, ys)}

# 深度 d 的 fork-join 树：叶子串行算 blk 个连续格子，join 处把两半拼起来。
# 覆盖 2^d * blk 个格子。这就是待证明的那个函数。
# 深度 d 的树覆盖多少个格子。和树本身是同一次递归，所以不用乘法，
# 也就没有分配律要证 —— 左半边覆盖 cells_in(p, blk) 个。
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

# ---------- 基准 ----------
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
