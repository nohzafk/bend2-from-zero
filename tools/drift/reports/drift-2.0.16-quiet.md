# Drift report — bend 2.0.16 (2.0.16-quiet)

- date: 2026-09-19 10:43 UTC
- machine: Apple M3 Max, 14 cores (10 performance), macOS 27.0
- bend binary: `/Users/randall/.bend/bin/bend` sha256 `da9bc51449f04a65…`
- repo: `/Users/randall/projects/bend2-from-zero` at `bb2d1d9` (clean)
- load average at start/end: 2.35/2.73/2.79 / 1.93/2.46/2.68
- caffeinate running: yes

Verdict is against **manifest.py** (the recorded claim); the `book` column is what the 2.0.5-written book says, for context.

## bench

| check | book (2.0.5) | now | verdict |
|---|---|---|---|
| parallel/pow2_26 @1t | 0.22-0.23 s | settled 0.22s (runs after first: 0.22 / 0.23); first run 0.62s (cold)  | OK |
| parallel/pow2_26 @2t | 0.12-0.13 s | settled 0.13s (runs after first: 0.13 / 0.13) | OK |
| parallel/pow2_26 @4t | 0.07 s | settled 0.07s (runs after first: 0.07 / 0.07) | OK |
| parallel/pow2_26 @8t | 0.04 s | settled 0.05s (runs after first: 0.05 / 0.05) | OK |
| parallel/pow2_26 @14t | 0.04-0.05 s | settled 0.04s (runs after first: 0.04 / 0.04) | OK |
| gpu/gpu_floor | 0.08-0.09 s | settled 0.07s (runs after first: 0.08 / 0.07) | OK |
| gpu/pow2_gpu | 0.09-0.10 s | settled 0.09s (runs after first: 0.09 / 0.09) | OK |
| gpu/gpu_twice | 0.09 s | settled 0.09s (runs after first: 0.10 / 0.09) | OK |
| gpu/mandelbrot cpu @1t | 5.10-5.12 s | settled 5.02s (runs after first: 5.02 / 5.02) | OK |
| gpu/mandelbrot cpu @10t | 0.72 s | settled 0.73s (runs after first: 0.73 / 0.73) | OK |
| gpu/mandelbrot gpu | 0.10-0.12 s | settled 0.10s (runs after first: 0.10 / 0.11) | OK |
| gpu/queens cpu @1t | 6.02-6.19 s | settled 6.32s (runs after first: 6.32 / 6.33) | OK |
| gpu/queens cpu @10t | 0.85 s | settled 0.86s (runs after first: 0.86 / 0.87) | OK |
| gpu/queens gpu | 1.34-1.41 s | settled 1.71s (runs after first: 1.71 / 1.74) | OK |
| life/life_row @1t | 4 / 17 / 70 / 308 ms (64 generations, ns/cell flat) | settled 0.42s (runs after first: 0.42); first run 0.63s (cold)  | OK |
| life/life_par @1t | 1t: 1795 / 2065 / 2025 ms | settled 14.27s (runs after first: 14.27) | OK |
| life/life_par @10t | 10t: 690 / 684 / 1045 ms | settled 10.57s (runs after first: 10.57) | OK |

## bench raw stdout (last run of each)

```
-- parallel/pow2_26 @1t --
67108864
-- parallel/pow2_26 @2t --
67108864
-- parallel/pow2_26 @4t --
67108864
-- parallel/pow2_26 @8t --
67108864
-- parallel/pow2_26 @14t --
67108864
-- gpu/gpu_floor --
4
-- gpu/pow2_gpu --
67108864
-- gpu/gpu_twice --
33554432
67108864
-- gpu/mandelbrot cpu @1t --
3101455856
-- gpu/mandelbrot cpu @10t --
3101455856
-- gpu/mandelbrot gpu --
3101455856
-- gpu/queens cpu @1t --
2063750025
-- gpu/queens cpu @10t --
2063750025
-- gpu/queens gpu --
2063750025
-- life/life_row @1t --
row-window Life, 64 generations -- O(n)?

  32x32  live=5  ms=5

  64x64  live=5  ms=16

128x128  live=5  ms=70

256x256  live=5  ms=313


64x64, 16 generations -- head to head with the naive version

  64x64  live=5  ms=4
-- life/life_par @1t --
64x64, 4 generations

blk=1  (4096 tasks)  live=5  ms=1763

blk=16 ( 256 tasks)  live=5  ms=2023

blk=64 (  64 tasks)  live=5  ms=1996


naive, no fork (d=0, blk=w*h)

  32x32 16gen  live=5  ms=500

  64x64 16gen  live=5  ms=7970
-- life/life_par @10t --
64x64, 4 generations

blk=1  (4096 tasks)  live=5  ms=657

blk=16 ( 256 tasks)  live=5  ms=647

blk=64 (  64 tasks)  live=5  ms=984


naive, no fork (d=0, blk=w*h)

  32x32 16gen  live=5  ms=506

  64x64 16gen  live=5  ms=7755
```

## Annotations

- **gpu/gpu_floor** — .gpu semantics (same design in 2.0.5's comp.ts and in 2.0.16): `bend -o X` writes X.gpu beside X; a launch LOADS it when present (silent), and prints 'compiling the GPU program (missing or stale)' and recompiles only when the file is absent or empty.  A run never writes the kernel back on Metal -- with X.gpu absent, every run notes and recompiles (~0.08 s either way; Metal's OS cache feeds the recompile).  A .gpu from a different program loaded silently and still computed correctly (the kernel source is embedded in the host binary).  The papercut of 2026-09-18 described an X.gpu-less binary, so its 'prints every run' is correct for that setup only.

