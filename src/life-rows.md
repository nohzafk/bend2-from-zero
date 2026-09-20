# Life in O(n), by rows

The [previous chapter](life-naive.md) measured the obvious engine and found where
the time goes: not the rule, and not the neighbour sum, but **reaching a cell at
all**. `nth` walks a
list one step per position, so a cell costs what its index costs — and every cell
needs eight neighbours read, each read starting from the head of the list.

This chapter removes the index.

## The plan: two passes, not one box

The neighbours are the 3×3 box around the cell, minus the centre: nine cells to
account for.

A box does not have to be summed in one go. It is three columns, and it is also
three rows, and either way it comes apart into two one-dimensional passes — first
collapse three rows into one number per column, then add three neighbouring
numbers:

```
    3×3 box   ──▶   3 numbers   ──▶   1 number
              three rows per     three columns,
              column              one window
```

Each pass is a walk: position by position, no jumps. That is the whole idea, and
the rest of this chapter is the two passes and what they need at the edges.

One consequence is worth stating before any of it, because it is the thing that
looks wrong at first: **the intermediate row holds one number per column** — `w`
of them, not `w × h`. By the time the second pass runs, each column has already
collapsed into a sum, and a sum is all the second pass wants.

The order is bookkeeping, not correctness. Rows first needs one scratch row;
columns first would need three.

## Pass one: three rows into one

