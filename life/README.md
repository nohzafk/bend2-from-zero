# life — 生命游戏，四种写法 + 两条定律的证明

同一个程序（8×8 到 256×256 的环形网格，一个滑翔机）。**这个目录是整个仓库
最有价值的对照**：它同时演示了「并行能买到什么」和「选对算法能买到什么」，
而这两个数差了两个数量级 —— 差 10 倍和差 2 000 倍不是一回事。

| 文件 | 写法 | 复杂度 |
|---|---|---|
| `life.bend` | 朴素串行，每个格子用下标查邻居 | **O(n²)** |
| `life_par.bend` | 同上 + fork-join 并行，带粒度旋钮 | O(n²) |
| `life_row.bend` | 按行滑动窗口，没有下标查找 | **O(n)** |
| `life_anim.bend` | 用 `life_row` 的引擎做的终端动画 | O(n) |
| `LIFE_PAR_LAWS.bend` | 定律：`life_par` 的树 == 同一个串行循环（人写） | — |
| `LIFE_PAR_PROOF.bend` | 上面那条定律的证明（`bend` 跑它就是 gate） | — |
| `LIFE_ANIM_LAWS.bend` | 定律：`life_anim` 的快渲染 == 慢的显然规格（人写） | — |
| `LIFE_ANIM_PROOF.bend` | 上面那条定律的证明（gate） | — |

（`n` = 网格总格数。`life.bend` 是 8×8、每代打印图案的教学版；
另外两个是基准，只看时间。）

## 问题出在哪

前两个版本查邻居是这么写的：

```python
def at(+g, +w, +h, +x: Nat, +y: Nat) -> Nat:
  nth(g, Nat.add(Nat.mul(Nat.mod(y, h), w), Nat.mod(x, w)))
      #  ↑ nth 要一步一步走到那个下标，代价 = O(下标)
```

每个格子要取 8 个邻居，所以**每格每代的代价与网格大小成正比** → 整体 O(n²)。
实测印证：32×32 时每格每代 30.8 µs，64×64 时 123.1 µs —— 格数 ×4，每格代价也 ×4。

## life_row 怎么做到 O(n)

两遍，全程不需要"跳到第 i 个"：

```
第一遍  纵向求和   s[x] = prev[x] + cur[x] + next[x]        ← 三行并排走
第二遍  横向窗口   new[x] = rule(cur[x], s[x-1] + s[x] + s[x+1] - cur[x])
```

网格表示成**行链表**，纵向环绕靠 `rows_rot1`，横向环绕靠行内 `rot_l`/`rot_r`
（`rot_r` 用 `rev ∘ rot_l ∘ rev` 实现，避免退化成 O(w²)）。每格每代只做约 9 次 O(1) 读取。

## 数字

### O(n) 的缩放 —— 单线程，64 代

| 网格 | 格数 | ms | ns / 格 / 代 |
|---|---|---|---|
| 32×32 | 1 024 | 5 | **76** |
| 64×64 | 4 096 | 18 | **69** |
| 128×128 | 16 384 | 67 | **64** |
| 256×256 | 65 536 | 314 | **75** |

格数涨 64 倍，每格代价基本不动 —— 这才是 O(n) 该有的样子。

（32×32 那一行的 5 ms 已经贴着 `IO.now()` 的 1 ms 分辨率，所以它的 ns 值只能算 ±20%；
粗粒度看后三行。）

### 并行能买到什么 —— 64×64，4 代

`life_par.bend` 把串行版改名 `block` 当**叶子**（连续算 `blk` 个格子），上套
一棵平衡二叉树 `tree_cells`：`a b = tree_cells(...) tree_cells(...)` 那一行就是
fork，join 处用 `app` 把两半拼起来。`2^d × blk = w×h` 覆盖全网格，`blk` 是粒度旋钮。

| threads | blk=1（4096 任务） | blk=16（256） | blk=64（64） |
|---|---|---|---|
| 1 | 1735 ms | 1958 | 1936 |
| 4 | 823 | 867 | 1043 |
| 10 | 676 | **628** | 986 |
| 加速比 | 2.57× | **3.12×** | 1.96× |

