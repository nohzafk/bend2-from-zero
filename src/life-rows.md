# Life in O(n), by rows

The previous chapter ended on the diagnosis: the cost is not the rule, and not
the neighbour sum — it is **computing an index at all**. So the fix is to stop
indexing.

Which raises the question of how you read a cell's neighbours without jumping to
them. The answer is the one this chapter is named after.

## The trick: add the three rows, then take a window

A cell's eight neighbours are the 3×3 block around it, minus the centre. So the
block is what has to be computed, and there are nine cells in it.

Take the three rows involved — the one above, the one at, the one below — and add
them together position by position, producing one new row `s` of the same width as
a row:

```
s[j] = prev[j] + cur[j] + next[j]
```

**`s[j]` holds three cells, not a whole board column.** This is the part that
reads wrong at first, so it is worth being blunt about: on a 17×17 board the
board's own columns are 17 cells tall, and *none of those are summed anywhere*.
The rows of the board are 17 cells wide, and `s` has 17 entries — one per
position along a row — but each entry is the sum of the three cells at that
position in the three-row window.

Why three rows and no more? Because neighbours are within one row. The
neighbours of a cell in row `y` live in rows `y-1`, `y` and `y+1` and in no
others, so the other rows of the board cannot contribute:

```
row y-2  ────────────────  not a neighbour of anything in row y
row y-1  ┐
row y    ├─  the three-row window  →  s = prev + cur + next
row y+1  ┘
row y+2  ────────────────  not a neighbour of anything in row y
```

That is why the board's height never appears in what follows. It is not that the
formula is clever enough to avoid `h`; it is that `h` was never in the question.
A cell has eight neighbours whether the board is 17 rows tall or 17,000.

Now look at what a 3×3 block is made of. Every cell around `(x, y)` sits in one of
three columns — `x-1`, `x` or `x+1` — and `s[j]` already holds all of **the
window's** column `j`, which is three cells: one from each of the three rows. So
the three entries add up to the whole block:

```
s[x-1] + s[x] + s[x+1]    =     all nine cells of the 3×3 block
```

The centre is among those nine, and it appears **once**: `cur[x]` is counted in
`s[x]` and in neither of the other two, because each `s[j]` covers a different
column. Subtract it and the eight neighbours are what is left:

```
neighbours(x) = s[x-1] + s[x] + s[x+1] - cur[x]
```

Nine cells, three arithmetic operations. Concretely, on a five-cell row:

```
prev    1  1  0  0  1
cur     1  0  1  0  1
next    0  1  1  1  0
        ----------------
s       2  2  2  1  2      s[j] = prev[j] + cur[j] + next[j]
```

For `x = 2`: `s[1] + s[2] + s[3] - cur[2]` is `2 + 2 + 1 - 1 = 4`. Count the
blocks by hand and you get the same: column 1 contributes `1+0+1 = 2`, column 2
contributes `0+1+1 = 2`, column 3 contributes `0+0+1 = 1`, nine cells totalling
5 — and the centre, `cur[2] = 1`, is not a neighbour, so 4.

**So: does the board size matter?** Not to the formula, and not to the eight. The
eight comes from the definition of a neighbour — the 3×3 block minus the centre —
and every cell has exactly those eight offsets in the three-row window, whatever
`w` and `h` are. Size enters only *where* the window's three columns fall once the
board wraps, which is why this chapter's remaining work is rotations, not
arithmetic. Even a board narrower than three changes nothing: the three columns
then coincide and the equation counts the same cells on both sides.

And the whole thing is a **walk**: four lists moving together, one position at a
time. No index is ever computed, so no list is ever traversed twice.

That is the entire optimisation. Everything below is bookkeeping to make the walk
work at the edges and between rows.

## Walking in circles

The world wraps, so the rows have to rotate. Rotating a list by one position is
cheap — move the head to the end:

```python
def rot_l(+xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      app(t, Con{h, Nil{}})

def rot_r(+xs: List<&2, Nat>) -> List<&2, Nat>:
  rev(rot_l(rev(xs, Nil{})), Nil{})
```

