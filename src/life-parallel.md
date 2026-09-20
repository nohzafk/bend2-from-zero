# Life on ten cores

The [previous chapter](life-naive.md) measured the obvious engine and found
the trap: every cell pays eight list walks, each as long as the cell's
position, and the whole engine is quadratic. Before changing anything about
the algorithm, there is an obvious move left. You have read how Bend forks,
and the machine has more than one core. Keep the engine, add cores.

This chapter does that, and it is really about two questions that sound
easier than they are: **what did the cores buy**, and **how do you know**.

You cannot tell by reading it. A parallel let that never gets scheduled and a
parallel let that runs perfectly look identical in the source. You cannot
tell from the wall clock either. A millisecond count answers the question you
asked, and two parts of that question are easy to ask wrong: what went into
the window, and which implementation was running.

## The shape

The naive engine gets parallelised by renaming its step function to `block`
and using it as a **leaf** — one task computes `blk` consecutive cells — then
hanging a balanced binary tree over the leaves:

```python
{{#include ../life/life_par.bend:106:112}}
```

`cells_in(d, blk)` is `2^d × blk`, by the same recursion the tree uses, so
`2^d × blk = w × h` covers the grid: `blk` is a **granularity knob** and
everything else stays fixed. The `a b = ...` line is the fork; `app(a, b)` is
the join.

## The evidence

Here is the honest signature of real parallelism: watch `user` while `real`
falls.

| `--threads` | real | user |
|---|---|---|
| 1 | 5.6 s | 5.6 s |
| 4 | 2.7 s | 8.8 s |
| 10 | 2.3 s | 12.4 s |

**`user` goes up while `real` goes down.** The total work is unchanged — the
same additions, the same comparisons — but it is being spent on more cores at
once, so the wall clock is shorter and the CPU total is larger (the extra is
scheduling overhead). A program that is not parallel shows `user ≈ real` at
every thread count. The [fork-join chapter](parallel.md) showed this signature
on a toy; this is the same read on our own engine.

This is the check to reach for, and it is cheap: `time ./binary --threads 1`
and `time ./binary --threads 10`, then compare the two columns. It asks one
thing of you first — a window that contains the parallel work and nothing
else — and that is the next section.

## What to time

Time only the region you are claiming is parallel. Nothing else belongs in
the window.

`./life_par` is a good test of that habit, because one command runs five
benchmarks and only three of them fork. The two `naive, no fork` cases are
depth-zero — one leaf for the whole grid — so they cannot parallelise at all,
and their own output says so: 7,940 ms at one thread, 7,745 ms at ten.

Both readings below are of the same five benchmarks, and both are correct:

| what was timed | 1 thread | 10 threads | |
|---|---|---|---|
| the whole command | 14.2 s | 10.5 s | **1.35×** |
| the three fork-join cases alone | 5.7 s | 2.3 s | **2.5×** |

That is `/usr/bin/time -p ./life_par --threads 1` against `--threads 10`. The
gap between the two rows is the two serial cases: 8.4 s of the process, and
8.2 s of it at ten threads. A benchmark that measures two things reports
neither, and the fix is not a better benchmark but a narrower one.

So the rest of this chapter measures in that narrow window. `blk=1` on its
own is 2.6× at ten threads; the process it lives in is 1.35×.

## Granularity

With the window narrowed to the fork-join work, here is the knob. 64×64, four
generations, one thread and ten:

| `--threads` | `blk=1` (4096 tasks) | `blk=16` (256) | `blk=64` (64) |
|---|---|---|---|
| 1 | 1,735 ms | 1,958 | 1,936 |
| 4 | 823 | 867 | 1,043 |
| 10 | 676 | **628** | 986 |
| **speedup** | 2.57× | **3.12×** | 1.96× |

At one thread the three settings sit within about 15% of each other. At ten
they spread by more than half a second, and the direction is the opposite of
the usual advice: **fewer, larger tasks win** — `blk=16` beats `blk=1` by
48 ms at ten threads.

The reason is the join. `app` is serial work — concatenating two lists is one
thread's job — and every internal node of the tree is a join. `blk=1` makes a
4096-leaf tree, which means 4,095 joins; `blk=16` makes 255. At ten threads,
each join parks one worker while its partner concatenates, so every join is a
small stretch of the schedule where a core idles. At one thread there are no
partners to park, the joins are just work, and the knob barely matters. The
knob only matters in the regime it was invented for.

This is the guide's second promise doing its work:

> The calls are independent. They run in roughly the same time. […] if one
> call finishes before the other, the speedup will be sub-ideal.

And it leaves a rule worth keeping verbatim:

> **A parallel number is a property of an implementation, not of a language.**
> Record them together or you will attribute the next one to the wrong cause.

This exact tree — `tree_cells`, `block`, `cells_in` — is the one the last
part of this book proves equal to a plain serial scan. The shape you just
measured is the shape that gets proved.

## So: is it actually parallel?

Yes — 3.1× on ten cores, and `user` climbing from 5.6 s to 12.4 s says so
independently of the wall clock. But 3.1× out of 10 is about 31% efficiency,
and both reasons are now visible rather than mysterious. The joins are
serial. And the leaves are unbalanceable: the work behind every cell is a
walk whose length is the cell's position, so "roughly the same time" — the
guide's second promise — is broken in every leaf at once. The cores multiply
what the algorithm hands them, and this algorithm hands them walks of a
thousand different lengths.

There is another road out of the trap, besides cores: make every cell cost
the same, small, constant amount of work, with no walk to a position at all.
That is the next chapter, and it is worth about a factor of 1,600.

## Running it

```sh
bend life_par.bend -o life_par
./life_par --threads 1
./life_par --threads 10
```

The binary also prints the naive no-fork baseline and the row-window
head-to-head, so the whole comparison is reproducible from one command.

Next: the same game in O(n).