`user` 时间从 5.9 s 涨到 13.1 s，证明是真并行。10 核换 3.15 倍 ≈ 32% 效率。

**这段代码为了能被证明改过一次**（见下面「定律与证明」）。改之前是 `build`
（建树）+ `flatten`（摊平）两个函数，同一台机、同一时刻的对照：

| | blk=1 | blk=16 | blk=64 |
|---|---|---|---|
| 旧 build+flatten，1 线程 | 2081 | 2388 | 2512 |
| 旧，10 线程 | 503（**4.14×**） | 651（3.67×） | 1004（2.50×） |
| 新 tree_cells，1 线程 | **1735** | 1958 | 1936 |
| 新，10 线程 | 676（**2.57×**） | **628**（3.12×） | 986（1.96×） |

两个方向同时动了：

- **串行快了约 13%** —— `flatten` 要把整棵树再走一遍才拼回列表，`tree_cells`
  在 join 处直接拼。
- **并行反而变差**，最优粒度也从 blk=1 翻转成 blk=16。`app` 是串行工作，
  搬进 fork-join 区内部之后，每次 join 都有一个 worker 在拼接、另一个空转 ——
  正是指南那句 *"if one call finishes before the other, the speedup will be
  sub-ideal"*。

所以早先那句「粒度越细越快」只在旧的 `build`+`flatten` 结构下成立，
**不是调度器的性质**。并行数字必须和产生它的实现绑在一起记。

### 两个版本的直接对照 —— 64×64，16 代，都是单线程

| | ms |
|---|---|
| O(n²) `life_par.bend`（`d=0`，完全不 fork） | 7 840 |
| **O(n) `life_row.bend`** | **4** |

**约 2 000 倍。两个版本都没开线程 —— 差别全部来自算法。**

十个核的 O(n²) 版（676 ms，4 代）离单核的 O(n) 版还差两个数量级。
**并行是加在算法上的乘数，它不挑算法。**

这两条数字都由仓库里的代码复现：`./life_par --threads 1` 末尾的
"naive, no fork" 一段，和 `./life_row --threads 1` 末尾的对照一行。

## 定律与证明 —— LIFE_PAR_LAWS.bend / LIFE_PAR_PROOF.bend

`LIFE_PAR_LAWS.bend` 写下命题（人写），`LIFE_PAR_PROOF.bend` 证明它（AI 写）。
`bend LIFE_PAR_PROOF.bend` 打印 `All terms check.` 才算数。

> **定律**：树产出的格子序列，逐格等于同一个串行循环产出的序列。

```python
Par.tree_cells(d, g, w, h, blk, k) == Par.block(g, w, h, Par.cells_in(d, blk), k)
```

这是 `demos/pure_par_sum` 那条定律的同构版本（那边是「树的和 == 循环的和」），
把数字换成格子列表而已。

> 注：Bend 的约定是这一对叫 `LAWS.bend` + `PROOF.bend`，且放在项目根
> （`bend PROOF.bend` 就是文档里的 gate 命令）。这里反对的是**主题**前缀 ——
> 仓库里有六个主题目录，`LIFE_LAWS` 看不出证的是哪个。`LIFE_PAR_` 指的不是
> 主题而是**主语文件**：`life_par.bend` 的定律就是 `LIFE_PAR_LAWS.bend`，
> 于是 `import ./life_par.bend as Par` 和 `import ./LIFE_PAR_LAWS.bend as Laws`
> 读起来是同一件事。下一个实现接上同一个后缀，不会撞名。

### 证明的形状

对深度 `d` 归纳。目标写作 `{实现 == 规格}`，每一步重写都把**右边（规格侧）**
改写成实现的形状，直到两边是同一个项。三条引理：

- `add_zero` —— `Nat.add` 按第一个参数递归，`Nat.add(k, 0n)` 对变量 `k` 卡住；
- `add_assoc` —— 右子树的偏移要看成 `(k+1)+q` 才用得上归纳假设；
- `cells_add` —— 串行循环切两半：`n` 个格子接 `m` 个，等于 `n+m` 个。

### 三个坑

