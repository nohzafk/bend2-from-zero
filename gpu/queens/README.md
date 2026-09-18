# queens

A parallel exhaustive backtracking search for N queens, N = 17.
**The representative divergent workload:** the search tree is pruned early, and
different branches differ wildly in how much work they hold.

- `main.bend` — **byte-identical** to upstream `bend/bench/runtime/queens/main.bend`
- `main.c` — the C `bend` generates (3,866 lines)
- `cpu` / `gpu` — the two binaries

## Why the GPU loses on this workload

The first four queens are placed up front, and `batch` forks the flat `(c0,c1,c2,c3)`
prefix index space `0..2^d` into a balanced tree; each leaf shuffles its own index with
an odd multiplier, decodes the four-column tuple, and — if it is legal — runs the
classic bitmask backtracker over the remaining N−4 rows.

The problem is that **how long a leaf runs is completely unpredictable**. A
well-pruned branch returns almost immediately; a badly-pruned one goes deep. A GPU
needs every lane doing the same thing, and this is precisely not that. The CPU's
out-of-order execution and caches cope with the irregularity instead.

## Numbers

Three runs per configuration, once settled:

| | real |
|---|---|
| `cpu --threads 1` | 6.02 – 6.19 s |
| `cpu --threads 10` | **0.85 s** |
| `gpu` | 1.34 – 1.41 s |

Checksum `2063750025` (= `(sols * 2654435761) ^ nodes`), identical across both binaries.

**The GPU is 1.6× slower than the 10-core CPU.** That agrees with the guide:

> divergent work like n-queens stays faster on the CPU.

Unlike `pow2` (where the GPU was really just paying its entry fee), this is a real
loss, and subtracting the ~85 ms door does not change it: ~1.29 s of GPU work against
0.855 s of CPU work. See `../README.md`.

## What is worth reading in this file

The comments at the top of the source record a few Bend-level workarounds that are
unavoidable when writing a search like this:

- `match` can only scrutinise a **parameter**, so every boolean a branch needs is
  computed by the **caller** and passed in as an argument
- a sub-call's `Stats` result **rides in on the sibling call's `acc` parameter**,
  which avoids destructuring a call result in place
- `solve`'s recursion is not structural (the candidate bitmask is not "structure" as
  far as the checker is concerned), so every self-call carries a `Nat` fuel, and
  termination is proved by `match f` and recursing on `g`

These three are exactly the restrictions from `../arrays/` and `../../affinity/`
showing up inside a real program.

## Size knobs

`main` hardcodes `run!(17n, size(), limit())`, i.e. N = 17 and `limit = 11730`. The
prefix mask is `2^d - 1` where `d` is the first argument (17 here), so lowering `d`
shrinks the prefix space — upstream's hardcoded `131071` (d = 17) is parameterised here.

## Running

```sh
./cpu --threads 10       # 0.85 s
./gpu                    # 1.36 s
```

## How to rebuild the two binaries

The CLI has no `--gpu` switch; the two builds are separate:

```sh
bend main.bend -o gpu            # → gpu + gpu.gpu (the Metal kernel)
bend main.bend -o main.c         # emit C
clang -O2 main.c -o cpu -lm      # CPU only, does not link Metal
```

Book: chapter 14.
