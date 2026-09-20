# Every number in this book, and how it was measured

Every timing in this book comes from one machine, and this appendix is the record
of which machine, what command, and what the number did when it was re-run.

## The machine

| | |
|---|---|
| CPU | Apple M3 Max |
| cores | 14 logical — **10 performance, 4 efficiency** |
| memory | 36 GB, unified |
| OS | macOS 27.0 |
| Bend | 2.0.16 |

`hw.perflevel0.logicalcpu` reports 10. That is why `--threads 8` and `--threads 10`
are where the parallel curves flatten and `--threads 14` is slower: past ten the
scheduler is putting work on the efficiency cores. Any thread count above 10 in
this book should be read as oversubscription, not as more capacity.

**All numbers were re-run for this appendix on 2026-09-18**, on the machine above,
with nothing else running. Where a value moved, the book quotes the new one.

Every one of them is re-checked mechanically with `tools/drift/run_drift.py` —
92 checks — so a version that moves a number says so instead of leaving the book
quietly wrong.

## 1. The two proof gates

```sh
cd life
/usr/bin/time -p bend LIFE_PAR_PROOF.bend
/usr/bin/time -p bend LIFE_ANIM_PROOF.bend
```

| | result | real | user |
|---|---|---|---|
| `LIFE_PAR_PROOF` | `All terms check.` | 0.10 s | 0.25 s |
| `LIFE_ANIM_PROOF` | `All terms check.` | 0.09 s | 0.21 s |

`user` is about 2.5× `real` because Bend's checker itself runs in parallel. The
wall-clock number is what a human experiences; it includes Bend's startup.

## 2. The size of a proof error

```sh
# break the proof by miscalling a lemma, then:
bend LIFE_PAR_PROOF.bend 2>&1 | wc -c
bend LIFE_PAR_PROOF.bend 2>&1 | python3 elide_errors.py | wc -c
```

| | bytes |
|---|---|
| raw | 14,151 |
| after `elide_errors.py` | 1,576 |

Worth noting the contrast: a **late** proof error is small. Three deliberate
changes to the implementation produced errors of 270, 553 and 638 bytes, all
readable. The 14 KB monster only appears when the goal is stuck at a point where
`block` has already unfolded into conses — which is a middle-of-the-proof
situation, and the one where you most need to see the difference.

## 3. `pow2`: the parallel curve

```sh
cd parallel && bend pow2_26.bend -o pow2_26
for t in 1 2 4 8 14; do /usr/bin/time -p ./pow2_26 --threads $t; done
```

`pow2(26n)` is 67,108,864 additions. Every run prints `67108864`.

| threads | real | speedup |
|---|---|---|
| 1 | 0.23 s | 1.0× |
| 2 | 0.12 s | 1.9× |
| 4 | 0.07 s | 3.3× |
| 8 | 0.04 s | 5.8× |
| 14 | 0.04 s | 5.8× |

Near-perfect to 4, then it saturates. The value is not the arithmetic — it is that
**a plain parallel let runs on the CPU with no `!` anywhere.** `!` is what sends a
call to the GPU; it is not what enables parallelism.

## 4. The GPU entry fee

```sh
cd gpu
bend gpu_floor.bend -o gpu_floor && ./gpu_floor   # result is 4!
bend pow2_gpu.bend  -o pow2_gpu  && ./pow2_gpu    # result is 67108864
bend gpu_twice.bend -o gpu_twice && ./gpu_twice   # two calls
```

| program | work | real |
|---|---|---|
| `gpu_floor` | `pow2!(2n)` → 4 | 0.08 – 0.09 s |
| `pow2_gpu` | `pow2!(26n)` → 67,108,864 | 0.09 – 0.10 s |
| `gpu_twice` | `pow2!(25n) + pow2!(26n)` | 0.09 s |

**Sixty-seven million additions cost the same as four.** And a *second* GPU call in
the same process costs almost nothing extra. So the ~85 ms is a per-process entry
cost, not a per-call tax — and `gpu_floor` has no fork-join work left in it at
all, which rules out the scheduler as the explanation. It is the Metal runtime:
device, command queue, pipeline state.

This is the measurement that changed the meaning of every other GPU number in the
book. If you take one methodological habit from this appendix, take this one:
**when a GPU number surprises you, write a program that does nothing and measure
that.**

## 5. mandelbrot — uniform numeric work

```sh
cd gpu/mandelbrot
./cpu --threads 1     # 5.10, 5.11
./cpu --threads 10    # 0.72, 0.71
./gpu                 # 0.12, 0.11, 0.10
```

4096² pixels, 51 iterations.

| | real | minus the ~85 ms door | CPU, 10 threads |
|---|---|---|---|
| CPU 1 thread | 5.10 s | — | — |
| CPU 10 threads | 0.72 s | — | 0.72 s |
| GPU | 0.10 – 0.12 s | **~0.03 s** | **≈ 20× faster** |

**The first run is slow.** An early measurement of this binary was 0.226 s, which
settled to 0.108 s on repetition — a factor of two. Never quote a GPU number from
a single run.

## 6. queens — divergent search

```sh
cd gpu/queens
./cpu --threads 1     # 6.02, 6.19
./cpu --threads 10    # 0.85, 0.86
./gpu                 # 1.36, 1.34, 1.41
```

N=17 exhaustive search.

