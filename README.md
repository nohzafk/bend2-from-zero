# bend2-play

玩 [Bend 2](https://github.com/bendlang/bend) 的实验记录。

每个目录是一个主题，里面既有能跑的代码，也有**故意写错、用来把编译器逼出话**的探针 ——
后者往往比读文档学到得多，所以它们被保留下来，并在 README 里注明"这是❌，报错是什么"。

- 环境：Bend 2.0.5，macOS，Apple M3 Max（10 性能核 + 4 能效核）
- `bend/` 是上游仓库的 clone，**不是我们的代码**，只作参考（不要在它里面改东西）

## 教程（mdBook）

`src/` 是一本从零写的 Bend 2 教程，`book.toml` 是它的 mdBook 配置：

```sh
mdbook serve      # http://localhost:3000
mdbook build      # 输出到 book/（已 gitignore）
```

书里出现的每个 ❌ / ⚠️ 都对应仓库里一个**真实可跑的探针文件** —— 报错原文是粘贴的
运行结果，不是手写的，所以你能自己复现每一处。

`src/` 下有一组指向各主题目录的符号链接。这是必须的：mdBook 只复制 `src/` 内的
非 md 文件，所以 `[hello_bad.bend](../basics/hello_bad.bend)` 在渲染出的 HTML 里
**是死链**。有了链接，mdBook 会走进去把 `.bend` 带进 `book/` —— 链接活了，
HTML 书也变成自包含的。

## 环境

```sh
curl -fsSL https://bend-lang.com/install.sh | sh
bend --version                                       # 本仓库用 2.0.5 写的
```

**装在哪**：`${BEND_HOME:-$HOME/.bend}` —— 本机没设 `BEND_HOME`，所以是 `~/.bend`：

| 路径 | 是什么 |
|---|---|
| `~/.bend/bin/bend` | 一个 3.5 KB 的 **POSIX shell 启动器**（解析版本 → 自动更新 → 交给 bun 去跑） |
| `~/.bend/current` | 软链，指向 `~/.bend/app/2.0.5/ZRx01G` |
| `~/.bend/app/<版本>/<hash>/` | 真正被解释执行的 TS 源码 |

仓库里那个 `bend/` **不是它** —— 那是上游源码 clone，同名但毫无关系。

那个启动器默认发匿名遥测（每次运行后台 POST `{id, ver, os, arch, cmd, exit, ms}` 到 `bend-lang.com/ping`），并会自动下载新版本。`BEND_NO_TELEMETRY=1` 关掉。

## 怎么跑

```sh
# 解释执行：JS 后端
bend basics/hello.bend

# 原生编译：才有真正的多核
cd life && bend life_row.bend -o life_row && ./life_row --threads 8
```

**两种后端差别很大，这是最容易踩的一个坑：**

| | 解释执行 | 原生编译 |
|---|---|---|
| 并行 | **完全串行**，`a b = f(x) g(y)` 不会 fork | 真的多核 |
| GPU (`f!(x)`) | 忽略 | 交给 Metal，旁边生成一个 `.gpu` MetalLib 文件 |
| 速度 | 慢一个量级 | 快 |
| 用途 | 看结果、看类型错误 | **量性能只能用它** |

第一次量化时我就是在解释执行下量的并行，得到"并行没用"的错误结论。

## 目录

| 目录 | 讲什么 |
|---|---|
| `basics/` | 第一次接触：hello、字符串、取模、列表 |
| `affinity/` | **仿射性** —— 理解 Bend 一切的第一把钥匙（含 199 行笔记 `notes.md`） |
| `arrays/` | 数组读出来的是一个「对」，以及怎么把它拆开 |
| `parallel/` | CPU 上的 fork-join：`a b = f(x) g(y)` |
| `gpu/` | `f!(x)` 与 Metal；mandelbrot 与 queens 的胜负 |
| `life/` | 生命游戏：三种写法（O(n²)串行 / O(n²)并行 / O(n)串行）+ 终端动画 + `LIFE_PAR_LAWS.bend`/`LIFE_PAR_PROOF.bend` 一条定律的完整证明 |
| `GUIDE.txt` | 官方指南全文（本地副本，笔记里的 `GUIDE.txt:NNN` 指的就是它） |

## 结论速查

写代码前值得先知道、而且**报错不会直接告诉你**的那些：

**仿射性**

- 仿射 ≠ 线性：一个值**至多用一次**，一次都不用是合法的
- `+x` 是逃生口，但类型必须是 `Data`（`expected : Data, observed : Type`）
- `Type` = `Kind(&1)` = 「有身份」的东西，不可复制。Base 里只有 3 个：
  `Array`、`IO.OP`、`App` —— 全是可变内存 / 资源句柄
- **闭包永远不能复制**，`+` 也救不了
- 判断按**执行路径**算，不按出现次数：`match` 两个分支里各用一次是合法的

**语法形状**

- 没有 `if`：用 `match` 到 `True{}` / `False{}`，或 `Bool.pick(T, cond, a, b)`
- `match` 只能看**参数**或字段，不能看局部变量，也不能看计算结果
  → 报错会直接说 "give it its own def"，照做
- 签名用圆括号 `-> IO(Unit)`，do 块用尖括号 `do IO<Unit>:`。写反了报
  `unknown: IO`，读起来像没 import
- 构造子是位置参数 `SCon{Chr{c}, SNil{}}`；字段名只用在模式里
- 并行 let 必须写在一行
- 自递归时，**缩小的那个参数必须排最左**，否则终止检查器拒绝

**性能**

- `bend` 解释执行永远串行；量并行必须原生编译
- 原生编译下 `a b = f(x) g(y)` 自动 fork 到多核，`f!` 才额外交给 GPU
- **先选算法再上核**。见 `life/`：同一个生命游戏、同一个 64×64 网格、同样 16 代、
  同样单线程，O(n²) 要 8069 ms，O(n) 只要 5 ms —— 约 1600 倍，全部来自算法，
  和核数无关（十个核只换来 3.15 倍，见下一条）
- **并行数字必须和产生它的实现绑在一起记**。见 `life/README.md`：为了能被证明
  重构过一次，串行快了 13%，10 线程加速比却从 4.15× 掉到 2.67×，最优粒度也从
  blk=1 翻转成 blk=16。同一个算法换个写法，结论就反了
- **`LAWS.bend` 的 gate 真的拦得住**。见 `life/LIFE_PAR_PROOF.bend`：改坏 `tree_cells`
  的偏移或 `block` 的取值，`bend` 立刻拒绝；`pure_par_sum` 那条同构定律的证明
  只有三行，因为 `Nat.add` 没有 cons 结构，而列表有
- **每个 `!` 程序要先交约 85ms 的固定入场费**，和它算多少无关（`gpu_floor` 算 4 和
  `pow2!(26n)` 算 6700 万一样贵，同一进程调两次也只多几毫秒）。所以 **GPU 的墙钟数字
  不是关于 GPU 的陈述**：扣掉这笔门费，mandelbrot 从「快 6×」变成「快约 20×」，
  而 pow2 根本不是在比算术。想知道你在量哪一个，写一个什么都不干的 `!` 程序去量它。
  见 `gpu/README.md`
