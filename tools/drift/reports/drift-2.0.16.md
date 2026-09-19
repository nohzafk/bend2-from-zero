# Drift report — bend 2.0.16 (2.0.16)

- date: 2026-09-19 10:23 UTC
- machine: Apple M3 Max, 14 cores (10 performance), macOS 27.0
- bend binary: `/Users/randall/.bend/bin/bend` sha256 `da9bc51449f04a65…`
- repo: `/Users/randall/projects/bend2-from-zero` at `9faee16` (dirty: 6 files)
- load average at start/end: 2.82/2.81/2.79 / 3.74/3.17/2.93
- caffeinate running: yes

Verdict is against **manifest.py** (the recorded claim); the `book` column is what the 2.0.5-written book says, for context.

## probes-bad

| check | book (2.0.5) | now | verdict |
|---|---|---|---|
| basics/hello_bad | a declared datatype (unknown: IO) | `Error:` | OK |
| basics/hello_arg | expected : String / observed : U32 | `Error:` | OK |
| basics/term_bad | expected : a decreasing self-call / observed : loop | `Error:` | OK |
| basics/term_order | expected : a decreasing self-call / observed : evolve | `Error:` | OK |
| affinity/affine_bad | expected : x / observed : x (consumed more than once) | `Error:` | OK |
| affinity/t9_listonly | expected : xs / observed : xs (consumed more than once) | `Error:` | OK |
| affinity/t4_arrplus | expected : Data / observed : Type | `Error:` | OK |
| affinity/t5_closure | expected : f / observed : f (consumed more than once) | `Error:` | OK |
| affinity/t6_closureplus | expected : Data / observed : Type (same error as the array) | `Error:` | OK |
| affinity/t11_templatemiss | expected : -f / observed : f (consumed more than once) | `Error:` | OK |
| affinity/t3_arr | fails on purpose (error not quoted in the affinity README) | `Error:` | OK |
| arrays/exp_arr | expected : a term / observed : ':' | `Error:` | OK |
| arrays/exp_arr2 | a match cannot scrutinize a computed value: give it its own def | `Error:` | OK |
| arrays/a_fail | a match cannot scrutinize a local binder: give it its own def | `Error:` | OK |
| arrays/d_write | expected : Sigma<&1, &1, Array<U32>, _ => U32> / observed : Array<U32> | `Error:` | OK |

## probes-ok

| check | book (2.0.5) | now | verdict |
|---|---|---|---|
| basics/hello | hello, bend 2 | `hello, bend 2` | OK |
| basics/exp_str | a <newline> b<TAB>tab | `a` | OK |
| basics/exp_mod | 1n (9 mod 4) | `1n` | OK |
| basics/exp_list | 2 | `2` | OK |
| basics/pat_bad | prints 1 -- it does not (deceptive on purpose) | `1` | OK |
| basics/esc_bad | bytes 00 33 33 (NUL + literal '33') -- not ESC | `\033` | OK |
| affinity/t1_drop | 7 -- unused is fine, affine != linear | `7` | OK |
| affinity/t2_plus | 6 | `6` | OK |
| affinity/t7_paths | 11 -- counted per path, not per occurrence | `11` | OK |
| affinity/t8_listplus | 6n | `6n` | OK |
| affinity/t10_template | 42 | `42` | OK |
| arrays/b_ok | 43 | `43` | OK |
| arrays/c_base | 42 | `42` | OK |
| arrays/e_post1 | ([0,0,0,0,0,42,0,0], 42) | `([0, 0, 0, 0, 0, 42, 0, 0], 42)` | OK |
| arrays/f_post3 | 42 | `42` | OK |
| parallel/pow2 | 2^22 (README only) | `4194304` | OK |
| life/life | 8x8 teaching version, prints the pattern every generation | `generation 0` | OK |

## proofs

| check | book (2.0.5) | now | verdict |
|---|---|---|---|
| life/LIFE_PAR_PROOF | All terms check. (0.10 s) | `All terms check.` | OK |
| life/LIFE_ANIM_PROOF | All terms check. (0.09 s) | `All terms check.` | OK |
| life/LIFE_PAR_LAWS | open claim; running it alone is '1 TODO found' | `Error: 1 TODO found.` | OK |
| life/LIFE_ANIM_LAWS | open claim; running it alone is '1 TODO found' | `Error: 1 TODO found.` | OK |

## hub

| check | book (2.0.5) | now | verdict |
|---|---|---|---|
| hub/nat.bend |  | `All terms check.` | OK |
| hub/string.bend |  | `All terms check.` | OK |
| hub/list.bend |  | `All terms check.` | OK |
| hub/example.bend |  | `All terms check.` | OK |

## gate

| check | book (2.0.5) | now | verdict |
|---|---|---|---|
| gate/matrix |  | `t1_ok rc=0 out=All terms check. err=` | OK |

## bench

