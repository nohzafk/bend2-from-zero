# gpu — `!` and Metal

Putting `!` after a function name hands that call to the GPU:

```python
pow2!(26n)     # GPU
pow2(26n)      # CPU, still multicore parallel
```

## What the build produces

`bend file.bend -o name` emits a `name.gpu` next to the native binary:

```
$ file gpu/pow2_gpu.gpu
... MetalLib executable (MacOS) ... applegpu_g15s
```

That is the **Metal kernel**; `name` itself is the host program, and the two run
together.

The compilation path is **Bend → C → clang**. You can read the generated C directly:
`mandelbrot/main.c` is 4,174 lines, produced from a 6,427-byte `main.bend`. It also
carries `#ifdef __METAL_VERSION__`, so **one C file builds both the CPU and the Metal
version**.

## ⚠️ Every `!` program pays an entry fee of about 85 ms

**This is the most important number in this directory, and it is why our first
measurement of it was wrong.**

To measure the floor, write a `!` program that does almost nothing: the same fork-join
tree, but `pow2!(2n)`, whose result is 4.

```
gpu_floor   pow2!(2n)      = 4          0.08 – 0.09 s
pow2_gpu    pow2!(26n) = 67108864       0.09 – 0.10 s
```

**Sixty-seven million additions cost the same as four.** So the ~85 ms is essentially
all entry, none of it work.

A *second* call in the same process costs only a few milliseconds more:

```
gpu_twice   pow2!(25n) + pow2!(26n)     0.09 s
```

So it is a **per-process** fixed cost, not a per-call tax.

And it is **not kernel compilation**, even though the stderr line
`compiling the GPU program (...)` invites that reading: `gpu_floor`'s kernel is tiny
and costs the same as mandelbrot's large one. What is being paid for is the Metal
runtime itself — device, command queue, pipeline state.

(`gpu_floor` and `gpu_twice` are those two probes; their sources live in this directory.)

## Three workloads: the raw numbers

All native builds, three runs per configuration. `cpu` uses all cores by default;
`--threads 1` is the single-core baseline.

| Workload | CPU 1 thread | CPU 10 threads | GPU | Checksum |
|---|---|---|---|---|
| `pow2` 2^26 additions | 0.22 – 0.23 s | 0.04 s (8 threads) | 0.09 – 0.10 s | 67108864 |
| `mandelbrot` 4096² × 51 | 5.10 – 5.12 s | 0.72 s | 0.10 – 0.12 s | 3101455856 |
| `queens` N=17 search | 6.02 – 6.19 s | 0.85 s | 1.34 – 1.41 s | 2063750025 |

Every checksum matches the expected value recorded in the source comments, so none of
this is "it ran something, we think".

## Subtract the entry fee and every conclusion changes shape

| Workload | GPU total | minus 85 ms | CPU 10 threads | Who actually wins |
|---|---|---|---|---|
| `pow2` | 0.09 s | **below the noise** | 0.04 s | the arithmetic is nearly free; all you are paying is the door |
| `mandelbrot` | 0.11 s | **~0.03 s** | 0.72 s | **the GPU, by about 20×** |
| `queens` | 1.38 s | **~1.29 s** | 0.85 s | the CPU, and not narrowly |

- **`pow2` is not "the GPU is slow at this".** 2^26 additions on the GPU are too fast
  to measure. What makes `pow2!(26n)` lose end to end is that 85 ms door.
  > **Correction (2026-09-18):** this README previously said the overhead was "all in
  > fork/join scheduling". **That was wrong.** Fork-join is precisely what the CPU is
  > good at, and `gpu_floor` has no fork-join work left in it at all — yet it still
  > pays 85 ms.
- **mandelbrot's win is much larger than it looks.** The often-quoted "7.6×" both
  understates the hardware and overstates the price. The honest pair of numbers is
  ~30 ms of GPU work against 722 ms of 10-core CPU work, plus a fixed door that a real
  application pays once.
- **queens genuinely loses.** ~1.29 s of GPU work against 0.855 s, matching the
  guide's own claim about divergent workloads.

In one line: **a GPU wall-clock number is not a statement about the GPU, it is a
statement about "the GPU plus a fixed cost that does not shrink with the work". To
find out which one you are measuring, write a program that does nothing and measure
that.**

## Things to watch when measuring

- The host binary **recompiles or reloads the Metal kernel on every run** and prints
  `bend: compiling the GPU program (... .gpu is missing or stale)` to stderr. That is
  not an error, but do not `grep` it away — the cost it reports is already counted in
  the GPU numbers above.
- **The first GPU run is noticeably slower.** The first mandelbrot measurement was
  0.226 s; repeats settled at 0.108 s. Run everything three times before recording it.
- `gpu/mandelbrot/gpu.gpu` does not currently exist on disk (the `gpu` binary rebuilds
  the kernel on every run and never writes it back). Re-running
  `bend main.bend -o gpu` regenerates it.

## Files

| Path | What |
|---|---|
| `gpu_floor.bend` / `gpu_twice.bend` | **the two probes that measure the entry fee** |
| `pow2_gpu.bend` + `pow2_gpu` + `pow2_gpu.gpu` | the smallest `!` example |
| `mandelbrot/` | a 4096² escape-time render; representative uniform numeric work |
| `queens/` | an exhaustive N-queens search; representative divergent work |

The `main.bend` files in `mandelbrot/` and `queens/` are **byte-identical** copies of
the upstream `bend/bench/runtime/{mandelbrot,queens}/main.bend`.

## How to rebuild the two binaries

The CLI has **no** `--gpu` switch (`bend --help` offers only `-o` / `--checkup` /
`--publish`). The two builds are separate:

```sh
# GPU build: the default, produces the host program and the Metal kernel together
bend main.bend -o gpu            # → gpu + gpu.gpu

# CPU build: have bend emit C, then compile it yourself (this does not link Metal)
bend main.bend -o main.c
clang -O2 main.c -o cpu -lm
```

## Running

```sh
bend gpu_floor.bend -o gpu_floor && ./gpu_floor    # the entry fee: ~85 ms, result is 4
./mandelbrot/gpu                                   # 0.11 s
./queens/cpu --threads 10                          # 0.85 s
```

Book: chapters 12–14.
