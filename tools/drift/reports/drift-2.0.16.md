# Drift report — bend 2.0.16 (2.0.16)

- date: 2026-09-19 11:11 UTC
- machine: Apple M3 Max, 14 cores (10 performance), macOS 27.0
- bend binary: `/Users/randall/.bend/bin/bend` sha256 `da9bc51449f04a65…`
- repo: `/Users/randall/projects/bend2-from-zero` at `98eb466` (dirty: 4 files)
- load average at start/end: 2.20/2.13/2.20 / 2.56/2.25/2.23
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

## fx

| check | book (2.0.5) | now | verdict |
|---|---|---|---|
| fx/io/deadlock |  | `bend: deadlock: every computation waits on a channel` | OK |
| fx/io/sleep_par |  | `total ms=709` | OK |
| fx/io/join_reuse_bad |  | `Error:` | OK |
| fx/io/join_twice |  | `first join=41` | OK |
| fx/io/match_in_do_bad |  | `Error:` | OK |
| fx/io/close_recv |  | `send=true` | OK |
| fx/io/send_after_close |  | `send-after-close=false` | OK |
| fx/io/orphan_deadlock |  | `main done` | OK |
| fx/io/die |  | `before die` | OK |
| fx/io/try_fail |  | `No such file or directory` | OK |
| fx/io/room_full |  | `send=true` | OK |
| fx/io/chan_fifo |  | `four sends done` | OK |
| fx/io/spawn |  | `main done` | OK |
| fx/io/args |  | `argc=3` | OK |
| fx/custom/clock |  | `ms since boot: 53` | OK |
| fx/custom/shout_repeat |  | `HELLO, BEND` | OK |
| fx/custom/utf8 |  | `héllo·世界héllo·世界` | OK |
| fx/custom/delay |  | `t0=56 d_builtin=307 d_custom=303` | OK |
| fx/custom/busy |  | `tick 300` | OK |
| fx/custom/misnamed_host |  | `TypeError: op.run is not a function. (In 'op.run(...op.args, op.kont)', 'op.run' is undefi` | OK |
| fx/custom/missing_registration |  | `bend: an alien request` | OK |
| fx/file/roundtrip |  | `size=11` | OK |
| fx/file/position |  | `chunk: [hello]` | OK |
| fx/file/open_missing |  | `No such file or directory` | OK |
| fx/file/read_after_close_bad |  | `Error:` | OK |
| fx/tcp/roundtrip |  | `listening on 127.0.0.1:7811` | OK |
| fx/tcp/refused |  | `Connection refused` | OK |
| fx/lane/lazy_checker |  | `7n` | OK |
| fx/lane/lazy_checker_baseline |  | `7n` | OK |

## bench