**① `%e : P` 里 `_` 的类型由语法位置推断。** `_` 标的是等式里 `b` 出现的位置，
而它的类型是看它**写在哪儿**推出来的。写 `Par.block(g, w, h, _, k)` 会把 `_`
推成 `Nat`（格子数），但 `b` 是整个 `block(...)`，类型是 `List` —— 报
`expected : Nat / observed : List<&2, Nat>`。标在 `app(..., _)` 或
`Con{cell, _}` 这类 List 位置上才对。

**② `block` 会展开成一个 cons。** `block(1+q+m, k)` 就是
`cellnext(k) <> block(q+m, k+1)`，待证的等式因此被压在 `cellnext(k) <> _` 底下，
而 `_` 只能标在那一层**下面**。`pure_par_sum` 没有这个问题，因为 `Nat.add`
没有 cons 结构 —— 这就是它的证明只有三行的原因，也是这里必须显式写出 cons 的原因。

**③ 让被证明的函数用同形的递归，可以省掉一条分配律。** 偏移原本写作
`Nat.mul(pow2(p), blk)`，那要在引理里把 `2^p·blk` 拆成两个 `2^(p-1)·blk` 之和，
需要乘法对加法的分配律。改成 `cells_in(p, blk)`（和树同一次递归，没有乘法）
之后这条引理整个消失了。

调试证明时用 `elide_errors.py`：失败的报错会把两边**完整展开**，
光 `cellnext` 一项就有几千字符，真正不同的地方看不见。它把那类项折成 `CELL`：

```sh
bend LIFE_PAR_PROOF.bend 2>&1 | python3 elide_errors.py
```

### 这个 gate 真的拦得住

「通过了」本身不是证据 —— 假证明也会通过。所以故意弄坏：

改动都做在**实现文件** `life_par.bend` 里（改 `LIFE_PAR_LAWS.bend` 是没用的 ——
那是规格，弄坏它只会让证明证不出别的东西）：

| 改动 | `bend LIFE_PAR_PROOF.bend` |
|---|---|
| `tree_cells` 右子树偏移 `Nat.add(k, cells_in(p, blk))` → `k` | **Error** |
| 叶子起点 `block(g, w, h, blk, k)` → `block(g, w, h, blk, 0n)` | **Error** |
| join 处 `app(a, b)` → `app(b, a)`（两半拼反） | **Error** |
| 原样 | `All terms check.` |

### 下一条定律：为什么「下标安全」是另一类问题

候选是 `at()` 的下标安全 —— 任何下标都落在 `0 .. w*h` 内：

```python
Nat.is_lt(Nat.add(Nat.mul(Nat.mod(y, h), w), Nat.mod(x, w)), Nat.mul(h, w))
```

它和 `tree_is_serial` 不是一类。上面那条是**纯结构性**的：列表归纳，
没有乘法、没有比较、没有 `Nat.cmp`。这条要靠**算术**，而 Base 里
**一条算术引理都没有**（`bend base | grep "-> {.*=="` 是空的）。

而且它不能直接写：`b = 0` 时 `Nat.mod(a, 0n) = a`，而 `a < 0` 是假的。
所以命题本身得带一个「`b` 为正」的前提。接下来每一步都要自己造：

| 需要的事实 | 代价 |
|---|---|
| `a < a + 1` | 一轮归纳，`{==}` 收尾 —— **好证**，实测通过 |
| `Nat.add` 的结合律 / 交换律 | 各一轮归纳（结合律见 `LIFE_PAR_PROOF.bend` 的 `add_assoc`） |
| `m + r == B` 时 `Nat.mod.fin(Nat.divmod.go(n,m,d,r)) < B + 1` | 对 `n` 归纳 + 内层分支；**退出分支要 `r ≤ m + r`，那是穿过 `Nat.cmp` 的双变量归纳** |
| `a < h` 且 `b < w` ⟹ `a*w + b < h*w` | `Nat.mul` 的分配律 + `Nat.cmp` 单调性，又是几轮归纳 |

**Bend 没有 tactics，Base 也没有引理库** —— 所以任何碰
`Nat.mod` / `Nat.mul` / `Nat.cmp` 的定律，都要自带一小套算术。

