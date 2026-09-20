# life — the Game of Life, five implementations and two proved laws

One program throughout (a toroidal grid from 8×8 up to 256×256, holding a glider).
**This directory is the most valuable comparison in the repo:** it demonstrates both
"what parallelism buys you" and "what choosing the right algorithm buys you", and those
two numbers are two orders of magnitude apart. A 3× difference and a 1,600× difference
are not the same kind of fact.

| File | Approach | Complexity |
|---|---|---|
| `life.bend` | naive serial; each cell looks up its neighbours by index | **O(n²)** |
| `life_par.bend` | the same, plus fork-join, with a granularity knob | O(n²) |
| `life_row.bend` | row-wise sliding window, no index lookup | **O(n)** |
| `life_rowpar.bend` | the row engine under the same fork-join tree, forked over rows | O(n) |
| `life_anim.bend` | a terminal animation built on `life_row`'s engine | O(n) |
| `LIFE_PAR_LAWS.bend` | the law: `life_par`'s tree == the same serial loop (hand-written) | — |
| `LIFE_PAR_PROOF.bend` | the proof of that law (`bend` on it is the gate) | — |
| `LIFE_ANIM_LAWS.bend` | the law: `life_anim`'s fast render == the slow, obvious spec (hand-written) | — |
| `LIFE_ANIM_PROOF.bend` | the proof of that law (the gate) | — |

(`n` = total cells in the grid. `life.bend` is the 8×8 teaching version that prints the
pattern every generation; the other two are benchmarks that print only timings.)

## What was wrong

The first two versions looked up neighbours like this:

```python
def at(+g, +w, +h, +x: Nat, +y: Nat) -> Nat:
  nth(g, Nat.add(Nat.mul(Nat.mod(y, h), w), Nat.mod(x, w)))
      #  ↑ nth walks to that index one link at a time; cost = O(index)
```

Every cell reads 8 neighbours, so **the cost per cell per generation grows with the
grid** → O(n²) overall. The measurement says so directly: at 32×32, 30,900 ns per cell
per generation; at 64×64, 123,800 ns. Cells ×4, cost per cell ×4.

## How `life_row` gets to O(n)

Two passes, and nothing ever "jumps to index i":

```
pass 1  column sum  s[x] = prev[x] + cur[x] + next[x]        ← three rows side by side
pass 2  row window  new[x] = rule(cur[x], s[x-1] + s[x] + s[x+1] - cur[x])
```

The grid is represented as a **list of rows**; vertical wrap is `rows_rot1`, horizontal
wrap is `rot_l`/`rot_r` within a row (`rot_r` is implemented as `rev ∘ rot_l ∘ rev` so
it does not degrade to O(w²)). Each cell per generation does about 9 O(1) reads.

## Numbers

### O(n) scaling — single thread, 64 generations

| Grid | Cells | ms | ns / cell / generation |
|---|---|---|---|
| 32×32 | 1,024 | 4 | **61** |
| 64×64 | 4,096 | 17 | **65** |
| 128×128 | 16,384 | 69 | **67** |
| 256×256 | 65,536 | 306 | **73** |

Cells rise 64×; cost per cell barely moves. That is what O(n) looks like.

(⚠️ `IO.now()` has 1 ms resolution and the 32×32 row is four ticks wide, so its `ns`
figure carries roughly ±25%. Read the *shape* of the column as the finding.)

### What parallelism buys — 64×64, 4 generations

`life_par.bend` renames the serial step to `block` and uses it as a **leaf** (computing
`blk` consecutive cells), wrapped in a balanced binary tree `tree_cells`:
`a b = tree_cells(...) tree_cells(...)` is the fork, and the join concatenates the two
halves with `app`. `2^d × blk = w×h` covers the grid, and `blk` is the granularity knob.

| threads | blk=1 (4096 tasks) | blk=16 (256) | blk=64 (64) |
|---|---|---|---|
| 1 | 1,735 ms | 1,958 | 1,936 |
| 10 | 676 ms | **628** | 986 |
| speedup | 2.57× | **3.12×** | 1.96× |

**About 2.6–3.1× on ten cores** at the two finer settings, and only 2× at the coarsest. That is not the scheduler failing; it is the shape of
this program. Each generation must finish before the next can start, so there is a join
barrier every generation, and there are only four of them.

