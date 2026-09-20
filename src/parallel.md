# Parallel by default: fork-join

Bend's parallelism primitive is an ordinary assignment. There is no keyword, no
annotation, no runtime to configure:

```python
a b = f(x) g(y)      # two calls, each becomes a task, then they join
```

That is the whole language surface. Everything else in this chapter is about
what it does and does not buy you.

## Two promises, and only one of them is yours

The guide states the contract:

> A parallel call promises the compiler two things: 1. The calls are
> independent. 2. They run in roughly the same time.
>
> — `bend guide`, *Parallelism*

**The first promise is not something you assert.** It is something the type
system has already made true, and this is the payoff from the affinity chapters
arriving in earnest. A value has one owner. If `x` is owned by the call on the
left, the call on the right cannot be touching it — not "should not be", *cannot*,
because there is no second name for it to hold. So `f(x) g(y)` cannot race, and
you did not have to prove it.

It goes further than "no locks needed". The one type in `Base` that can be
rewritten in place is `Array`, and `Array` is `Type` — not copyable. So there is
**no syntax in the language** that hands the same array to both sides of a
parallel call. Racing on an array is not forbidden; it is unspellable.

**The second promise is the entire human job.**

Bend's scheduler is a binary fork-join machine, in the words of the guide,
*contention-free*: every task is handed to a core exactly once and never
migrates afterwards. That is what makes it fast, and it is also what makes load
balancing your problem. If one side of your fork takes ten times as long as the
other, no amount of cores helps — one core does everything while the rest wait at
the join.

## What it looks like when it works

Here is a function whose body is a balanced binary tree, which is the shape the
scheduler likes:

```python
{{#include ../parallel/pow2_26.bend}}
```

`pow2(26n)` is 2^26 = 67,108,864 additions, arranged as a complete binary tree
of forks. Native-compiled, three runs per configuration:

| `--threads` | real | user |
|---|---|---|
| 1 | 0.223 – 0.229 s | 0.205 – 0.212 s |
| 2 | 0.126 s | 0.215 s |
| 4 | 0.074 – 0.076 s | 0.227 – 0.231 s |
| 8 | **0.048 – 0.050 s** | 0.236 – 0.237 s |
| 14 | 0.045 – 0.049 s | 0.253 – 0.256 s |

Read the two columns against each other, because that is the evidence. **`user`
barely moves while `real` falls by nearly five times.** The total work is the
same; the wall clock got shorter. That is what real parallelism looks like, and
it is the only way to tell it from a machine that is simply fast.

Scaling saturates at 8. This machine is 10 performance cores and 4 efficiency
cores, so past 8 there is nothing left to give except scheduling overhead.

## Where the numbers come from

Every number in this chapter, and in the rest of this book, was measured on a
**compiled** binary:

```sh
bend pow2_26.bend -o pow2_26     # compile
./pow2_26 --threads 1            # then time the binary, not the interpreter
./pow2_26 --threads 8
```

`bend pow2_26.bend` interprets instead, and the interpreter is sequential: no
call forks, and the wall clock is identical at every thread count. [Getting set
up](setup.md) has the two backends in full; what this chapter needs from them is
one line — **a performance number means nothing unless it came from a compiled
binary.**

That is worth a section of its own because the difference is invisible in the
output. A sequential run looks exactly like a parallel run that does not scale:
the right answer, `user` about equal to `real`, and no speedup at any thread
count.

## The files

| | |
|---|---|
| [`parallel/pow2_26.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/parallel/pow2_26.bend) | 2^26, the table above |
| [`parallel/pow2.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/parallel/pow2.bend) | 2^22 |

Next: [the GPU, and the `!` mark](gpu.md) — where `!` turns out to mean the GPU
rather than more cores, and a fixed cost turns out to decide who wins.