这不是 Bend 的缺陷，是它的定位：它是给 AI 写的规格语言，而引理库还没被写出来
（它自己的 README 说 Lean 形式化落后于 TypeScript 实现）。但它确实改变了**选哪条
定律当下一个** —— 离算术越近，越不划算。

**第二个数据点（`LIFE_ANIM` 那条定律）：`String` 这边同样一条引理都没有。**
Base 里连 `append(a, SNil) == a` 都不存在。但两笔库税的**难度**差一个量级：
String 引理是纯结构归纳（`append` 在第一个参数上 match，归纳一遍就完），
而 Nat 那套要穿过 `Nat.cmp` —— 那是双变量归纳。同一堵墙，一处是当天能交完的，
一处是交不完的。

## life_anim —— 让它动起来

`life_row.bend` 的引擎原样搬过来（那部分是 O(n) 的，40×16 的网格根本不费力），
外面套一层 `do IO`：写一帧 → `IO.sleep(70)` → 算下一代。就是普通的 IO 递归，
缩小的那个参数（剩余代数）排最左。

网格里放三种行为各一个，跑起来一眼能分辨：

| 图案 | 行为 |
|---|---|
| 滑翔机（左） | 每 4 代向右下平移一格 |
| 闪烁器（右上） | 横向 ↔ 竖向，原地周期 2 |
| 方块（右下） | 静止不动 |

一帧的渲染有两个坑，都踩过：

**① 不要整屏清。** 只用 `\u{1B}[H` 把光标拉回左上角再重画，就不闪；整屏 `[2J` 会闪。

顺带记住 Bend 的字符串转义**只有** `\n \t \r \0 \\ \' \" \u{...}` ——
**没有 `\e`，也没有 `\x1b`**，ESC 必须写 `\u{1B}`。
（写错的报错反而很好：它会直接把允许的转义全列出来。）

**② `String.reverse` 翻的是「字符」，不是「格子」。**

渲染为了避开 O(n²) 的 `append` 链，用的是"倒着攒 + 最后翻转一次"。
我一开始在**行**和**整屏**两级各翻了一次，于是行被多翻一遍 ——
症状是 **y 坐标全对，x 变成 `39-x`，整个图案左右镜像**。
现在整个帧只翻一次。

代价是：**每个格子必须是回文**（`"██"` / `"  "` 都是）。
换成 `"▐█"` 这种非回文格子，每行就会翻个个儿 —— 实测过，4×4 的滑翔机渲染成
`OXOX][][` / `][][OX][`，而不是 `[]XO[][]` / `[][]XO[]`。

**机制**（写注释时想反过一次，所以写清楚）：`rowrev` 里是
`append(cell(h), acc)` —— 它翻的是**格子顺序，格子内部一个字符都不动**；
而 `frame` 最后那次翻的是**字符**。两者复合得到

```
reverse (rowrev r) == map reverse (map cell r)
```

所以一排只在**每个格子等于它自己的字符反转**时才拼得对。回文不是注意事项，
是"整屏只翻一次"这个 O(帧长) 优化的**前提条件** —— 而这条现在由
`LIFE_ANIM_PROOF.bend` 机器强制（见下面）。

## 定律二 —— LIFE_ANIM_LAWS.bend / LIFE_ANIM_PROOF.bend

命题一句话：**快的那个渲染 == 慢的、显然正确的那个渲染**。

```python
def spec_row(+r) -> String      # 一排格子 → 字符串，直白的 append 链
def spec_rows(+rs) -> String    # 整屏，直白的 append 链

law frame_is_spec:
  for +rs: Rows
  {Anim.frame(rs) == String.append("\u{1B}[H", spec_rows(rs)) : String}
```

上面那条「每格必须是回文」的约束**是定理的一部分，不是注释**：证明里有一条
`cell_pal`，它同时是整条定律成立的原因。

### 先验证命题是真的，再去证

证一条假定律等于证谎话。所以动手前先用暴力检查跑了一遍：
`frame(rs)` 与 `String.append(ESC, spec_rows(rs))` 逐字符比较，5 个网格
（4×4、16×16、40×16，含演化 40 代之后的）全部相等，长度也对得上
（40×16 → 3 + 16×(80+1) = 1299，那条 ESC 是 3 个字符不是 1 个）。