| | real | minus the door |
|---|---|---|
| CPU 10 threads | 0.855 s | — |
| GPU | 1.34 – 1.41 s | **~1.29 s** |

The CPU wins, and not narrowly. This is the one place where the guide's own claim
— divergent work stays on the CPU — came out against the GPU by our own
measurement rather than by repetition.

## 7. Life — the row-window engine

```sh
cd life && bend life_row.bend -o life_row
./life_row --threads 1
```

Sixty-four generations, one thread:

| grid | cells | total | ns per cell, per generation |
|---|---|---|---|
| 32×32 | 1,024 | 4 ms | **61** |
| 64×64 | 4,096 | 17 ms | **65** |
| 128×128 | 16,384 | 70 ms | **67** |
| 256×256 | 65,536 | 308 ms | **73** |

The right column is flat over a 64× range of sizes. That is what O(n) looks like.

⚠️ **`IO.now()` has one-millisecond resolution.** The 32×32 row is four ticks
wide, so its `ns` figure carries roughly ±25%; the book's tables once said 76
there. Every small value in this book is subject to this. Treat the shape of a
column as the finding and the individual cells as approximate.

## 8. Life — naive vs row window, head to head

```sh
./life_par --threads 1     # last line: "naive, no fork", 64x64, 16 generations
./life_row --threads 1     # last line: 64x64, 16 generations
```

Both single-threaded, 64×64, sixteen generations:

| | ms |
|---|---|
| naive (`life_par.bend`, `d=0`, no fork) | 8,114 |
| row window (`life_row.bend`) | **5** |

**≈ 1,600×.** The divisor sits on the timer's resolution, so across sessions this
ratio reads anywhere from about 1,600× to 2,000×. The order of magnitude is the
finding.

The naive side also demonstrates the complexity directly:

| grid | cells | 16 generations | ns per cell, per generation |
|---|---|---|---|
| 32×32 | 1,024 | 506 ms | 30,900 |
| 64×64 | 4,096 | 8,114 ms | 123,800 |

Cells ×4, cost per cell ×4, total ×16. That is O(n²) announcing itself.

## 9. Life — the fork-join granularity table

```sh
cd life && bend life_par.bend -o life_par
./life_par --threads 1
./life_par --threads 10
```

64×64, four generations, three leaf sizes. `blk` is how many cells each leaf task
computes; `2^d × blk = 4096`.

| threads | blk=1 (4096 tasks) | blk=16 (256) | blk=64 (64) |
|---|---|---|---|
| 1 | 1,795 ms | 2,065 | 2,025 |
| 10 | 690 ms | **684** | 1,045 |

Three things to read here.

**The speedup is only about 2.6–3× on ten cores.** That is not the scheduler
failing; it is the shape of this program. Each generation must finish before the
next can start, so there is a join barrier every generation, and there are only
four generations.

**Finer is not reliably faster.** An earlier version of this code — the
`build` + `flatten` structure, before it was rewritten into `tree_cells` so the law
could be proved — showed `blk=1` clearly ahead at every thread count. After the
rewrite the ordering is much flatter at ten threads and `blk=16` is marginally
ahead. The rewrite moved `app` (the concatenation of the two halves) *inside* the
fork-join region, so every join has one worker concatenating while the other
idles; more joins means more idling.

The lesson is about the confusion, not the numbers: **"finer granularity is
faster" was true of one implementation, and was written down as if it were a
property of the scheduler.** It was corrected by the rewrite.

**The command's own wall clock is not the number to quote.** The same command also
runs two `naive, no fork` cases — depth zero, one leaf for the whole grid, so
serial by construction — and they are most of it. `/usr/bin/time -p` on
`./life_par --threads 1` reads 14.2 s against 10.5 s on `--threads 10`, while the
three fork-join cases inside that same process go from 5.7 s to 2.3 s. The two
serial cases account for the difference: 8.4 s of the fourteen, and 8.2 s of the
ten and a half.

## The disciplines, collected

Everything above is one number with a command. These are the habits that made the
numbers mean something, and each was learned by getting it wrong first.

**A benchmark that measures two things measures neither.** The first parallel Life
benchmark ran the serial version and the parallel version in the same process, so
the reading was of the whole process — and the serial baseline swallowed half the
wall clock. The parallel section was going from 493 ms to 211 ms while the process
looked flat. The fix is a narrower benchmark, not a better one.

**`real` can lie about parallelism; `user` cannot.** `real` includes every serial
part of the program. `user` is total CPU time across all cores, so `user / real` is
the average number of cores actually working. When `user` climbs from 7.0 s to
11.6 s across a thread sweep, the parallelism is real regardless of what `real`
does.

**Measure the floor.** If a number surprises you, build the smallest program that
should be cheap, and time that. `gpu_floor` cost the same as the real workload and
rewrote the conclusion of a whole chapter.

**Write the unit down.** `ns per cell, per generation` moves in a straight line
where `ms` does not, and `user / real` says something `real` cannot. A raw
millisecond count is only comparable to another millisecond count from the same
machine, kernel and load.

**A ratio has a resolution too.** `8,114 / 5` looks precise and is not: the
divisor is five timer ticks. Report the range you actually observed, and say which
end is at risk.

**Re-run before quoting.** Every number here was re-measured for this appendix,
and two of them moved. That is the normal outcome, not a sign that something was
wrong the first time.
