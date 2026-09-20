# Life in O(n), by rows

The previous chapter ended on the diagnosis: the cost is not the rule, and not
the neighbour sum — it is **computing an index at all**. So the fix is to stop
indexing.

Which raises the question of how you read a cell's neighbours without jumping to
them. The answer is the one this chapter is named after.

## The block, without indexes

Start from the target. A cell's neighbours are the eight cells around it — the
3×3 block centred on it, minus the centre itself:

```
         x-1   x    x+1
  y-1     ·    ·     ·
   y      ·    ▣     ·      eight of these nine cells are neighbours
  y+1     ·    ·     ·      ▣ is the cell itself, and is not a neighbour
```

Nine cells. The previous chapter's problem was reaching them: by index, each one
costs a walk down the list. So the question for this section is how to add up
nine cells that lie in three columns and three rows, without ever naming an
index.

The first thing to notice is how small that block is vertically.

### Three rows are enough

Every cell of the block is in row `y-1`, row `y` or row `y+1`. Nothing in row
`y-2` is a neighbour of anything in row `y`, and neither is anything in `y+2`:

```
row y-2  ────────────────  no cell here is a neighbour of row y
row y-1  ┐
row y    ├─  every cell of the block is in these three rows
row y+1  ┘
row y+2  ────────────────  no cell here is a neighbour of row y
```

That is the whole reason the board's height never enters this chapter again. It
is not that the trick is clever enough to avoid `h`; `h` was never in the
question. A cell has eight neighbours whether the board is 17 rows tall or
17,000.

### Adding those three rows into one

Three rows, then, and the move is to combine them before anything else. Add them
together position by position, producing one scratch row `s`:

```python
s[j] = prev[j] + cur[j] + next[j]
```

Two names in that line, before anything else:

- **`j` is a column position** — an offset along a row, counting from `0` to
  `w-1`. This chapter is about positions along a row.
- **`s` is a derived row** — scratch space, one row long, holding what the
  three rows add up to.

The line reads: at each position `j`, take the cell from each of the three rows
and add them. One number comes out, and these three went in:

```
      prev[j]  ·      ┐
      cur[j]   ·      ├─── add ───▶  s[j]       one number, three cells behind
      next[j]  ·      ┘
```

Do that at every position and you have a row of such numbers — as wide as a row,
one entry per column position:

```
                  j=0  j=1  j=2        j=16        (w = 17)
   prev (row y-1)   ·    ·    ·          ·
   cur  (row y  )   ·    ·    ·    ...   ·          three rows of w cells
   next (row y+1)   ·    ·    ·          ·
                    │    │    │          │
                    ▼    ▼    ▼          ▼
   s                ▪    ▪    ▪    ...   ▪          w cells of three each
                  j=0  j=1  j=2        j=16
```

`colsum` is that line, written as the walk it has to be:

```python
{{#include ../life/life_row.bend:77:92}}
```

All three rows are matched at once, so the three lists are consumed in lockstep:
`hp`, `hc` and `hn` are the three cells at the current position, and the recursive
line appends exactly one entry — `hp + hc + hn` — to the accumulator. Nothing is
indexed; the position is simply wherever the walk has got to.

### The three-cell window

Now look at what a 3×3 block is made of. Every cell around `(x, y)` sits in one of
three columns — `x-1`, `x` or `x+1` — and `s[j]` already holds all of **the
window's** column `j`, which is three cells: one from each of the three rows. So
the three entries add up to the whole block:

```python
s[x-1] + s[x] + s[x+1]    =     all nine cells of the 3×3 block
```

The centre is among those nine, and it appears **once**: `cur[x]` is counted in
`s[x]` and in neither of the other two, because each `s[j]` covers a different
column. Subtract it and the eight neighbours are what is left:

```python
neighbours(x) = s[x-1] + s[x] + s[x+1] - cur[x]
```

Nine cells, three arithmetic operations.

### Worked example

On a real 17-wide board, so the whole row is visible at once:

```
prev (row y-1)   0 0 1 1 0 0 1 1 0 0 1 1 1 0 0 0 1
cur  (row y  )   0 0 0 0 1 0 1 1 1 1 1 1 0 1 0 0 0
next (row y+1)   1 0 1 1 1 1 1 1 1 0 1 0 1 0 1 0 0
                 ---------------------------------
s                1 0 2 2 2 1 3 3 2 1 3 2 2 1 1 0 1
```

Seventeen entries in `s`, one per column position, and the largest entry is `3` —
because three rows went into it and there is nothing else for it to hold.

For `x = 2`: `s[1] + s[2] + s[3] - cur[2]` is `0 + 2 + 2 - 0 = 4`. Count the nine
cells by hand and it agrees: column 1 is `0+0+0 = 0`, column 2 is `1+0+1 = 2`,
column 3 is `1+0+1 = 2`, so the block totals 4 — and the centre, `cur[2] = 0`, is
not one of its own neighbours.

### Does the board size matter?

Not to the formula, and not to the eight. The eight comes from the definition of
a neighbour — the 3×3 block minus the centre — and every cell has exactly those
eight offsets in whichever three rows the window is on, whatever `w` and `h` are.
Size enters only *where* the window's three columns fall once the board wraps,
which is why this chapter's remaining work is rotations, not arithmetic. Even a
board narrower than three changes nothing: the three columns then coincide and
the equation counts the same cells on both sides.

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