### 形状与成本

七条引理，其中**五条是 Base 缺的标准库引理**，只有两条是这条定律自己的：

| 引理 | 谁需要它 |
|---|---|
| `append_nil2` / `append_assoc2` | Base 缺 |
| `reverse_go_spec` / `reverse_append2` | Base 缺（`reverse` 是累加器式，卡在变量上） |
| `pick_pal` / `cell_pal` | Base 缺 —— **这条就是回文约束本身** |
| `rowrev_spec` | 定律自己的：`reverse(rowrev(r, acc))` == 这排格子加逆序的 acc |
| `inner` + `frame_is_spec` | 定律自己的：`Rows` 上的累加器不变式 |

### 两个写法要点

- **改写注解的语义**：`%lem(args) : P` 里的 `P` 是**改写前**的目标，`_` 标在
  **引理右边（被消费的那一项）**的位置。所以引理要写成
  `{目标形式 == 目标里现在出现的形式}`。方向写反的时候 `%` 会明确报
  "expected / observed"，照着改就行，但一开始不知道的话会连撞三次。
- **参数修饰符看用法不看语义**：只在类型里出现的参数用 `-`，
  在**证明体**里被用到多次的要 `+`。`reverse_go_spec` 的 `acc` 看着像"擦除"，
  但它要出现在递归调用里，所以是 `+acc`。

### 这个 gate 拦得住什么

破坏都做在**实现文件** `life_anim.bend` 里：

| 改动 | `bend LIFE_ANIM_PROOF.bend` |
|---|---|
| `frame` 去掉最后的 `String.reverse`（行的顺序反了） | **Error** |
| 每行多翻一次（就是当年那个镜像 bug） | **Error** |
| `cell` 换成非回文的 `"▐█"` | **Error** |
| 原样 | `All terms check.` |

第二条值得单看：**当年靠眼睛发现的那个镜像 bug，现在是编译期拦下来的。**

#### ⚠️ 但破坏测试本身已经骗过我两次

**这两次都没写进过磁盘，只活在对话里，所以补在这里。**

破坏测试的形状是「改一处 → 跑 gate → 看它报不报」。它有一个致命的失败模式：
**替换没匹配上，文件一个字节没变，gate 打印 `All terms check.`** ——
症状和「gate 坏了」一模一样。两次都是这个：

**第一次**：本该改实现文件 `life_par.bend`，我改的却是规格文件 `LIFE_PAR_LAWS.bend`；
而且替换的字符串在规格里根本不存在，静默没匹配。

**第二次（2026-09-18）**：把 `"██"` 换成非回文的 `"▐█"` 去测 `LIFE_ANIM_PROOF`。
`life_anim.bend` 里 `"██"` 出现两次 —— 一次在 `cell` 的实现里，
**一次在上面解释回文约束的注释里**，而注释在前。替换落在注释上，代码没动。

所以规矩现在写死成：**替换前 `assert s.count(old) == 1`，只认唯一命中。**
两处都唯一命中的锚点，结果才可信。

`src/laws-1.md` 和 `src/laws-2.md` 里也记了这一条，因为它是「`All terms check`
不算证据」那句话的另一半：**一次没落地的破坏，就是一次没做的验证。**

## 跑

```sh
bend life.bend                      # 8×8，每代打印

bend life_anim.bend                 # 终端动画（320 代 × 70ms ≈ 22 秒）

bend life_par.bend -o life_par      # 原生才有并行
./life_par --threads 4

bend life_row.bend -o life_row
./life_row --threads 1

bend LIFE_PAR_PROOF.bend                # 证明 gate：打印 All terms check.
bend LIFE_ANIM_PROOF.bend               # 同上，动画那条
```

动画的长度和速度在 `life_anim.bend` 末尾改两处：`loop(320n, ...)` 的第一个参数，
和 `loop` 里的 `IO.sleep(70)`。两种后端都能跑，原生版实测是**流式输出**
（2s→39KB、4s→77KB），不是攒到最后一起吐。
