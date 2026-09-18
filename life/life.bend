import Base

# ============================================================
# 生命游戏 (Conway's Game of Life)
# 网格是一个平的 List<&2, Nat>，长度 w*h，取值 0 或 1。
# 坐标 (x,y) → 下标 y*w + x；越界自动绕回，所以世界是个环面。
# ============================================================

# ---- 取第 i 个元素；走过头返回 0n ----
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

# ---- 坐标 → 值，环形 ----
def at(+g: List<&2, Nat>, +w: Nat, +h: Nat, +x: Nat, +y: Nat) -> Nat:
  nth(g, Nat.add(Nat.mul(Nat.mod(y, h), w), Nat.mod(x, w)))

# ---- 8 个邻居之和 ----
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

# ---- 生死规则 ----
# 恰好 3 个邻居 → 活（无论原来死活）；恰好 2 个 → 维持原状；否则死
def rule(+alive: Nat, +n: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_eq(n, 3n), 1n,
    Bool.pick(Nat, Nat.is_eq(n, 2n), alive, 0n))

# ---- 下一代：n 个格子，从下标 k 开始算 ----
def step(+g: List<&2, Nat>, +w: Nat, +h: Nat, +n: Nat, +k: Nat) -> List<&2, Nat>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      +x = Nat.mod(k, w)
      +y = Nat.div(k, w)
      v = rule(at(g, w, h, x, y), nb(g, w, h, x, y))
      Con{v, step(g, w, h, p, Nat.add(k, 1n))}

# ---- 初始图案：一个滑翔机 glider，坐标 (1,0) (2,1) (0,2) (1,2) (2,2) ----
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

# ---- 渲染成字符串，每 w 个字符一行 ----
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

# ---- 演化 gens 代。gens 必须放最左：终止检查器要求「会使参数变小的那个排第一」 ----
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
