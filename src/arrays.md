# Arrays: a read hands you a pair

Everything in this chapter comes from one type signature:

```
a[i]  ::  Sigma<&1, &1, Array<U32>, _ => U32>
```

Reading an element out of an array does not give you the element. It gives you
**the array and the element, together**. This is the single most surprising
thing in Bend's surface syntax, and it is not a quirk — it is forced, and the
chapter is mostly about seeing why.

## Watch it happen

The clearest demonstration is to just print what you get back:

```python
{{#include ../arrays/e_post1.bend}}
```

```
$ bend e_post1.bend
([0, 0, 0, 0, 0, 42, 0, 0], 42)
```

A pair. On the left, the whole array with the write visible in it; on the right,
the element that was asked for.

## Why it is forced

From the previous chapter: `Array` is `Type`. It is the one thing in the language
you may rewrite in place, and it is not copyable — that is exactly the trade that
makes in-place rewriting need no copy.

Now suppose a read gave you just the `U32`. Where would the array go? The read
has to *hold* the array to look inside it, and since the array may not be
duplicated, the read cannot keep a copy and hand you the value. It must give the
array back. So the return type is a pair, and there is no version of this design
that returns a bare element.

This is the affinity rule from chapter two, arriving at the syntax you actually
type.

## Four ways to try to get the value out

The obvious attempts do not work, and the errors are worth reading in full
because together they draw a precise line.

**Try to assert the type.** `a[5] : U32`:

```python
{{#include ../arrays/exp_arr.bend}}
```

```
Error:
- expected : a term
- observed : ':'
```

The ascription is not even parsed here. A pair is not a `U32` and saying so does
not make it one.

**Try to destructure it where it is written.** `(a2, v) = a[5]`:

```
Error:
- message  : a parameter or field scrutinee (a match cannot scrutinize a computed value: give it its own def)
```

**Try to name it first, then destructure.** `p = a[5]` then `(a2, b) = p`:

```python
{{#include ../arrays/a_fail.bend}}
```

```
Error:
- message  : a parameter or field scrutinee (a match cannot scrutinize a local binder: give it its own def)
```

Notice that those two messages are the same rule with two different subjects: a
*computed value*, and a *local binder*. Bend will only take a pair apart where it
is already a thing you were handed — a parameter, or a field. In between, you are
not allowed to hold it and look at it.

And notice what the compiler does about it: **it tells you the workaround.** *Give
it its own def.* That instruction is not a hint, it is the whole solution, and it
is the same shape as the `nth` trap in the chapters ahead.

## The two ways that work

**Give it its own def, and destructure in the parameter position:**

```python
{{#include ../arrays/b_ok.bend}}
```

```
$ bend b_ok.bend
43
```

Running `unzip` and `value` as separate functions is not stylistic padding.
Those two functions exist because that is the only place a pair may be opened.

**Or use the projections that `Base` ships**, which are typed by the pair's own
two halves:

```python
{{#include ../arrays/c_base.bend}}
```

```
$ bend c_base.bend
42
```

`Pair.fst` and `Pair.snd` take the two half-types as their first two arguments
and then the pair. They exist precisely so that you do not have to write a def
per read.

## What a write returns

A write, `a[i] <- v`, is a different thing, and its type is easy to guess wrong.
Asking for the wrong half makes Bend print both:

```python
{{#include ../arrays/d_write.bend}}
```

```
Error:
- expected : Sigma<&1, &1, Array<U32>, _ => U32>
- observed : Array<U32>
```

Those two lines are the answer. A **read** returns
`Sigma<&1, &1, Array<U32>, _ => U32>` — a pair. A **write** returns the bare
`Array<U32>`, because there is no element to hand back; you supplied it.

And on its own line, a write rebinds:

```python
a[5] <- 42      # this is sugar for:  a = a[5] <- 42
```

which is why the pattern in every probe above is a write followed by reads
against the same name.

## The files

| | | |
|---|---|---|
| [`arrays/e_post1.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/arrays/e_post1.bend) | ✅ | print the pair, see the pair |
| [`arrays/b_ok.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/arrays/b_ok.bend) | ✅ | destructure in a parameter |
| [`arrays/c_base.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/arrays/c_base.bend) | ✅ | `Pair.fst` / `Pair.snd` |
| [`arrays/exp_arr.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/arrays/exp_arr.bend) | ❌ | `a[5] : U32` |
| [`arrays/exp_arr2.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/arrays/exp_arr2.bend) | ❌ | destructure a computed value |
| [`arrays/a_fail.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/arrays/a_fail.bend) | ❌ | destructure a local binder |
| [`arrays/d_write.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/arrays/d_write.bend) | ❌ | the wrong half of a write |

---

That is the whole idea. Affinity, kinds, and the pair — one mechanism, spread
over three chapters, and at this point you have seen everything in Bend that is
genuinely unlike other languages.

The rest of the book is what that mechanism *buys*: [parallelism that cannot
race](parallel.md), [a GPU path where the compiler does the memory
management](gpu.md), and finally [proofs the compiler checks](laws-1.md).
