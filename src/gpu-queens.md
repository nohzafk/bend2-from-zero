# When the GPU loses: n-queens

`gpu/queens` is N-queens by parallel exhaustive backtracking, N = 17, ported
verbatim from upstream. Its `main.bend` is byte-identical to
`bend/bench/runtime/queens/main.bend`, and its comments are unusually good, which
is why this chapter can quote the source rather than guess at it.

## The shape of the work

Rows 0–3 are placed up front. `batch` forks the flat
`(c0, c1, c2, c3)` prefix index space `0..2^d` into a balanced tree — a perfectly
uniform fork, exactly the shape the previous chapter said the scheduler likes.
Each leaf then decodes its own column quadruple and runs the classic bitmask
backtracker over the remaining 13 rows.

And that second half is where the uniformity ends:

> the classic bitmask backtracker: descend on the child candidate word (the
> natural non-tail call), then tail-loop on the sibling set

Branches that get pruned early return almost immediately. Branches that do not
go deep. Nobody can know in advance which is which, because knowing is the
search.

> q: Why is this bad on a GPU, when a balanced fork tree is good?
>
> Because the fork is only the *entry* to the work, not the work. The GPU issues
> one instruction across many lanes at once, so lanes doing different things
> serialize — which is exactly what upstream means by *divergent work*. A CPU
> core is built for this: it predicts, reorders, and caches its way through
> irregular control flow. The GPU has no such machinery, because it was designed
> to never need it.

## The numbers

Three runs each, checksum `2063750025` in every configuration — the same
computation on both devices.

| | real |
|---|---|
| `cpu --threads 1` | 6.058 – 6.112 s |
| `cpu --threads 10` | 0.854 – 0.859 s |
| `gpu` | 1.338 – 1.420 s |

Subtracting the ~85 ms entry cost from the [previous chapter](gpu.md), the GPU
spends about **1.29 s** on the search itself against **0.855 s** on ten cores.

**The GPU is genuinely slower here**, by a factor of about 1.5, and unlike the
`pow2` result this is not an artefact of the door charge. It is the one workload
in this repository where the guide's sentence —

> divergent work like n-queens stays faster on the CPU

— is doing real work rather than being a truism.

Note also what eleven cores do for the *CPU* side: 6.09 s down to 0.855 s is a
7.1× speedup on 10 cores. A branchy search is what fork-join is for.

## What this program had to do to be writable at all

The source's header comment documents three Bend-level workarounds, and all three
are consequences of the chapters before this one. This is the best place in the
book to see those limits operating on real code rather than on a probe.

**Every decision boolean is computed by the caller.**

> a match scrutinizes only a parameter, so every decision bool is computed by the
> CALLER and passed as an argument: `solve` receives `z = is_zero(cand)` and
> `e = is_eq(nc, full)` with the peeled words, and each self-call site
> precomputes the next level's words

This is the arrays chapter's rule — *a match cannot scrutinize a computed value*
— showing up as a calling convention. Note the cost: the arguments are threaded
one level ahead of where they are used, so the code reads inside-out.

**No call result is ever destructured in place.**

> the child's `Stats` result rides into the sibling call as the acc argument, so
> no call result is ever destructured in place

The same rule, from the other side. `solve` wants to add up `Stats{sols, nodes}`
from a child call and a sibling call. Taking the child's result apart to read its
fields is exactly what Bend refuses, so the accumulation is rearranged so that
each result arrives as a parameter instead.

**The recursion rides on a fuel argument.**

> `solve` is ONE def and its recursion is structural: the shrinking candidate
> word is not a structure the checker can see, so a Nat fuel rides ahead of every
> self-call (`match f`, recurse on its pred `g`)

The numbers chapter's rule. The search *does* terminate, but it does not shrink a
structural argument — a bitmask is not a structure the termination checker can
follow. So `solve` carries a `Nat` that the checker can watch go down, and the
comment goes to the trouble of proving the fuel is never exhausted (the initial
call seeds `n²`, which exceeds the true frame bound `(n-3)(n-2)+1` for every
`n ≥ 5`). **The fuel is not there for the algorithm. It is there for the type
checker** — and the cost is a parameter that exists only to be decremented.

Three different chapters' rules, in one real program, each written down by
whoever ported it because they had to.

## Sizes

`main` calls `run!(17n, size(), limit())` — N = 17, `limit = 11730`. The prefix
mask is `2^d - 1` where `d` is the first argument, so lowering `d` shrinks the
prefix space. Upstream hard-codes `131071`; here it is threaded through `batch`,
which is what makes the small configuration (`d = 10, n = 5, limit = 625`,
expected checksum `774553824`) reachable.

## The files, and how to build them

| | |
|---|---|
| [`gpu/queens/main.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/gpu/queens/main.bend) | the source, comments included |
| [`gpu/queens/main.c`](https://github.com/nohzafk/bend2-from-zero/blob/main/gpu/queens/main.c) | 3,866 lines of generated C |

```sh
bend main.bend -o gpu            # -> gpu and gpu.gpu
bend main.bend -o main.c
clang -O2 main.c -o cpu -lm      # CPU only, no Metal linked
```

Next: [the workload where the GPU wins](gpu-mandelbrot.md).