| check | book (2.0.5) | now | verdict |
|---|---|---|---|
| parallel/pow2_26 @1t | 0.22-0.23 s | settled 0.21s (runs after first: 0.22 / 0.21); first run 0.44s (cold)  | OK |
| parallel/pow2_26 @2t | 0.12-0.13 s | settled 0.12s (runs after first: 0.12 / 0.12) | OK |
| parallel/pow2_26 @4t | 0.07 s | settled 0.07s (runs after first: 0.07 / 0.07) | OK |
| parallel/pow2_26 @8t | 0.04 s | settled 0.04s (runs after first: 0.04 / 0.04) | OK |
| parallel/pow2_26 @14t | 0.04-0.05 s | settled 0.05s (runs after first: 0.05 / 0.05) | OK |
| gpu/gpu_floor | 0.08-0.09 s | settled 0.07s (runs after first: 0.08 / 0.07) | OK |
| gpu/pow2_gpu | 0.09-0.10 s | settled 0.09s (runs after first: 0.09 / 0.09) | OK |
| gpu/gpu_twice | 0.09 s | settled 0.09s (runs after first: 0.10 / 0.09) | OK |
| gpu/mandelbrot cpu @1t | 5.10-5.12 s | settled 5.01s (runs after first: 5.01 / 5.02) | OK |
| gpu/mandelbrot cpu @10t | 0.72 s | settled 0.72s (runs after first: 0.72 / 0.73) | OK |
| gpu/mandelbrot gpu | 0.10-0.12 s | settled 0.10s (runs after first: 0.10 / 0.10) | OK |
| gpu/queens cpu @1t | 6.02-6.19 s | settled 5.89s (runs after first: 5.89 / 5.89) | OK |
| gpu/queens cpu @10t | 0.85 s | settled 0.86s (runs after first: 0.86 / 0.86) | OK |
| gpu/queens gpu | 1.34-1.41 s | settled 1.71s (runs after first: 1.85 / 1.71) | OK |
| life/life_row @1t | 4 / 17 / 70 / 308 ms (64 generations, ns/cell flat) | settled 0.41s (runs after first: 0.41); first run 0.65s (cold)  | OK |
| life/life_par @1t | 1t: 1795 / 2065 / 2025 ms | settled 14.31s (runs after first: 14.31) | OK |
| life/life_par @10t | 10t: 690 / 684 / 1045 ms | settled 10.56s (runs after first: 10.56) | OK |

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

  32x32  live=5  ms=4

  64x64  live=5  ms=17

128x128  live=5  ms=69

256x256  live=5  ms=301


64x64, 16 generations -- head to head with the naive version

  64x64  live=5  ms=5
-- life/life_par @1t --
64x64, 4 generations

blk=1  (4096 tasks)  live=5  ms=1764

blk=16 ( 256 tasks)  live=5  ms=2039

blk=64 (  64 tasks)  live=5  ms=2002


naive, no fork (d=0, blk=w*h)

  32x32 16gen  live=5  ms=499

  64x64 16gen  live=5  ms=7991
-- life/life_par @10t --
64x64, 4 generations

blk=1  (4096 tasks)  live=5  ms=670

blk=16 ( 256 tasks)  live=5  ms=651

blk=64 (  64 tasks)  live=5  ms=979


naive, no fork (d=0, blk=w*h)

  32x32 16gen  live=5  ms=507

  64x64 16gen  live=5  ms=7735
