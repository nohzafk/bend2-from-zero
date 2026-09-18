# affinity

**The first key to understanding anything in Bend.** This is the only directory in
the repo with formal notes: read `notes.md` first (199 lines — terminology,
definitions, experimental evidence, payoffs, costs).

In one sentence: **a value has exactly one holder at a time.**

## The files

The tables in `notes.md` reference these; all of them have been run.

| File | What it tries | Result |
|---|---|---|
| `t1_drop.bend` | declare `x = {3:U32}` and never use it | ✅ prints `7` — **unused is fine**, affine ≠ linear |
| `affine_bad.bend` | use `x` twice | ❌ `x (consumed more than once)` |
| `t2_plus.bend` | use `+x` twice | ✅ `6` — `+` is the escape hatch |
| `t7_paths.bend` | `x` appears in both arms of a `match` | ✅ `11` — **counted per path, not per occurrence** |
| `t9_listonly.bend` | use a plain `List<U32>` twice | ❌ `consumed more than once` |
| `t8_listplus.bend` | use `+List<U32>` twice | ✅ `6n` — the price is runtime reference counting |
| `t4_arrplus.bend` | put `+` on an array: `+a = [0 : U32*4n]` | ❌ `expected : Data, observed : Type` |
| `t5_closure.bend` | call a closure twice | ❌ `consumed more than once` |
| `t6_closureplus.bend` | put `+` on a closure | ❌ `expected : Data, observed : Type` — **the same error as the array** |
| `t10_template.bend` | a `~f` template parameter, called twice | ✅ `42` — the real answer to the closure problem |
| `t11_templatemiss.bend` | the same, but the call site omits `~` | ❌ `consumed more than once` |
| `t3_arr.bend` | read from an array | ❌ see below |

## Two levels

**quantity — written on a variable**

```
-x   erased      appears only in types and proofs; deleted at run time
x    affine      the default; at most once
+x   reusable    requires the type to be Data; the price is reference counting
```

**kind — written on a type**

```
Type = Kind(&1)   at most once — something with identity
Data = Kind(&2)   copyable     — something without identity
```

Why `+` demands `Data` is direct: **the precondition for copying a thing is that it
can be copied.** The error from `t4_arrplus`, `expected : Data, observed : Type`, is
the whole answer.

Measured over Base: 22 type declarations — 13 `is Data`, 3 `is Type`, and 6
(`List`/`Maybe`/`Either`/`Result`/`Map`/`Sigma`) that are `is Kind(...)`, parameterised
by the kind of their own element. Those 3 `Type`s are `Array` (a block of mutable
memory), `IO.OP` (an IO operation) and `App` (a window state) — all things with identity.

## Why `t3_arr` does not pass

`a[i]` does not read out the element; it reads out a **Sigma**, a pair of the array
and the element. Taking that pair apart has its own rules, and that is what the whole
of `../arrays/` is about.

## Two corrections (found by re-running, 2026-09-18)

While writing the tutorial every probe was re-run, and two of them turned out to be
**cases of the notes being wrong**:

**① `t6_closureplus.bend` was testing nothing.** It was written as
`+f = (x: U32) => ...`, which is not how a closure is written in Bend — it reports
`expected : an annotated term (cannot infer)`, a plain syntax error with nothing to do
with `+`. The note's conclusion ("a closure cannot take `+`") was **right, but it
rested on nothing**. Rewritten the way `t5` compiles, the real error appears:
`expected : Data, observed : Type` — identical to the array's. So the array and the
closure are now two examples of one rule, which is a better story than two anecdotes.

**② A `~f` template parameter must carry its `~` at the call site too.** The note
quoted the function definition without the call site, so `twice(inc, 5)` looked like
it should work. It does not: without the `~` the argument decays to an ordinary
affine value and you get `expected : -f / observed : f (consumed more than once)` —
an error that reads like "a closure cannot be called twice" but actually means "you
omitted a `~`". The guide's own example is
`twice(~(x => (x + 1 : U32)), 40)`. Now covered by the `t10`/`t11` pair.

Both were **the same mistake**: using a failed experiment to support a correct
conclusion, without checking whether it failed for the reason you assumed.

## Running

```sh
cd affinity
bend t1_drop.bend               # ✅
bend affine_bad.bend            # ❌ fails on purpose
bend t10_template.bend          # ✅
bend t11_templatemiss.bend      # ❌ fails on purpose
```

Book: chapters 8–9.