**This code was rewritten once so that it could be proved** (see "Laws and proofs"
below). Before the rewrite it was two functions, `build` (make the tree) and `flatten`
(flatten it); a paired run on the same machine at the same time:

| | blk=1 | blk=16 | blk=64 |
|---|---|---|---|
| old `build`+`flatten`, 1 thread | 2,081 | 2,388 | 2,512 |
| old, 10 threads | **503** (4.14×) | 651 (3.67×) | 1,004 (2.50×) |
| new `tree_cells`, 1 thread | **1,735** | 1,958 | 1,936 |
| new, 10 threads | 676 (2.57×) | **628** (3.12×) | 986 (1.96×) |

Both directions moved at once:

- **The serial version got faster** (`2,081 → 1,735` ms at `blk=1`). `flatten` walks the
  whole tree a second time to rebuild the list; `tree_cells` concatenates at the join.
- **Parallelism got worse**, and the best granularity flipped from `blk=1` to `blk=16`.
  `app` is serial work, and the rewrite moved it *inside* the fork-join region — so
  every join now has one worker concatenating while the other idles. That is exactly the
  guide's line, *"if one call finishes before the other, the speedup will be sub-ideal"*.

So the earlier claim here, "finer granularity is faster", holds only for the old
`build`+`flatten` structure. **It is a fact about one implementation, not a property of
the scheduler.** A parallel number has to be recorded together with the implementation
that produced it.

### The two versions head to head — 64×64, 16 generations, both single-threaded

| | ms |
|---|---|
| O(n²) `life_par.bend` (`d=0`, no fork at all) | 8,114 |
| **O(n) `life_row.bend`** | **5** |

**≈ 1,600×. Neither version used a second thread — the entire difference is the
algorithm.**

The ten-core O(n²) version (676 ms, 4 generations) is still two orders of magnitude
away from the single-core O(n) version. **Parallelism is a multiplier on top of an
algorithm; it does not choose the algorithm.**

(The divisor sits on the timer's 1 ms resolution, so across sessions this ratio reads
anywhere from about 1,600× to 2,000×. The order of magnitude is the finding.)

### The cores on the O(n) engine

`life_rowpar.bend` hangs the same fork-join tree over the row engine, one
level up: leaves are runs of consecutive output rows, `blk` is **rows per
leaf**, and the clock wraps `evolve` only (the grid is built and counted
outside it). Measured 2026-09-20, two to three runs per cell:

| board | walk, 1 thread | walk, 4 threads | tree, 4 leaves, 4 threads | tree, 4 leaves, 1 thread |
|---|---|---|---|---|
| 256×256, 64 gens | 272-295 ms | 291-293 ms | **210 ms** | 369 ms |
| 512×512, 64 gens | 1,439-1,443 ms | 1,559-1,560 ms | **1,127-1,157 ms** | 1,945-1,948 ms |

Four cores: a stable 1.4× over the walk. Ten cores buy nothing over four —
four leaves per generation cap the width, and finer trees (8/16 leaves)
never win: the fork, the drop walks and the joins are real work, about a
third on one thread. Full tables: the *Life in O(n), by rows* chapter.

## Laws and proofs — `LIFE_PAR_LAWS.bend` / `LIFE_PAR_PROOF.bend`

`LIFE_PAR_LAWS.bend` states the proposition (hand-written).
`LIFE_PAR_PROOF.bend` proves it. Only `bend LIFE_PAR_PROOF.bend` printing
`All terms check.` counts.

> **The law:** the cell sequence the tree produces equals, cell for cell, the sequence
> the same serial loop produces.

```python
Par.tree_cells(d, g, w, h, blk, k) == Par.block(g, w, h, Par.cells_in(d, blk), k)
```

This is the isomorphic version of the law in `demos/pure_par_sum` (where it is
"the tree's sum == the loop's sum"), with numbers swapped for a list of cells.

> On naming: Bend's convention is that this pair is called `LAWS.bend` + `PROOF.bend`
> and lives at the project root (`bend PROOF.bend` is the gate command in the docs).
> What is being rejected here is the **topic** prefix — the repo has six topic
> directories, and `LIFE_LAWS` would not say which thing it proves. `LIFE_PAR_` names
> not a topic but the **subject file**: the law of `life_par.bend` is
> `LIFE_PAR_LAWS.bend`, so `import ./life_par.bend as Par` and
> `import ./LIFE_PAR_LAWS.bend as Laws` read as two halves of one name. The next
> implementation takes the same suffix and cannot collide.

