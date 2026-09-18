# parallel — fork-join on the CPU

Bend's parallelism primitive is an ordinary assignment:

```python
a b = f(x) g(y)      # two calls, each its own task, then a join
```

It promises the compiler two things:

1. **The two calls are independent.**
2. **They take roughly the same time.**

The first is free in Bend — the language is pure and affine. The second is your job:
the scheduler is a contention-free binary fork-join machine, each task goes to one
core and is never moved afterwards, so an uneven load shows up directly as missing
speedup.

## Why you need neither locks nor an argument

Because of affinity. A value has exactly one holder at a time, so splitting
`f(x) g(y)` across two cores **cannot**, at the type level, have both sides touch the
same thing. This is the second payoff of the machinery in `../affinity/`.

Note that `!` is not the switch that turns parallelism on. Under a native build,
`pow2(p) pow2(p)` forks across cores on its own. `!` only additionally hands that
call to the GPU (see `../gpu/`).

## The smallest example

```python
def pow2(+n: Nat) -> U32:
  match n:
    case 0n:    1
    case 1n+p:
      a b = pow2(p) pow2(p)     # unfolds into a binary tree; every inner node is a fork
      (a + b : U32)
```

## Thread scaling

`pow2_26` = 2^26 = 67,108,864 additions, native build, `--threads N`, three runs per
configuration (re-measured 2026-09-18):

| threads | real | user |
|---|---|---|
| 1 | 0.22 – 0.23 s | 0.20 s |
| 2 | 0.12 – 0.13 s | 0.21 s |
| 4 | 0.07 s | 0.22 s |
| 8 | **0.04 s** | 0.23 s |
| 14 | 0.04 – 0.05 s | 0.25 s |

At 1 thread `real` and `user` are the same, as they must be. At 8, `real` has dropped
to **1/5.8** while `user` has *risen* from 0.20 to 0.23 — total work slightly up
(fork-join overhead), wall clock down nearly sixfold. That combination is the evidence
that this is real parallelism and not a measurement artefact.

It saturates at 8. This machine is 10 performance cores plus 4 efficiency cores, so
past 10 threads the scheduler is only adding contention.

> An earlier note here said "0.048 s at 8 threads, about 1/4.8". Re-measuring gave
> 0.040 s and 1/5.8 on three consecutive runs. **A parallel speedup is a number that
> varies** — record it together with the state of the machine, and re-check it before
> quoting it.

For contrast, see `../gpu/`: the same tree handed to the GPU as `pow2!(26n)` takes
0.089 – 0.096 s. That looks like "only a little slower", but about 85 ms of it is a
**fixed entry fee** every `!` program pays. See `../gpu/README.md`.

**A trap we fell into:** the first measurement of this table was taken under the
interpreter, where `real` did not move with the thread count at all. The reason is
stated at the top of the repository README — **the JS backend ignores parallelism by
design and runs everything serially.** You can only measure parallelism under a
native build.

## Files

| File | What |
|---|---|
| `pow2.bend` / `pow2` | 2^22 |
| `pow2_26.bend` / `pow2_26` | 2^26 — this is what the table above used |
| `parsum` / `parsum.gpu` | build output of the upstream demo `bend/demos/pure_par_sum/` |

The source for `parsum` is not in this directory (it is upstream, in
`bend/demos/pure_par_sum/`). It is worth a look: that demo carries a `LAWS.bend`
claiming **the parallel fork/join sum tree equals the serial loop**, with a
`PROOF.bend` proving it by induction. Its checker finishes in 0.087 s — the direct
result of Bend trading "almost no type inference" for "the checker never has to
search".

Compiled binaries sit next to their sources rather than in a separate `build/`, to
match `../life/`.

## Running

```sh
bend pow2_26.bend -o pow2_26
./pow2_26 --threads 1
./pow2_26 --threads 8
```

Book: chapter 11.
