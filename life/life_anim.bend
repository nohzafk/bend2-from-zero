import Base

# ============================================================
# 生命游戏：终端动画
# 引擎就是 life_row.bend 的那套按行滑动窗口（O(n)），
# 外面套一层 do IO：每代写一帧、睡一下、再算下一代。
# 跑：bend life_anim.bend
# 改动画长度 / 速度：看文件底部的 GENS 和 SLEEP_MS
# ============================================================

# ---------- 链表小工具 ----------
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

# ---------- 网格 = 行的链表 ----------
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

# ---------- 第一遍：三行逐列纵向求和 ----------
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

# ---------- 第二遍：横向三格窗口 ----------
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

# ---------- 渲染 ----------
# 一个格子 → 两个字符。终端字符大约高:宽 = 2:1，双宽才不会把滑翔机拉长。
# ⚠️ 整套写法最后只做一次 String.reverse，而它翻的是「字符」不是「格子」——
# 所以每个格子必须是回文。"██" / "  " 都是；哪天换成 "▐█" 这种，
# 每行就会被翻个个儿（这个坑我已经踩过一次）。
def cell(+v: Nat) -> String:
  Bool.pick(String, Nat.is_eq(v, 1n), "██", "  ")

# 一行倒着攒：行首被压到最里层，这里不 reverse
def rowrev(+r: List<&2, Nat>, +acc: String) -> String:
  match r:
    case Nil{}:
      acc
    case Con{h, t}:
      rowrev(t, String.append(cell(h), acc))

# 网格也倒着攒：整屏倒过来
def framerev(+rs: Rows, +acc: String) -> String:
  match rs:
    case RNil{}:
      acc
    case RCons{r, t}:
      framerev(t, String.append("\n", String.append(rowrev(r, SNil{}), acc)))

# 一次 reverse 同时把「行的顺序」和「每行格子的顺序」翻回来。
# 每步 String.append 的代价只看左边那个短串，所以整体 O(帧长)。
# \u{1B}[H = 光标回左上角；不整屏清，就不闪。
def frame(+rs: Rows) -> String:
  String.append("\u{1B}[H", String.reverse(framerev(rs, SNil{})))

# ---------- 初始图案：三种行为各一个 ----------
def on(+x: Nat, +y: Nat, +ax: Nat, +ay: Nat) -> Bool:
  Bool.and(Nat.is_eq(x, ax), Nat.is_eq(y, ay))

# 滑翔机 —— 会走
def glider(+x: Nat, +y: Nat) -> Bool:
  Bool.or(on(x, y, 2n, 2n),
  Bool.or(on(x, y, 3n, 3n),
  Bool.or(on(x, y, 1n, 4n),
  Bool.or(on(x, y, 2n, 4n),
          on(x, y, 3n, 4n)))))

# 闪烁器 —— 原地周期 2
def blinker(+x: Nat, +y: Nat, +w: Nat) -> Bool:
  +bx = Nat.sub(w, 8n)
  Bool.and(Nat.is_eq(y, 3n),
  Bool.or(Nat.is_eq(x, bx),
  Bool.or(Nat.is_eq(x, Nat.add(bx, 1n)),
          Nat.is_eq(x, Nat.add(bx, 2n)))))

# 方块 —— 静止不动
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

# ---------- 动画 ----------
# 缩小的参数排最左 = left
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