### The shape of the proof

Induction on depth `d`. The goal is written `{implementation == spec}`, and each rewrite
step turns the **right-hand (spec) side** into the shape of the implementation, until
both sides are the same term. Three lemmas:

- `add_zero` — `Nat.add` recurses on its first argument, so `Nat.add(k, 0n)` is stuck on
  the variable `k`
- `add_assoc` — the right subtree's offset has to be read as `(k+1)+q` before the
  induction hypothesis applies
- `cells_add` — splitting the serial loop: `n` cells followed by `m` equals `n+m` cells

### Three traps

**① The type of `_` in `%e : P` is inferred from where it is written.** `_` marks the
position where `b` appears in the equation, and its type comes from **where you wrote
it**. Writing `Par.block(g, w, h, _, k)` infers `_ : Nat` (the cell count), but `b` is
the whole `block(...)`, whose type is `List` — you get
`expected : Nat / observed : List<&2, Nat>`. It has to be marked at a `List` position,
like `app(..., _)` or `Con{cell, _}`.

**② `block` unfolds into a cons.** `block(1+q+m, k)` *is*
`cellnext(k) <> block(q+m, k+1)`, so the equation to be proved ends up underneath
`cellnext(k) <> _`, and `_` can only be marked one level **below** that.
`pure_par_sum` has no such problem because `Nat.add` has no cons structure — which is
why its proof is three lines, and why the cons has to be written out explicitly here.

**③ Giving the proved function a same-shaped recursion removes a distributivity
lemma.** The offset was originally `Nat.mul(pow2(p), blk)`, and proving anything about
it means splitting `2^p·blk` into two `2^(p-1)·blk` terms, which needs multiplication to
distribute over addition. Rewritten as `cells_in(p, blk)` — the same recursion as the
tree, no multiplication — that lemma disappears entirely.

When debugging a proof, use `elide_errors.py`: a failing proof prints both sides
**fully expanded**, several thousand characters for `cellnext` alone, with the one place
they differ invisible. It collapses those terms to `CELL`:

```sh
bend LIFE_PAR_PROOF.bend 2>&1 | python3 elide_errors.py
```

### This gate really does stop you

"All terms check" is not by itself evidence — a false proof passes too. So break it on
purpose. The breakage goes in the **implementation** file `life_par.bend` (breaking
`LIFE_PAR_LAWS.bend` is pointless: that is the spec, and breaking it just makes the
proof prove something else):

| Change | `bend LIFE_PAR_PROOF.bend` |
|---|---|
| `tree_cells` right-subtree offset `Nat.add(k, cells_in(p, blk))` → `k` | **Error** |
| leaf start `block(g, w, h, blk, k)` → `block(g, w, h, blk, 0n)` | **Error** |
| join `app(a, b)` → `app(b, a)` (halves swapped) | **Error** |
| unchanged | `All terms check.` |

### The next law, and why "index safety" is a different kind of problem

The candidate is the index safety of `at()` — every index lands in `0 .. w*h`:

```python
Nat.is_lt(Nat.add(Nat.mul(Nat.mod(y, h), w), Nat.mod(x, w)), Nat.mul(h, w))
```

It is not the same kind of problem as `tree_is_serial`. The one above is **purely
structural**: induction on lists, no multiplication, no comparison, no `Nat.cmp`. This
one needs **arithmetic**, and Base has **not one arithmetic lemma**
(`bend base | grep "-> {.*=="` is empty).

Nor can it be stated directly: at `b = 0`, `Nat.mod(a, 0n) = a`, and `a < 0` is false. So
the proposition itself needs a "`b` is positive" premise. Then every step has to be built:

| Fact needed | Cost |
|---|---|
| `a < a + 1` | one induction, closed with `{==}` — **easy**, verified |
| associativity / commutativity of `Nat.add` | one induction each (associativity is `add_assoc` in `LIFE_PAR_PROOF.bend`) |
| `m + r == B` ⟹ `Nat.mod.fin(Nat.divmod.go(n,m,d,r)) < B + 1` | induction on `n` plus inner branches; **the exit branch needs `r ≤ m + r`, a two-variable induction through `Nat.cmp`** |
| `a < h` and `b < w` ⟹ `a*w + b < h*w` | distributivity of `Nat.mul` plus monotonicity of `Nat.cmp`, several more inductions |