```

## Annotations

- **affinity/t3_arr** — error wrapper: 'a parameter or field scrutinee (...)'; message core matches arrays/a_fail
- **basics/pat_bad** — WARNING-probe: compiles and lies by design.  f(2n) should be 2, prints 1.
- **basics/esc_bad** — WARNING-probe: emits wrong bytes by design.  \033 is \0 then '33'.
- **affinity/t10_template** — CHANGED(2.0.16, intended -- see CHANGELOG): a def that is a template instance counts as unsafe, so a file with a template prints 'All terms check, with N unsafe annotations.' on stderr 'until the checker verifies template expansion itself'.  2.0.5's cli_report counted only @unsafe and printed nothing when running a file with a main.  The template does NOT skip any check; this is a disclosure, not a soundness hole.
- **arrays/e_post1** — book README prints it without spaces; the actual normalizer output has spaces after commas.  Formatting only.
- **gpu/gpu_floor** — .gpu semantics (same design in 2.0.5's comp.ts and in 2.0.16): `bend -o X` writes X.gpu beside X; a launch LOADS it when present (silent), and prints 'compiling the GPU program (missing or stale)' and recompiles only when the file is absent or empty.  A run never writes the kernel back on Metal -- with X.gpu absent, every run notes and recompiles (~0.08 s either way; Metal's OS cache feeds the recompile).  A .gpu from a different program loaded silently and still computed correctly (the kernel source is embedded in the host binary).  The papercut of 2026-09-18 described an X.gpu-less binary, so its 'prints every run' is correct for that setup only.
- **gpu/queens gpu** — Re-measured 2026-09-19: ~1.7 s (median) here, and the same ~1.7 s from the Sep-18 2.0.5-built binary (gpu/queens/gpu) interleaved on the same machine -- so this is NOT a 2.0.5->2.0.16 regression.  queens-gpu is the only workload whose GPU compute is not hidden under the ~85 ms entry fee (mandelbrot's real work is ~30 ms), so it is the only one that can show a GPU-state difference; the difference is environment (GUI/GPU contention), per the book's own warning to record a parallel number with the machine's state.  See reports/drift-2.0.16-quiet.md.
- **hub/nat.bend** — published as 0x1ee1b5d0c2a66817bf368b849f3117fc
- **hub/string.bend** — published as 0x89df026edd2acf2673b5e469e037eaf1
- **hub/list.bend** — published as 0x085d89db9ee8a21865e959816bb20e5b
- **hub/example.bend** — the consumer example; fetches all three packages by hash
- **gate/matrix** — T6 phase 0.  t2 pins the effective gate semantics: a FALSE law 'proven' by @unsafe non-termination passes with rc=0; the only signal is the degraded stdout line -- deliberate per upstream #776/#805 (disclosure shipped in 2.0.8, exit code unchanged), so CI must match `All terms check.` exactly, or forbid @unsafe.  t5: an emptied law set passes.  t6: the unsafe count is book-wide, not proof-scoped.  t7: a stray proof def after the law is deleted is a parse error ('expected : ->') -- filed upstream as a diagnostic-er quality issue.
- **fx/io/deadlock** — one computation waits on a channel nobody sends to
- **fx/io/sleep_par** — two forked 700 ms sleeps finish in ~709 ms (one sleep's time)
- **fx/io/join_reuse_bad** — join consumes the channel; a second join does not compile
- **fx/io/join_twice** — with +ch it compiles; the second join dies at runtime
- **fx/io/match_in_do_bad** — match cannot live inside a do block; extract it into a def
- **fx/io/close_recv** — close then recv answers None
- **fx/io/send_after_close** — send on a closed channel answers false, not an error
- **fx/io/orphan_deadlock** — main returning is not the program ending: a leftover waiting task turns the whole exit into a deadlock report
- **fx/io/die** — IO.die: the process exits with your code (7), message on stderr, later statements do not run
- **fx/io/try_fail** — IO.try on a failed Result: exit code is the errno (ENOENT=2)
- **fx/io/room_full** — a full room makes send wait (it does not return false); with nobody receiving, the program reports deadlock
- **fx/io/chan_fifo** — room 4: four sends do not block, receives come FIFO
- **fx/io/spawn** — IO.spawn: the program waits for the spawned task (no deadlock)
- **fx/io/args** — -- stops bend's own parsing and is not passed to the program
- **fx/custom/clock** — the two lanes measure different quantities: native=since boot, JS=since process start (book material)
- **fx/custom/shout_repeat** — two effects that are not in Base; green in run and native lanes (and -o x.js + bun, checked by hand)
- **fx/custom/utf8** — UTF-8 through a custom effect: byte-identical in both lanes
- **fx/custom/delay** — a custom need (IO_TIME) parks the loop like IO.sleep
- **fx/custom/busy** — io_work runs the blocking call on a helper thread; the loop stays live (the ticker fires during the 1000 ms of work)
- **fx/custom/misnamed_host** — JS host function name wrong: a raw runtime TypeError; the compiled lane is unaffected (its C file is fine)
- **fx/custom/missing_registration** — C file without its io_eff registration: compiles; native run dies at first use; the JS lane is unaffected
- **fx/file/position** — sequential reads advance the position; read_at does not
- **fx/file/read_after_close_bad** — handle misuse after close is a compile error (affine)
- **fx/tcp/refused** — ECONNREFUSED=61, same in both lanes
- **fx/lane/lazy_checker** — WONTFIX #775: run mode skips the dead 200M-step argument (0.057 s) while the compiled lane pays it (0.18 s)
- **fx/lane/lazy_checker_baseline** — same call with spin(0n): the cost reference

