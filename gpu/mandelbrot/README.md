# mandelbrot

A 4096×4096 escape-time render of the Mandelbrot set, with histogram equalisation.
**The representative uniform numeric workload:** every pixel runs the same arithmetic
for the same number of rounds.

- `main.bend` — **byte-identical** to upstream `bend/bench/runtime/mandelbrot/main.bend`
- `main.c` — the C `bend` generates (4,174 lines); one file builds both the CPU and the Metal version
- `cpu` / `gpu` — the two binaries

## Why the GPU wins on this workload

The source comment says it plainly: every pixel runs `ITERS` **branch-free** iterations
(once a point escapes, `z` is frozen via `sel` rather than jumped out of), so **the
instruction stream is identical for every pixel**. That is exactly the shape a GPU wants.

Two fork passes: the first spreads 2^18 blocks of 64 pixels, bins escape times into
8 buckets and merges the histograms pairwise; a CDF pass turns the root histogram into
an equalisation lookup table; the second pass gives each pixel one leaf, recolouring
through the table and summing position-weighted results. The checksum mixes the lookup
table with the recoloured output.

## Numbers

Three runs per configuration, once settled:

| | real |
|---|---|
| `cpu --threads 1` | 5.10 – 5.12 s |
| `cpu --threads 10` | 0.72 s |
| **`gpu`** | **0.10 – 0.12 s** |

Checksum `3101455856`, matching the value recorded in the source comment (which says it
was verified on a cluster in all three modes: seq / par / metal).

**The naive ratio is 7.6× over the 10-core CPU — and that is the wrong number.** Every
`!` program pays a fixed entry fee of about 85 ms before it computes anything (see
`../README.md`). Subtract it and the comparison is ~30 ms of GPU work against 722 ms of
10-core CPU work: **about 20×**, not 7.6×.

⚠️ The first GPU run is slower (the first measurement here was 0.226 s, settling to
0.108 s on repeats), and the host binary recompiles or reloads the Metal kernel on every
run and prints a line to stderr. Do not read that line as an error, and never record a
number from a single run.

## Size knobs

Two sizes are recorded at the top of the source (`hd` = half-width/depth parameter,
`ITERS` = iteration count):

| Size | `hd` | `ITERS` | Expected checksum |
|---|---|---|---|
| small | `2n` | `7n` | 887240761 |
| big | `18n` | `51n` | 3101455856 ← the two binaries here were built with this one |

## Running

```sh
./cpu --threads 10       # 0.72 s
./gpu                    # 0.11 s
```

## How to rebuild the two binaries

The CLI has **no** `--gpu` switch (`bend --help` offers only `-o` / `--checkup` /
`--publish`). The two builds are separate:

```sh
# GPU build: the default; produces the host program and the Metal kernel together
bend main.bend -o gpu            # → gpu + gpu.gpu

# CPU build: have bend emit C, then compile it yourself (this does not link Metal)
bend main.bend -o main.c
clang -O2 main.c -o cpu -lm
```

The second is where this directory's `main.c` comes from, and where the `cpu` binary
comes from — measured at 70,696 bytes, with checksum and timings matching `cpu`
(3101455856 / 5.15 s).

Book: chapter 13.
