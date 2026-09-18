# arrays — 数组读出来的是一个「对」

这些是**探针**，大部分**故意是错的**。每个文件试一种「想把数组里的值拿出来」的写法，
看哪一种能过。失败的那些和成功的一样重要 —— 它们共同划出了那条规则。

## 规则

`a[i]` 的返回类型是

```
Sigma<&1, &1, Array<U32>, _ => U32>
```

也就是**数组与元素的对**。原因在 `../affinity/notes.md`：`Array` 是 `Type`（不可复制），
「就地改写」要求读写这个数组时同时握住它，所以读操作必须把数组一起交还。

要拆开这个对，只有两条路：

1. **在参数或字段的位置解构** —— `b_ok.bend`
2. **用 Base 自带的投影** `Pair.fst` / `Pair.snd` —— `c_base.bend`、`f_post3.bend`

不能做的：在一个局部绑定上直接 `(a2, v) = ...`。报错会直接告诉你怎么绕：
*"give it its own def"*。

## 八个文件

| 文件 | 写法 | 结果 |
|---|---|---|
| `exp_arr.bend` | `U32.show(a[5] : U32)` | ❌ `expected : a term, observed ':'` |
| `exp_arr2.bend` | `(a2, v) = a[5]` 就地解构 | ❌ `a match cannot scrutinize a computed value: give it its own def` |
| `a_fail.bend` | 先 `p = a[5] <- 42`，再拆 `p` | ❌ `a match cannot scrutinize a local binder` |
| `b_ok.bend` | 在**参数**位置解构 | ✅ `43` |
| `c_base.bend` | `Pair.fst` / `Pair.snd` | ✅ `42` |
| `d_write.bend` | `Pair.snd(Array<U32>, U32, a[9] <- 7)` | ❌ 类型不符（写返回的不是 Sigma） |
| `e_post1.bend` | `a[5]` 直接当返回值 | ✅ 打印出 `([0,0,0,0,0,42,0,0], 42)` |
| `f_post3.bend` | `Pair.fst` 拿回数组，再 `Pair.snd(b[5])` | ✅ `42` |

`e_post1.bend` 的输出最能说明问题：返回值**带着整个数组**，`Array<U32> & U32`。
这不是 bug，是仿射性在保证「就地改写不需要拷贝」的代价。

## 跑

```sh
cd arrays
bend b_ok.bend             # ✅ 43
bend exp_arr2.bend         # ❌ 故意的
```
