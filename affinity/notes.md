# 仿射性（Affinity）—— Bend 2 的第一把钥匙

> 本文件由一次 cordis-agent 教学会话产出，所有实验均在本机实跑（Bend 2.0.5，M3 Max）。
> 实验文件都在本目录下（`t1_*.bend` … `t9_*.bend`、`affine_bad.bend`），官方指南全文见 `bend guide`（或 `~/.bend/guide/GUIDE.md`）。

---

## 一、英文术语

| 中文 | 英文 | 含义 |
|---|---|---|
| 仿射性 | **affinity** | 这个性质本身 |
| 仿射的 | **affine** | 形容词，`Bend is affine` |
| 仿射类型系统 | **affine type system** | 整套系统 |
| 子结构类型系统 | **substructural type system** | 上位概念 |

- 标准参考文献：**David Walker, "Substructural Type Systems"**, 收于 Pierce 编
  *Advanced Topics in Types and Programming Languages*, MIT Press, 2005, 第一章。
- 源头：**Jean-Yves Girard, linear logic, 1987**。

### 名字来自哪：三条「结构规则」

| 规则 | 英文 | 意思 |
|---|---|---|
| 弱化 | **weakening** | 可以丢弃没用到的假设 |
| 收缩 | **contraction** | 可以复制一个假设用两次 |
| 交换 | **exchange** | 可以重排顺序 |

- **linear logic** = 三条全砍掉 → 恰好一次
- **affine logic** = 只加回 weakening → 至多一次
- **relevant logic** = 只加回 contraction → 至少一次
- 普通语言 = 三条全有 → 任意次

```
恰好一次  linear       (线性)
至多一次  affine       (仿射)  ← Bend 在这里，也是 Rust
至少一次  relevant     (相关)
任意次    unrestricted (普通语言)
```

**词源**（未查原始出处，常见说法）：命名类比仿射几何 —— 线性组合要求所有系数都在，
仿射组合允许某个系数为 0，即允许「丢掉一项」。所以「可以丢弃」这个性质叫 affine。

**关键直觉**：`affine` 与 `linear` 的差别**只有一件事** —— 能不能不用。Bend 选了「能」。

---

## 二、精确定义

> **一个值，在任何一条执行路径上，最多被使用一次。**

注意是「路径」，不是「出现次数」。

指南原文（`bend guide`，Types and Functions）：

> Bend, by default, is *affine*, meaning variables must be used, at most, once.

---

## 三、实验证据（全部实跑）

| 实验 | 代码 | 结果 | 说明 |
|---|---|---|---|
| `t1_drop` | `x = {3:U32}` 声明后从不用 | ✅ 输出 `7` | **可以不使用！** affine ≠ linear |
| `affine_bad` | `x` 用了两次 | ❌ `x (consumed more than once)` | 核心限制 |
| `t2_plus` | `+x = {3:U32}` 用两次 | ✅ 输出 `6` | `+` 是逃生口 |
| `t7_paths` | `x` 在 match **两个分支都出现** | ✅ 输出 `11` | **按路径算，不按出现次数** |
| `t9_listonly` | `List<U32>` 用两次（无 `+`） | ❌ `consumed more than once` | 列表也遵守 |
| `t8_listplus` | `+List<U32>` 用两次 | ✅ 输出 `6n` | 代价是运行时引用计数 |
| `t4_arrplus` | `+a = [0 : U32*4n]` | ❌ **`expected : Data, observed : Type`** | `+` 不是万能钥匙 |
| `t5_closure` | 闭包 `f` 调用两次 | ❌ `consumed more than once` | **闭包永远不能复制** |
| `t6_closureplus` | 试图给闭包加 `+` | ❌ 同样被拒 | 加不了 |

### 两个层级

**quantity（量）—— 写在变量上**

```
-x   擦除（erased）    只出现在类型和证明里，运行时被删掉
x    仿射（affine）    默认值，至多一次
+x   可重用（reusable） 要求类型是 Data，代价是引用计数
```

**kind（种类）—— 写在类型上**

```
Type = Kind(&1)   至多一次 ——「有身份」的东西
Data = Kind(&2)   可复制   ——「无身份」的东西
```

`+` 为什么要求 `Data`：复制一个东西的前提是它能被复制。

`t4_arrplus` 的报错 `expected : Data, observed : Type` 就是全部答案。