The cell is `(x, y)`, with `x` counting along a row and `y` counting rows. This
chapter builds **one output row at a time** — call it `y` — so `y` is fixed and `x`
ranges along the row. Doing it for every row is [the row rotation](#rows-themselves-rotate),
later on.

Only three rows can matter, because a neighbour is never further than one row away:

```
row y-2  ────────────────  no neighbour of row y lives here
row y-1  ┐
row y    ├─  every neighbour of a cell in row y is in these three rows
row y+1  ┘
row y+2  ────────────────  no neighbour of row y lives here
```

So the height of the board never comes up again. Not because the trick avoids `h`,
but because `h` was never part of the question: a cell has eight neighbours whether
the grid is 17 rows tall or 17,000.

Add those three rows, position by position, into a scratch row `s_y`:

```python
s_y[x] = prev[x] + cur[x] + next[x]
```

- `prev`, `cur` and `next` are rows `y-1`, `y` and `y+1` — three different rows, the
  same column. They differ in `y`, not in `x`, and each is a `List<Nat>` of length `w`.
- `s_y` is a `List<Nat>` of length `w`: one entry per column.
- `s_y[x]` is a single `Nat` — three cells added into one number.

Six columns, so the whole window fits on the page. The boards measured below are far
bigger; the width changes nothing:

```
          x=0  x=1  x=2  x=3  x=4  x=5
prev        0    1    0    0    1    0
cur         1    0    1    1    0    0
next        0    0    1    0    1    1
            │    │    │    │    │    │      one column at a time:
            ▼    ▼    ▼    ▼    ▼    ▼      0+1+0, 1+0+0, 0+1+1, ...
s_1         1    1    2    1    2    1
```

`s_1[2] = prev[2] + cur[2] + next[2] = 0 + 1 + 1 = 2`. No entry can exceed 3, because
three cells go into it.

**There is one `s_y` per output row**, and the inputs change with the row, so every
entry changes with it. Add a fourth row to the same board:

```
   row 0   0 1 0 0 1 0        s_1 = 1 1 2 1 2 1      from rows 0+1+2
   row 1   1 0 1 1 0 0        s_2 = 2 1 2 2 1 2      from rows 1+2+3
   row 2   0 0 1 0 1 1
   row 3   1 1 0 1 0 1
```

Two different lists, both correct, each the three-row window of its own row. The
code names it `s`, because inside one call to `newrow` there is only ever one; this
chapter writes `s_y` because it looks at more than one.

`colsum` is that formula written as the walk it has to be:

```python
{{#include ../life/life_row.bend:77:92}}
```

All three rows are matched at once, so the three lists are consumed in lockstep:
`hp`, `hc` and `hn` are the three cells at the current position, and the recursive
line appends one entry — `hp + hc + hn` — per position. No position is ever
computed; the position is wherever the walk has got to.

## Pass two: a three-wide window

Same output row, so still the same `s_y`. The block's three columns are `x-1`, `x`
and `x+1`, and each of them is already one entry:

```
   s_y[x-1]  =  prev[x-1] + cur[x-1] + next[x-1]     the block's left column
   s_y[x]    =  prev[x]   + cur[x]   + next[x]       the middle column
   s_y[x+1]  =  prev[x+1] + cur[x+1] + next[x+1]     the right column
```

A 3×3 block is three columns and nothing else, so those three entries are the whole
block. Exactly one of the nine cells is the cell itself — `cur[x]`, which sits
inside `s_y[x]` and in neither of the others — so it comes off once:

```python
s_y[x-1] + s_y[x] + s_y[x+1]              =   all nine cells of the block
s_y[x-1] + s_y[x] + s_y[x+1] - cur[x]     =   the eight neighbours
```

On the same example, for the cell at `x = 2`:

```
   column 1:  prev[1]=1  cur[1]=0  next[1]=0     s_1[1] = 1
   column 2:  prev[2]=0  cur[2]=1  next[2]=1     s_1[2] = 2     ← cur[2] is the cell
   column 3:  prev[3]=0  cur[3]=1  next[3]=0     s_1[3] = 1
                                              ─────────────
                                nine cells  =  1 + 2 + 1  =  4
                 minus the cell itself, cur[2] = 1   →   3 neighbours
```

That is the neighbour count. Turning the count into the next state is the rule,
three lines:

```python
{{#include ../life/life_row.bend:39:41}}
```

and the whole of pass two is one line of `rowstep`, which walks a row applying it:

```python
{{#include ../life/life_row.bend:115:118}}
```

`hl`, `hs` and `hr` are the three heads of the three window lists — that is
`s_y[x-1]`, `s_y[x]` and `s_y[x+1]` — and `hc` is `cur[x]`.

Nine cells, three additions and a subtraction, and the board's size never entered
it: eight neighbour offsets always fall in three rows and three columns, whatever
`w` and `h` are. Size decides only *where* those columns land once the board wraps —
which is what the rest of this chapter is about.

## Why the passes have to be walks

`nth` costs one step per position, which is why the naive engine is quadratic: eight
walks per cell, each up to `w × h` steps long. Count what this version does instead.
`colsum` visits every cell once and adds it. `rowstep` visits every cell once and
does four operations there. So a cell costs a constant number of list steps rather
than a walk to its position:

```
naive    n cells × 8 walks of up to n steps    →  O(n²)
this     n cells × a constant number of steps  →  O(n)
```

That is why both passes are written as walks rather than as index arithmetic.
Neither of them computes a position — they advance three or four lists together, and
the position is wherever the walk has got to.

The rotations below are what it costs, and they are the honest part of the trade.
Each traverses a whole row, so a generation pays O(w) per row — O(n) across the grid,
the same order as the pass it enables. Buying an O(n) pass with an O(n) pass is a
good trade; the alternative was an O(n) walk inside every cell, once per neighbour.

## Walking in circles

The world wraps, so the window has to slide round the end of a row and back to the
start. Rotating a list by one position is cheap — move the head to the end:

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
recursion: one rotation primitive to get right, and both are O(w).

`newrow` is one output row's worth of work, and it is the two passes in four lines:

```python
def newrow(+p: List<&2, Nat>, +c: List<&2, Nat>, +n: List<&2, Nat>) -> List<&2, Nat>:
  +s = colsum(p, c, n, Nil{})
  rowstep(rot_r(s), s, rot_l(s), c, Nil{})
```

Build `s`, then hand `rowstep` three staggered copies of it: `rot_r(s)` holds
`s_y[x-1]` at position `x`, `rot_l(s)` holds `s_y[x+1]`. Four lists of the same
length — the three window lists and `cur` — walked in lockstep, so the three terms
of the formula are simply the three heads. The window slides by walking; no rotation
is ever undone and no position is ever computed.

## Rows themselves rotate

The same problem one level up. To produce row `y` you need rows `y-1`, `y` and
`y+1`, and the grid is a list of rows — so the row list rotates too:

```python
def gen(+a: Rows) -> Rows:
  zip3(rows_rotm1(a), a, rows_rot1(a))
```

`zip3` is what walks them:

```python
{{#include ../life/life_row.bend:125:138}}
```

It takes one row from each of the three staggered lists per step and calls `newrow`
— one call, and therefore one `s_y`, per output row. **The grid is never indexed, at
either level**: not horizontally within a row, not vertically across rows. A whole
generation is two walks of structures that are already in the right order.

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

Next: the naive engine, parallelised, and why the honest answer is "it
depends".