`rot_r` is defined as *reverse, rotate left, reverse again* rather than as its own
recursion. That keeps one rotation primitive to get right, and both are O(w) — a
pass over the row, which is the same order as the pass we are already doing.

Both are used in `newrow`, the function that produces one new row:

```python
def newrow(+p: List<&2, Nat>, +c: List<&2, Nat>, +n: List<&2, Nat>) -> List<&2, Nat>:
  +s = colsum(p, c, n, Nil{})
  rowstep(rot_r(s), s, rot_l(s), c, Nil{})
```

`rot_r(s)` is `s` shifted so that position `x` holds `s[x-1]`; `rot_l(s)` holds
`s[x+1]`. Three lists, same length, walked in lockstep — `s[x-1]`, `s[x]`, `s[x+1]`
are simply the current heads.

## Rows themselves rotate

The same problem one level up. To produce row `y` you need rows `y-1`, `y` and
`y+1`, and the grid is a list of rows — so the row list has to rotate too.

```python
def gen(+a: Rows) -> Rows:
  zip3(rows_rotm1(a), a, rows_rot1(a))
```

`zip3` walks the three staggered row lists together, one row from each per step,
and calls `newrow`. Note what this means: **the grid is never indexed, at either
level.** Not horizontally within a row, not vertically across rows. The whole
generation is one walk of a structure that is already in the right order.

`Rows` is its own type, because a list of lists needs a name:

```python
type Rows is Data:
  RNil{}
  RCons{row: List<&2, Nat>, tail: Rows}
```

## The result

Sixty-four generations, single thread:

| grid | cells | total | **ns per cell, per generation** |
|---|---|---|---|
| 32×32 | 1,024 | 4 ms | **61** |
| 64×64 | 4,096 | 17 ms | **65** |
| 128×128 | 16,384 | 70 ms | **67** |
| 256×256 | 65,536 | 308 ms | **73** |

Compare the last column with the previous chapter's:

| | 32×32 | 64×64 |
|---|---|---|
| naive | 30,900 ns | 123,800 ns |
| **row window** | **61 ns** | **65 ns** |

The naive column multiplies by four when the grid does. This one does not move.
**Sixty-four times more cells for sixty-four times more time — that is what O(n)
looks like**, and the flat right-hand column is the evidence.

## The head-to-head

Both versions, 64×64, sixteen generations, **one thread each**:

| | ms |
|---|---|
| naive (`life_par.bend` with `d=0`, no fork at all) | 8,114 |
| row window (`life_row.bend`) | **5** |

**Roughly sixteen hundred times.** Neither version used more than one core.

A caveat on that ratio, since it is the headline number of this chapter. `IO.now()`
has **one-millisecond resolution**, so the divisor — 5 ms, and sometimes 4 — is
three or four ticks wide. Measured across sessions the row-window side reads 4 or
5 ms and the ratio moves between about 1,600× and 2,000×. The order of magnitude
is solid; the third significant figure is not. Every `ns` column in this chapter
is subject to the same thing, which is why the 32×32 row is the least trustworthy
one — it is four ticks total.

This is the number worth carrying away from the whole Performance part of the
book. Ten cores bought about 3× in the last chapter. Changing the algorithm bought
about 2,000×, from the same programmer, in the same language, on the same
afternoon.

Put the two side by side and the ordering is unambiguous — the *parallel* naive
version, on ten cores, at 4 generations, is still 676 ms. The *serial* row-window
version does 16 generations in 4 ms. **Parallelism is a multiplier on an
algorithm. It does not choose one for you.**

## A note on what was traded

The row-window version is not free. It is longer, it needs `Rows` and its own
append and reverse, and it depends on a mathematical identity that is not obvious
at a glance. Someone reading `colsum` for the first time will not see Life in it.

That is the honest cost of the 2,000×: the fast version is a rewrite, not a
tuning pass. What makes it defensible is that the rewrite is checkable — the
equality of this engine with the naive one is a law with a proof, in the last part
of this book.

## The file

```sh
bend life_row.bend -o life_row
./life_row --threads 1
```

Next: [the naive engine, parallelised, and why the honest answer is "it
depends"](life-parallel.md).
