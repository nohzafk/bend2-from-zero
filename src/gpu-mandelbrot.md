# When the GPU wins: mandelbrot

`gpu/mandelbrot` renders the Mandelbrot set at 4096² with histogram equalisation.
Its `main.bend` is byte-identical to upstream's benchmark, and it is the mirror
image of the previous chapter: the same balanced fork tree, but the work at the
leaves is uniform, and that turns out to be the whole difference. The code below
is that file, quoted by line number.

## Why the leaves are uniform

The set is drawn by iterating `z ↦ z² + c` a fixed number of times per pixel and
recording when `z` escapes. The obvious implementation breaks out of the loop
when it escapes — and that is a branch, which makes pixels take different
amounts of time, which is the thing that kills the GPU.

So it does not break out. Upstream's own header says it in a line:

> every pixel runs `ITERS` iterations with **no branches** (once escaped, `sel`
> freezes `z` rather than jumping out), so the instruction stream is identical
> for every pixel

The loop that does that is `mit` — one iteration per `match` step, ending when
the counter runs out rather than when the point escapes:

```python
{{#include ../gpu/mandelbrot/main.bend:49:62}}
```

Follow `e2`: once the escape test `|z|² > 1024` has fired, `esc` stays set
forever, because it is `or`-ed into itself on the next iteration. And `e2` never
appears in a `case`, so nothing branches on it. It only decides *values*:

```python
{{#include ../gpu/mandelbrot/main.bend:33:41}}
```

`sel` is a select — a conditional *value*, not a conditional *jump*. `sr` and
`si` are the new or the old `z`, chosen without a jump, and a frozen `z` stops
changing. Every pixel takes the same path through the same instructions; only
the data differs.

The escape count is still correct, because the iterations after the escape are
wasted work — and wasted work costs nothing to a machine built to run many lanes
in lockstep. That is the exact inverse of n-queens. There, the search tree could
not be made uniform. Here, it can be made uniform by *spending more arithmetic*.

## The two passes

The render is not one fork. It is two, plus something in between, and each pass
has a type of its own:

```python
{{#include ../gpu/mandelbrot/main.bend:20:24}}
```

`Hs` is one histogram — eight scalar buckets, one per eighth of the iteration
budget:

```python
{{#include ../gpu/mandelbrot/main.bend:70:73}}
```

1. **Histogram.** Fork 2^18 blocks of 64 pixels; each block sorts its escape
   counts into those 8 buckets and the buckets are merged pairwise up the fork
   tree:

```python
{{#include ../gpu/mandelbrot/main.bend:99:105}}
```

`hfold` is the same depth-`d` fork as `batch` in the previous chapter, and
`hzip` is its `smerge`: one bucket set added to another, pairwise, all the way
up.

2. **The CDF.** A serial pass turning the root histogram into an equalisation
   lookup table. Small, sequential, unavoidable — and worth reading, because it is
   the one piece of this program with no fork in it at all:

```python
{{#include ../gpu/mandelbrot/main.bend:107:119}}
```

3. **Recolour.** Fork again, one leaf per pixel this time, running each pixel
   back through the lookup table and summing by position:

```python
{{#include ../gpu/mandelbrot/main.bend:131:138}}
```

The checksum mixes the lookup table and the recoloured result, so it is sensitive
to both passes. That matters — it means a GPU build that silently skipped the
recolour would not produce the recorded value.

## The numbers

Three runs each, checksum `3101455856` everywhere.

| | real |
|---|---|
| `cpu --threads 1` | 5.103 – 5.116 s |
| `cpu --threads 10` | 0.722 s |
| `gpu` | 0.108 – 0.127 s |

Wall clock says the GPU is about 6× faster than ten cores. That understates it
badly, because roughly 85 ms of every GPU run is the entry cost measured in the
[GPU chapter](gpu.md), and it does not shrink when the work does.

Subtract it and the picture is:

| | |
|---|---|
| GPU work | **~0.03 s** |
| CPU work, 10 threads | 0.722 s |
| ratio | **~20×** |

This is the largest GPU win in the repository, and it is worth being precise
about *why* it is not reported as 20×: because a wall-clock number for a program
that runs once has to include the door. A real renderer loops over many frames or
many scenes and pays it once — at which point this becomes the 20× number.

## Two things to know before timing it yourself

**The first run is slow.** The first measurement of this binary here was 0.226 s,
which settled to 0.108 s on repetition — a factor of two. Every GPU number in
this book is three runs, and the first is discarded in spirit even where it is
printed.

**The stderr line is not an error, and you must not filter it out.**

```
bend: compiling the GPU program (... .gpu is missing or stale)
```

The host binary checks for a kernel and rebuilds it when it cannot find one. If
you `grep -v` that line away while timing, you are timing a different program.
The cost is real and it belongs in the number.

## Sizes

The source records two configurations:

| size | `hd` | `ITERS` | expected checksum |
|---|---|---|---|
| small | `2n` | `7n` | `887240761` |
| big | `18n` | `51n` | `3101455856` |

Both are one call apart:

```python
{{#include ../gpu/mandelbrot/main.bend:159:161}}
```

The two binaries in this directory are the big one. The small one is useful for
checking a rebuild — it finishes quickly and still verifies.

## The files, and how to build them

| | |
|---|---|
| [`gpu/mandelbrot/main.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/gpu/mandelbrot/main.bend) | the source |
| [`gpu/mandelbrot/main.c`](https://github.com/nohzafk/bend2-from-zero/blob/main/gpu/mandelbrot/main.c) | 4,174 lines of generated C, one file for both targets |

```sh
bend main.bend -o gpu            # the GPU path, plus a .gpu Metal kernel
bend main.bend -o main.c
clang -O2 main.c -o cpu -lm      # CPU only
```

A useful sanity check: build the CPU binary yourself and compare. The result here
was 70,696 bytes with the same checksum and the same 5.15 s as the committed
`cpu`, which is a decent sign that the generated C is deterministic and that
nothing about the measurement depends on which clang invocation you used.

---

That closes the performance half of the book. The last part takes the same
machinery — affinity, kinds, the fork — and points it at a different question:
not *how fast*, but [how do you know it is right](laws-1.md), without reading
the code.
