# affinity — 仿射性

**理解 Bend 一切的第一把钥匙。** 这个目录是整个仓库里唯一有正式笔记的：
先读 `notes.md`（199 行，含术语、定义、实验证据、回报、代价）。

一句话：**一个值在同一时刻只有一个持有者。**

## 目录里的文件

`notes.md` 里的表格引用的就是这些文件，全部实跑过。

| 文件 | 试什么 | 结果 |
|---|---|---|
| `t1_drop.bend` | `x = {3:U32}` 声明后从不用 | ✅ 输出 `7` —— **可以不使用**，affine ≠ linear |
| `affine_bad.bend` | `x` 用了两次 | ❌ `x (consumed more than once)` |
| `t2_plus.bend` | `+x` 用两次 | ✅ `6` —— `+` 是逃生口 |
| `t7_paths.bend` | `x` 在 `match` 两个分支里都出现 | ✅ `11` —— **按路径算，不按出现次数** |
| `t9_listonly.bend` | `List<U32>` 用两次（无 `+`） | ❌ `consumed more than once` |
| `t8_listplus.bend` | `+List<U32>` 用两次 | ✅ `6n` —— 代价是运行时引用计数 |
| `t4_arrplus.bend` | 给数组加 `+`：`+a = [0 : U32*4n]` | ❌ `expected : Data, observed : Type` |
| `t5_closure.bend` | 闭包调用两次 | ❌ `consumed more than once` |
| `t6_closureplus.bend` | 给闭包加 `+` | ❌ `expected : Data, observed : Type` —— **和数组同一个错** |
| `t10_template.bend` | `~f` 模板参数，调用两次 | ✅ `42` —— 闭包问题的正解 |
| `t11_templatemiss.bend` | 同上但调用点漏写 `~` | ❌ `consumed more than once` |
| `t3_arr.bend` | 数组读 | ❌ 见下 |

## 两个层级

**quantity（量）—— 写在变量上**

```
-x   擦除      只出现在类型和证明里，运行时删掉
x    仿射      默认，至多一次
+x   可重用    要求类型是 Data，代价是引用计数
```

**kind（种类）—— 写在类型上**

```
Type = Kind(&1)   至多一次 ——「有身份」的东西
Data = Kind(&2)   可复制   ——「无身份」的东西
```

`+` 要求 `Data` 的道理很直接：**复制一个东西的前提是它能被复制**。
`t4_arrplus` 的报错 `expected : Data, observed : Type` 就是全部答案。

Base 实测 22 个类型声明：13 个 `is Data`、3 个 `is Type`，另外 6 个
（`List`/`Maybe`/`Either`/`Result`/`Map`/`Sigma`）是 `is Kind(...)`，由自己的
元素种类参数化。那 3 个 `Type` 是 `Array`（一块可变内存）、`IO.OP`（一个 IO 操作）、
`App`（一个窗口状态）—— 全是「有身份」的东西。

## t3_arr 为什么没跑通

`a[i]` 读出来不是元素，是一个 **Sigma**（数组与元素的对）。要把它拆开有讲究，
那正是隔壁 `../arrays/` 整个目录在讲的事。

## 两处更正（2026-09-18 重跑时发现）

写教程时把全部探针重跑了一遍，抓到两个**笔记自己错了**的地方：

**① `t6_closureplus.bend` 原本什么都没测到。** 它写的是 `+f = (x: U32) => ...`，
而这不是 Bend 里闭包的写法 —— 报的是 `expected : an annotated term (cannot infer)`，
一个纯粹的语法错，跟 `+` 无关。笔记据此写下的「闭包加不了 `+`」**结论是对的，
立论是空的**。改用 `t5` 里那个能编译的写法后，才拿到真正的报错：
`expected : Data, observed : Type` —— 和数组一模一样。现在数组和闭包是同一条规则
的两个例子，比原来更好讲。

**② `~f` 模板参数的调用点也要写 `~`。** 笔记里贴的是函数定义，没贴调用点，于是
看起来像 `twice(inc, 5)` 就该行。实际不行：实参没有 `~` 就退化成普通仿射值，
报 `expected : -f / observed : f (consumed more than once)` —— 一个读起来像
「闭包不能调两次」、其实在说「你漏了个 `~`」的错。指南的原文例子是
`twice(~(x => (x + 1 : U32)), 40)`。已补成 `t10`/`t11` 一对正反例。

两次都是**同一个毛病**：拿一个失败的实验去支撑一个正确的结论，而没有检查
失败的原因是不是自己以为的那个。

## 跑

```sh
cd affinity
bend t1_drop.bend               # ✅
bend affine_bad.bend            # ❌ 故意失败的
bend t10_template.bend          # ✅
bend t11_templatemiss.bend      # ❌ 故意失败的
```
