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
| `t6_closureplus.bend` | 试图给闭包加 `+` | ❌ 同样被拒 —— **闭包永远不能复制** |
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

Base 实测 13 个 `is Data`、3 个 `is Type`，那 3 个是 `Array`（一块可变内存）、
`IO.OP`（一个 IO 操作）、`App`（一个窗口状态）—— 全是「有身份」的东西。

## t3_arr 为什么没跑通

`a[i]` 读出来不是元素，是一个 **Sigma**（数组与元素的对）。要把它拆开有讲究，
那正是隔壁 `../arrays/` 整个目录在讲的事。

## 跑

```sh
cd affinity
bend t1_drop.bend          # ✅
bend affine_bad.bend       # ❌ 故意失败的
```
