# arrays — reading an array gives you a *pair*

These are **probes**, and most of them are **deliberately wrong**. Each file tries one
way of "getting a value out of an array" to see which one passes. The failures matter
as much as the successes — together they draw the rule.

## The rule

The type of `a[i]` is

```
Sigma<&1, &1, Array<U32>, _ => U32>
```

that is, **a pair of the array and the element**. The reason is in
`../affinity/notes.md`: `Array` is a `Type` (not copyable), and in-place mutation
requires holding the array while you read or write it — so a read has to hand the
array back too.

There are exactly two ways to take that pair apart:

1. **Destructure in an argument or a field position** — `b_ok.bend`
2. **Use Base's projection** `Pair.fst` / `Pair.snd` — `c_base.bend`, `f_post3.bend`

What you cannot do is `(a2, v) = ...` on a local binding, in place. The error tells
you the way around it: *"give it its own def"*.

## The eight files

| File | What it tries | Result |
|---|---|---|
| `exp_arr.bend` | `U32.show(a[5] : U32)` | ❌ `expected : a term, observed ':'` |
| `exp_arr2.bend` | `(a2, v) = a[5]`, destructuring in place | ❌ `a match cannot scrutinize a computed value: give it its own def` |
| `a_fail.bend` | bind `p = a[5] <- 42` first, then take `p` apart | ❌ `a match cannot scrutinize a local binder` |
| `b_ok.bend` | destructure in an **argument** position | ✅ `43` |
| `c_base.bend` | `Pair.fst` / `Pair.snd` | ✅ `42` |
| `d_write.bend` | `Pair.snd(Array<U32>, U32, a[9] <- 7)` | ❌ type mismatch (a write does not return a Sigma) |
| `e_post1.bend` | return `a[5]` as-is | ✅ prints `([0,0,0,0,0,42,0,0], 42)` |
| `f_post3.bend` | `Pair.fst` to get the array back, then `Pair.snd(b[5])` | ✅ `42` |

The output of `e_post1.bend` is the one that explains it: the return value **carries
the entire array**, `Array<U32> & U32`. That is not a bug — it is the price of
affinity guaranteeing that in-place mutation needs no copy.

## Running

```sh
cd arrays
bend b_ok.bend             # ✅ 43
bend exp_arr2.bend         # ❌ on purpose
```

Book: chapter 10.