**Bend has no tactics, and Base has no lemma library** — so any law touching
`Nat.mod` / `Nat.mul` / `Nat.cmp` has to bring its own small arithmetic.

That is not a defect in Bend; it is its positioning. It is a specification language for
AI to write in, and the lemma library has not been written yet (Bend's own README says
its Lean formalisation lags the TypeScript implementation). But it does change **which
law to pick next** — the closer to arithmetic, the worse the deal.

**A second data point (`LIFE_ANIM`'s law): `String` has no lemmas either.** Base does
not even have `append(a, SNil) == a`. But the two library taxes differ by an order of
magnitude in **difficulty**: the `String` lemmas are plain structural induction
(`append` matches on its first argument, so one induction finishes it), while the `Nat`
set has to go through `Nat.cmp`, which is a two-variable induction. The same wall — one
side is an afternoon's work, the other is not.

## `life_anim` — making it move

`life_row.bend`'s engine, moved across unchanged (that part is O(n), and a 40×16 grid
barely notices), wrapped in a `do IO`: draw a frame → `IO.sleep(70)` → compute the next
generation. Ordinary IO recursion, with the shrinking parameter (generations remaining)
leftmost.

Three behaviours are placed in the grid, one each, so they are distinguishable at a glance:

| Pattern | Behaviour |
|---|---|
| glider (left) | translates one cell down-right every 4 generations |
| blinker (upper right) | horizontal ↔ vertical, period 2, in place |
| block (lower right) | static |

Rendering a frame has two traps, both of which we hit:

**① Do not clear the whole screen.** Move the cursor back to the top left with
`\u{1B}[H` and redraw; that does not flicker. A full `[2J` does.

While you are here: Bend's string escapes are **only**
`\n \t \r \0 \\ \' \" \u{...}` — **there is no `\e` and no `\x1b`**, so ESC has to be
written `\u{1B}`. (Getting this wrong has a helpful error: it lists every escape that
does exist.)

**② `String.reverse` reverses *characters*, not *cells*.**

To avoid an O(n²) chain of `append`s, the renderer accumulates backwards and flips the
whole thing once at the end. We initially flipped at **both** the row level and the
whole-frame level, so every row was flipped one time too many — the symptom was
**y coordinates entirely correct, x becoming `39-x`, the whole pattern mirrored
left-to-right**. Now the frame is flipped exactly once.

The price is that **every cell must be a palindrome** (`"██"` and `"  "` both are).
Swap in a non-palindromic cell like `"▐█"` and each row flips inside out — measured: a
4×4 glider renders as `OXOX][][` / `][][OX][` instead of `[]XO[][]` / `[][]XO[]`.

**The mechanism** (written out because we reasoned it backwards once): `rowrev` does
`append(cell(h), acc)` — it reverses **the order of cells and touches no character
inside a cell** — while the frame's final flip is over **characters**. Composing the two
gives

```
reverse (rowrev r) == map reverse (map cell r)
```

so a row only comes out right when **each cell equals its own character reversal**. A
palindrome is not a caution; it is the **precondition** of the "flip the frame once"
O(frame-length) optimisation — and that precondition is now machine-enforced by
`LIFE_ANIM_PROOF.bend` (below).

## Law two — `LIFE_ANIM_LAWS.bend` / `LIFE_ANIM_PROOF.bend`

The proposition in one line: **the fast render equals the slow, obviously-correct one.**

```python
def spec_row(+r) -> String      # one row of cells → string, a plain chain of appends
def spec_rows(+rs) -> String    # the whole frame, a plain chain of appends

law frame_is_spec:
  for +rs: Rows
  {Anim.frame(rs) == String.append("\u{1B}[H", spec_rows(rs)) : String}
```

That "every cell must be a palindrome" constraint **is part of the theorem, not a
comment**: the proof contains a `cell_pal` lemma, which is simultaneously why the whole
law holds.

### Verify the proposition before proving it

