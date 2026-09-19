# The GPU, and the `!` mark

Putting `!` after a function name hands that call — and every parallel call
inside it — to the GPU:

```python
pow2!(26n)     # the GPU
pow2(26n)      # the CPU, still multi-core
```

That is the entire syntax. This chapter is about what it costs, and the cost is
not where you would expect.

## What a `!` call builds

`bend file.bend -o file` writes two things:

```
file        the host program
file.gpu    a MetalLib kernel
```

The host binary loads the kernel and drives it. The compilation path is
**Bend → C → clang**, and the interesting part is that it is *one* C program:
`gpu/mandelbrot/main.c` is 4,174 lines generated from a 6,427-byte `.bend`, and it
contains `#ifdef __METAL_VERSION__`, so the same source builds both the CPU
binary and the Metal kernel.

You will see this line on stderr whenever the kernel is missing or out of date:

```
bend: compiling the GPU program (... .gpu is missing or stale)
```

It is not an error, and it is not free.

## The numbers, which are not what they look like

Three workloads, native-compiled, three runs each. The checksums all match the
values recorded in the sources, so this is the same computation on two pieces of
hardware and not a mistake in a loop bound.

| workload | CPU 1 thread | CPU 10 threads | GPU |
|---|---|---|---|
| `pow2` 2^26 additions | 0.226 s | 0.049 s (8 threads) | 0.089 – 0.096 s |
| `mandelbrot` 4096² × 51 | 5.11 s | 0.722 s | 0.108 – 0.127 s |
| `queens` N=17 search | 6.09 s | 0.855 s | 1.338 – 1.420 s |

Read at face value: the GPU wins at mandelbrot by about 6×, loses at pow2 by
about 2×, and loses at queens by about 1.6×. That is the story this repository
recorded the first time round, and it is the story the guide's one sentence
predicts:

> The GPU shines on uniform numeric work like mandelbrot or nbody; divergent
> work like n-queens stays faster on the CPU.

**But face value is wrong, and here is how it was caught.**

## The entry cost

Every GPU run takes about 85 ms before it does anything. That was not obvious;
it had to be measured, by writing a `!` program that computes almost nothing —
the same fork-join tree as `pow2`, asked for `pow2!(2n)`, which is 4.

```python
{{#include ../gpu/gpu_floor.bend}}
```

```
gpu_floor   pow2!(2n)          = 4        82 – 91 ms
pow2_gpu    pow2!(26n)   = 67108864       89 – 96 ms
```

**Sixty-seven million additions cost about the same as four.** So essentially all
of that time is entry, not work. And two `!` calls in one process cost about the
same as one:

```
gpu_twice   pow2!(25n) + pow2!(26n)       97 – 114 ms
```

So it is a per-process cost, paid once — not a per-call tax.

It is also not the kernel compilation, which is what the stderr line suggests.
`gpu_floor`'s kernel is trivial and it costs the same as mandelbrot's, which is
much larger. What you are paying for is the Metal runtime: device, command queue,
pipeline state.

## What the table says once you subtract it

Take ~85 ms off every GPU number:

| workload | GPU total | minus entry | CPU 10 threads | who actually wins |
|---|---|---|---|---|
| `pow2` | 0.093 s | **below the noise** | 0.049 s | the arithmetic is free; you are only paying to enter |
| `mandelbrot` | 0.118 s | **~0.03 s** | 0.722 s | GPU, by roughly 20× |
| `queens` | 1.38 s | **~1.29 s** | 0.855 s | CPU, and it is not close |

Every conclusion changes shape:

- **`pow2` is not a case of the GPU losing at arithmetic.** The GPU does 2^26
  additions in less time than the measurement can resolve. What makes
  `pow2!(26n)` slower end-to-end is the 85 ms door. The earlier note in this
  repository — that the overhead is all in *fork-join scheduling* — was wrong,
  and `gpu_floor` is what disproves it: fork-join is exactly what the CPU does
  well, and a program with no fork-join left in it still pays the 85 ms.
- **`mandelbrot`'s win is far larger than it looks.** The often-quoted "7.6×"
  understates the hardware and overstates the price. The honest pair of numbers
  is: ~30 ms of GPU work against 722 ms of 10-core CPU work, plus a fixed door
  charge that a real application pays once.
- **`queens` genuinely loses.** Its GPU work is about 1.29 s against 0.855 s on
  ten cores. This is the one place where the guide's divergence sentence is
  doing real work rather than being a truism.

## The one-line lesson

A wall-clock number for a GPU path is not a statement about the GPU. It is a
statement about the GPU plus a fixed cost that does not shrink when the work
does. To find out which of the two you are measuring, **write the program that
does nothing and time that.**

## Building either target

There is no `--gpu` flag. The two paths are separate:

```sh
# GPU: the default build, produces both the host program and the kernel
bend main.bend -o gpu            # -> gpu and gpu.gpu

# CPU only: let bend emit C, then compile it yourself so nothing links Metal
bend main.bend -o main.c
clang -O2 main.c -o cpu -lm
```

## The files

| | |
|---|---|
| [`gpu/gpu_floor.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/gpu/gpu_floor.bend) | one `!` call that does nothing — the entry cost |
| [`gpu/gpu_twice.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/gpu/gpu_twice.bend) | two calls, to show the cost is per process |
| [`gpu/pow2_gpu.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/gpu/pow2_gpu.bend) | the smallest `!` example |

Next: the two workloads, one at a time — [why the GPU loses at
n-queens](gpu-queens.md), and [why it wins at mandelbrot](gpu-mandelbrot.md).
