# Is it actually parallel?

The previous two chapters established that the algorithm matters more than the
cores. This one is about the cores, and about a question that sounds trivial and
is not: **how do you know a program is running in parallel?**

You cannot tell by reading it. A parallel let that never gets scheduled and a
parallel let that runs perfectly look identical in the source. You cannot tell
from the wall clock either, at least not reliably, and getting this wrong is easy
enough that this chapter's author did it twice.

## The shape

The naive engine gets parallelised by renaming its step function to `block` and
using it as a **leaf** — one task computes `blk` consecutive cells — then hanging
a balanced binary tree over the leaves:

```python
def tree_cells(+d: Nat, +g: List<&2, Nat>, +w: Nat, +h: Nat, +k: Nat, +blk: Nat) -> Tree(d):
  match d:
    case 0n:
      block(g, w, h, blk, k)
    case 1n+p:
      a b = tree_cells(p, g, w, h, k, blk) tree_cells(p, g, w, h, k + cells_in(p, blk), blk)
      app(a, b)
```

`2^d × blk = w × h` covers the grid, so `blk` is a **granularity knob** and
everything else stays fixed. The `a b = ...` line is the fork; `app` is the join.

## The evidence

Here is the honest signature of real parallelism: watch `user` while `real` falls.

| `--threads` | real | user |
|---|---|---|
| 1 | 5.6 s | 5.6 s |
| 4 | 2.7 s | 8.8 s |
| 10 | 2.3 s | 12.4 s |

**`user` goes up while `real` goes down.** The total work is unchanged — the same
additions, the same comparisons — but it is being spent on more cores at once, so
the wall clock is shorter and the CPU total is larger (the extra is scheduling
overhead). A program that is not parallel shows `user ≈ real` at every thread
count.

This is the check to reach for, and it is cheap: `time ./binary --threads 1` and
`time ./binary --threads 10`, then compare the two columns. Wall clock alone will
lie to you, as the next section shows.

## ❌ The trap: you can measure the wrong thing

The first version of this benchmark ran the **serial** and **parallel** engines in
the same process, back to back, so the reader could compare them. At 32×32 it
reported a speedup of about 2.2×, and the parallel engine looked disappointing.

It was not. Look at what the wall clock was made of:

| threads | parallel section | whole process |
|---|---|---|
| 1 | 493 ms | 1.012 s |
| 4 | 211 ms | 0.731 s |

The parallel section went from 493 ms to 211 ms — 2.3× on four threads, which is
unremarkable but real. The **whole process** barely moved, because the other half
of it was a serial baseline that does not parallelise at all and was being
included in every reading.

This is Amdahl's law doing what it does, and it is easy to walk into: a benchmark
that measures two things reports neither. The fix is not a better benchmark, it is
a narrower one — time only the region that is supposed to be parallel.

## Granularity

With the benchmark narrowed, here is the knob. 64×64, four generations, one
thread and ten:

| `--threads` | `blk=1` (4096 tasks) | `blk=16` (256) | `blk=64` (64) |
|---|---|---|---|
| 1 | 1,735 ms | 1,958 | 1,936 |
| 4 | 823 | 867 | 1,043 |
| 10 | 676 | **628** | 986 |
| **speedup** | 2.57× | **3.12×** | 1.96× |

Coarser leaves are strictly worse here, which is the wrong way round from the
usual advice — usually you coarsen tasks to amortise fork overhead. But note that
`blk=64` is already slower **at one thread**, where there is no fork overhead to
amortise. So this is not a scheduling effect at all; the coarse-leaf
implementation is doing more work. That is a fact about this code, and it took a
second measurement to find the cause.

## The refactor that flipped it

The same function had to be rewritten so that its correctness could be
**proved** — that is the last part of this book. The change was to merge the
tree-building and the flattening into one function, so that the join happens in
place instead of in a second pass.

Both versions, measured in the same session, same machine:

| | `blk=1` | `blk=16` | `blk=64` |
|---|---|---|---|
| old (`build` + `flatten`), 1 thread | 2,081 | 2,388 | 2,512 |
| old, 10 threads | 503 (**4.14×**) | 651 (3.67×) | 1,004 (2.50×) |
| new (`tree_cells`), 1 thread | **1,735** | 1,958 | 1,936 |
| new, 10 threads | 676 (**2.57×**) | **628** (3.12×) | 986 (1.96×) |

Two things moved, in opposite directions.

**Serial got about 18% faster.** `flatten` had to walk the whole tree a second
time to collect the results; the new version appends at the join and never
revisits.

**Parallel got worse, and the best granularity flipped** from `blk=1` to
`blk=16`. The reason is visible once you look for it: `app` is *serial* work —
concatenating two lists is one thread's job — and the refactor moved it **inside**
the fork-join region. So at every join, one worker is concatenating while its
partner sits idle. The more joins there are, the more idle time; hence `blk=1`
degrading and the optimum moving to fewer, larger joins.

This is exactly the guide's second promise doing its work:

> The calls are independent. They run in roughly the same time. […] if one call
> finishes before the other, the speedup will be sub-ideal.

An earlier version of this repository's notes recorded "finer granularity is
faster" as a finding about the scheduler. **It is not.** It was true of one
implementation and stopped being true when that implementation changed. The rule
that survives is narrower and more useful:

> **A parallel number is a property of an implementation, not of a language.**
> Record them together or you will attribute the next one to the wrong cause.

## So: is it actually parallel?

Yes — 3.1× on ten cores, and `user` climbing from 5.6 s to 12.4 s says so
independently of the wall clock. But 3.1× out of 10 is about 31% efficiency, and
the reason is now visible rather than mysterious: the joins are serial, and the
naive engine's inner loop — eight list walks per cell — is not a shape the
scheduler can balance, because every walk is a different length.

The row-window engine from the previous chapter has none of those properties. It
also does not need the cores.

## Running it

```sh
bend life_par.bend -o life_par
./life_par --threads 1
./life_par --threads 10
```

The binary also prints the naive no-fork baseline and the row-window head-to-head,
so the whole comparison is reproducible from one command.

Next: [making it move](life-anim.md).