Proving a false law is proving a lie. So before starting, a brute-force check was run:
`frame(rs)` and `String.append(ESC, spec_rows(rs))` compared character by character over
5 grids (4×4, 16×16, 40×16, the last also after 40 generations of evolution) — all equal,
and the lengths matched too (40×16 → 3 + 16×(80+1) = 1299, since that ESC is 3 characters
rather than 1).

### Shape and cost

Seven lemmas, of which **five are standard-library lemmas Base is missing** and only two
belong to this law:

| Lemma | Who needs it |
|---|---|
| `append_nil2` / `append_assoc2` | Base is missing it |
| `reverse_go_spec` / `reverse_append2` | Base is missing it (`reverse` is accumulator-style and sticks on the variable) |
| `pick_pal` / `cell_pal` | Base is missing it — **this one is the palindrome constraint itself** |
| `rowrev_spec` | the law's own: `reverse(rowrev(r, acc))` == this row's cells followed by the reversed `acc` |
| `inner` + `frame_is_spec` | the law's own: an accumulator invariant over `Rows` |

### Two things to know when writing them

- **What a rewrite annotation means:** the `P` in `%lem(args) : P` is the goal **before**
  the rewrite, and `_` marks **the lemma's right-hand side (the term being consumed)**.
  So a lemma has to be written `{the goal's form == the form currently appearing in the
  goal}`. Get the direction wrong and `%` reports "expected / observed" clearly enough —
  but not knowing this up front cost three collisions.
- **A parameter modifier follows usage, not meaning:** a parameter that only appears in
  the type is `-`; one the **proof body** uses more than once must be `+`.
  `reverse_go_spec`'s `acc` looks like it should be "erased", but it appears in the
  recursive call, so it is `+acc`.

### What this gate stops

The breakage goes in the **implementation** file `life_anim.bend`:

| Change | `bend LIFE_ANIM_PROOF.bend` |
|---|---|
| drop `frame`'s final `String.reverse` (rows come out in reverse order) | **Error** |
| flip each row one extra time (the original mirroring bug) | **Error** |
| make `cell` the non-palindrome `"▐█"` | **Error** |
| unchanged | `All terms check.` |

The second is worth a second look: **the mirroring bug that was once found by eye is now
caught at compile time.**

#### ⚠️ But the breakage test itself has fooled us twice

**Neither of these was ever written to disk; they lived only in conversation, so they are
recorded here.**

The shape of a breakage test is "change one thing → run the gate → see whether it
complains". It has a lethal failure mode: **the replacement does not match, the file does
not change by a single byte, and the gate prints `All terms check.`** — a symptom
indistinguishable from "the gate is broken". Both times, that is what happened:

**The first time:** the change belonged in the implementation file `life_par.bend`, but we
edited the spec file `LIFE_PAR_LAWS.bend`; and the string being replaced did not exist in
the spec at all, so the substitution silently matched nothing.

**The second time (2026-09-18):** replacing `"██"` with the non-palindrome `"▐█"` to test
`LIFE_ANIM_PROOF`. `"██"` occurs twice in `life_anim.bend` — once in the implementation of
`cell`, and **once in the comment above it explaining the palindrome constraint**, which
comes first. The replacement landed on the comment; the code never moved.

So the rule is now hard: **`assert s.count(old) == 1` before any replacement — only a
unique match counts.** Only anchors that match exactly once give a result worth believing.

`src/laws-1.md` and `src/laws-2.md` record this too, because it is the other half of "All
terms check is not evidence": **a breakage that never landed is a verification that never
happened.**

## Running

```sh
bend life.bend                      # 8×8, prints every generation

bend life_anim.bend                 # terminal animation (320 generations × 70 ms ≈ 22 s)

bend life_par.bend -o life_par      # parallelism needs a native build
./life_par --threads 4

bend life_row.bend -o life_row
./life_row --threads 1

bend life_rowpar.bend -o life_rowpar
./life_rowpar --threads 4

bend LIFE_PAR_PROOF.bend                # proof gate: prints All terms check.
bend LIFE_ANIM_PROOF.bend               # the same, for the animation
```

The animation's length and speed are two edits at the end of `life_anim.bend`: the first
argument of `loop(320n, ...)`, and the `IO.sleep(70)` inside `loop`. Both backends can run
it; the native build was measured to be **streaming** (2 s → 39 KB, 4 s → 77 KB), not
buffering everything until the end.

Book: chapters 15–20.