| check | book (2.0.5) | now | verdict |
|---|---|---|---|
| parallel/pow2_26 @1t | 0.22-0.23 s | settled 0.24s (runs after first: 0.25 / 0.24); first run 0.55s (cold)  | OK |
| parallel/pow2_26 @2t | 0.12-0.13 s | settled 0.13s (runs after first: 0.13 / 0.13) | OK |
| parallel/pow2_26 @4t | 0.07 s | settled 0.07s (runs after first: 0.08 / 0.07) | OK |
| parallel/pow2_26 @8t | 0.04 s | settled 0.05s (runs after first: 0.05 / 0.05) | OK |
| parallel/pow2_26 @14t | 0.04-0.05 s | settled 0.05s (runs after first: 0.05 / 0.05) | OK |
| gpu/gpu_floor | 0.08-0.09 s | settled 0.08s (runs after first: 0.09 / 0.08) | OK |
| gpu/pow2_gpu | 0.09-0.10 s | settled 0.09s (runs after first: 0.10 / 0.09) | OK |
| gpu/gpu_twice | 0.09 s | settled 0.09s (runs after first: 0.11 / 0.09) | OK |
| gpu/mandelbrot cpu @1t | 5.10-5.12 s | settled 5.61s (runs after first: 5.61 / 5.62) | OK |
| gpu/mandelbrot cpu @10t | 0.72 s | settled 0.75s (runs after first: 0.75 / 0.75) | OK |
| gpu/mandelbrot gpu | 0.10-0.12 s | settled 0.11s (runs after first: 0.12 / 0.11) | OK |
| gpu/queens cpu @1t | 6.02-6.19 s | settled 6.60s (runs after first: 6.60 / 6.61) | OK |
| gpu/queens cpu @10t | 0.85 s | settled 0.89s (runs after first: 0.89 / 0.90) | OK |
| gpu/queens gpu | 1.34-1.41 s | settled 1.65s (runs after first: 1.74 / 1.65) | OK |
| life/life_row @1t | 4 / 17 / 70 / 308 ms (64 generations, ns/cell flat) | settled 0.43s (runs after first: 0.43); first run 0.64s (cold)  | OK |
| life/life_par @1t | 1t: 1795 / 2065 / 2025 ms | settled 14.90s (runs after first: 14.90) | OK |
| life/life_par @10t | 10t: 690 / 684 / 1045 ms | settled 11.18s (runs after first: 11.18) | OK |

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

  64x64  live=5  ms=17

128x128  live=5  ms=72

256x256  live=5  ms=315


64x64, 16 generations -- head to head with the naive version

  64x64  live=5  ms=5
-- life/life_par @1t --
64x64, 4 generations

blk=1  (4096 tasks)  live=5  ms=1842

blk=16 ( 256 tasks)  live=5  ms=2112

blk=64 (  64 tasks)  live=5  ms=2079


naive, no fork (d=0, blk=w*h)

  32x32 16gen  live=5  ms=521

  64x64 16gen  live=5  ms=8326
-- life/life_par @10t --
64x64, 4 generations

blk=1  (4096 tasks)  live=5  ms=756

blk=16 ( 256 tasks)  live=5  ms=724

blk=64 (  64 tasks)  live=5  ms=1071


naive, no fork (d=0, blk=w*h)

  32x32 16gen  live=5  ms=529

  64x64 16gen  live=5  ms=8084
```

## Annotations

- **affinity/t3_arr** — error wrapper: 'a parameter or field scrutinee (...)'; message core matches arrays/a_fail
- **basics/pat_bad** — WARNING-probe: compiles and lies by design.  f(2n) should be 2, prints 1.
- **basics/esc_bad** — WARNING-probe: emits wrong bytes by design.  \033 is \0 then '33'.
- **affinity/t10_template** — CHANGED(2.0.16, intended -- see CHANGELOG): a def that is a template instance counts as unsafe, so a file with a template prints 'All terms check, with N unsafe annotations.' on stderr 'until the checker verifies template expansion itself'.  2.0.5's cli_report counted only @unsafe and printed nothing when running a file with a main.  The template does NOT skip any check; this is a disclosure, not a soundness hole.
- **arrays/e_post1** — book README prints it without spaces; the actual normalizer output has spaces after commas.  Formatting only.
- **gpu/gpu_floor** — .gpu semantics (same design in 2.0.5's comp.ts and in 2.0.16): `bend -o X` writes X.gpu beside X; a launch LOADS it when present (silent), and prints 'compiling the GPU program (missing or stale)' and recompiles only when the file is absent or empty.  A run never writes the kernel back on Metal -- with X.gpu absent, every run notes and recompiles (~0.08 s either way; Metal's OS cache feeds the recompile).  A .gpu from a different program loaded silently and still computed correctly (the kernel source is embedded in the host binary).  The papercut of 2026-09-18 described an X.gpu-less binary, so its 'prints every run' is correct for that setup only.
- **hub/nat.bend** — published as 0x1ee1b5d0c2a66817bf368b849f3117fc
- **hub/string.bend** — published as 0x89df026edd2acf2673b5e469e037eaf1
- **hub/list.bend** — published as 0x085d89db9ee8a21865e959816bb20e5b
- **hub/example.bend** — the consumer example; fetches all three packages by hash
- **gate/matrix** — T6 phase 0.  t2 pins the effective gate semantics: a FALSE law 'proven' by @unsafe non-termination passes with rc=0; the only signal is the degraded stdout line -- deliberate per upstream #776/#805 (disclosure shipped in 2.0.8, exit code unchanged), so CI must match `All terms check.` exactly, or forbid @unsafe.  t5: an emptied law set passes.  t6: the unsafe count is book-wide, not proof-scoped.  t7: a stray proof def after the law is deleted is a parse error ('expected : ->') -- filed upstream as a diagnostic-er quality issue.