Base 库实测：**13 个 `is Data`，3 个 `is Type`**，那 3 个是：

```
Array      一块可变内存
IO.OP      一个 IO 操作
App        一个应用/窗口状态
```

全是「有身份」的东西。复制一块可变内存会打破「就地改写」的保证；复制 IO 句柄是伪造资源。
而 `List<U32>` 是 Data —— 复制它只是复制结构。

这解释了 `t8` 能过而 `t4` 不能：`+List<U32>` 合法，`+Array<U32>` 非法。

---

## 四、为什么是「第一把钥匙」

**一个机制**：一个值在同一时刻只有一个持有者。

**三个回报**，全是这一个机制的推论：

### 回报 1：内存 —— 没有 GC

> There is no garbage collector. Since values are affine, a `match` frees the node it
> opens on the spot, and only `+` values carry a reference count.  （`bend guide`，Under the Hood）

拆 = 取 + 释放，是同一个动作。这解释了为什么 Bend 强制你用 `match` 拆值 —— 不是风格，
是它内存管理的唯一方式。

### 回报 2：并行 —— 无锁，且不需要你论证

> A parallel call promises the compiler two things: 1. The calls are independent.
> 2. They run in roughly the same time.
> **Since Bend is pure and affine, the first point always holds.** The second is yours
> to keep.  （`bend guide`，Parallelism）

- 第 1 条由类型系统免费给：x 只有一个持有者，两个并行调用在类型上不可能有别名。
- 第 2 条才是人的工作：负载均衡。

反过来更厉害：会 race 的东西**根本写不出来**。Array 是 `Type`，没有语法能把它交给两个
并行调用。

### 回报 3：证明可擦除 —— 零运行时开销

`-x`（erased）：检查器看得见，编译器删掉。证明在运行时不存在。

---

## 五、代价

1. **函数参数默认被消耗**。`f(xs)` 之后 `xs` 就没了。
2. **没有借用（borrow）**。grep 全份指南 `borrow` 零命中（已核实）。
3. **闭包仿射，且加不了 `+`**。`t5`/`t6` 证明：什么都不捕获的闭包也只能调用一次。

与 Rust 的分水岭：

| | Rust | Bend 2 |
|---|---|---|
| 默认 | 仿射（move） | 仿射 |
| 想临时用一下 | `&x` 借用 | ❌ 没有这个概念 |
| 想用两次 | `.clone()` / 改所有权结构 | `+x`，引用计数 |
| 想在运行时不要它 | 单态化 | `-x` 擦除 |

闭包的解法很漂亮 —— **模板参数 `~f`**：

```python
def twice(~f: U32 -> U32, x: U32) -> U32:
  f(f(x))
```

`~` 参数在**编译期内联**，每套实参编译出一份自己的 `twice`。所以 `f` 可调用任意次，
且运行时成本为零 —— 不是函数指针，是内联。

**类型系统限制「闭包不可复制」，推出的不是「多写代码」，而是「把函数内联进去」——
一个限制变成了更快的实现。**

---

## 六、一句话总结

> **仿射性 = 每个值至多被消费一次。**
>
> 换来：没有 GC 的内存管理 + 不需要锁也不需要论证的并行 + 可以完全擦除的证明。
> 代价：没有借用，所以到处要显式标注和复制。

Bend 的三个卖点（快 / 并行 / 可证明）**不是三件事，是同一件事的三个后果**。
接受了「一个值只有一个持有者」，剩下的都是推论。

---

## 延伸阅读关键词

`substructural type systems` · `affine types` · `linear logic` ·
`Walker ATTAPL chapter 1` · `Rust affine type system` ·
`uniqueness types (Clean)` · `Linear Haskell`

---

## 未解决 / 待跟进

- `t3_arr.bend` 未跑通：`a[i]` 读取返回 `Sigma<&1,&1,Array<U32>,_=>U32>`（数组与元素的对），
  但 `(a2, b) = p` 被拒 —— 报错「a match cannot scrutinize a local binder」。
  Sigma 的投影方式（`.fst`/`.snd`? 专用 def?）未确定。
- GPU 声称未验证：`pow2!(26n)` 在 M3 Max 上比纯 CPU 慢（0.13s vs 0.04s @14 线程），
  但该负载每任务只做 1 次加法，是任务开销主导，不足以证伪。需换重负载（mandelbrot）复测。
