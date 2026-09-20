# Life in O(n), by rows

The previous chapter ended on a diagnosis. The cost is not the rule, and not the
neighbour sum: it is **computing an index at all**. `nth` walks a list one step per
position, so reading a cell costs as many steps as the cell's index is large — and
the naive engine reads eight cells for every cell of the grid.

This chapter removes the index. The neighbours of a cell are found by walking the
three rows it can see, never by asking for a position.

## Two windows, in two directions

The board is `h` rows of `w` cells. A cell is `(x, y)`, where **`x` counts along a
row** (`0` to `w-1`) and **`y` counts rows** (`0` to `h-1`). This chapter builds one
output row at a time — call it `y` — from the three rows it can see. Doing that for
every row is [the row rotation](#rows-themselves-rotate), later on.

Two windows are used here, and they run in **different directions**:

- **across rows** — `y-1`, `y`, `y+1`: three rows, at the same column;
- **along a row** — `x-1`, `x`, `x+1`: three columns, in the same row.

The whole trick is doing them one after the other. Everything below is one of the
two.

### Across rows: add the three rows into one

A cell's neighbours are the eight cells of the 3×3 block around it:

```
           x-1   x    x+1
    y-1     ·    ·     ·
     y      ·    ▣     ·      eight of these nine are neighbours
    y+1     ·    ·     ·      ▣ is the cell itself
```

Nothing in row `y-2` is a neighbour of anything in row `y`, and neither is anything
in `y+2`. So those three rows are all the input there is, and the height of the
board never comes up again — a cell has eight neighbours whether the grid is 17
rows tall or 17,000.

Add them position by position, into a scratch row `s_y` — the scratch row of
output row `y`:

```python
s_y[x] = prev[x] + cur[x] + next[x]
```

- `prev`, `cur` and `next` are the three **rows** `y-1`, `y`, `y+1`. They differ in
  `y`, not in `x`; each is a `List<Nat>` of length `w`.
- `x` is a position **along** a row, the same `x` as above. `prev[1]` and `cur[1]`
  are in different rows and the same column.
- `s_y` is a `List<Nat>` of length `w` — the scratch row for this output row.
- `s_y[x]` is a single `Nat`: three cells added into one number.

The subscript is the whole point: **`s_y` is the scratch row of one output row**,
and the code has one per call, so there is no bare `s` to speak of. The code itself
names it `s`, because inside `newrow` there is only ever one; this chapter writes
`s_y` because it looks at more than one.

**`s_y` is a row; `s_y[x]` is a number.** The `+` is ordinary addition of `Nat`s —
nothing here adds two lists, because there is no such operation in Bend. The three
numbers at column `x` are added, then the same is done at column `x+1`. (A
different `+` shows up in the code further down: the reuse mark from the affinity
chapters. It is labelled where it arrives.)

Six columns, so the whole window fits on the page. The boards measured below are
much bigger, but the width changes nothing here:

```
          x=0  x=1  x=2  x=3  x=4  x=5
prev        0    1    0    0    1    0
cur         1    0    1    1    0    0
next        0    0    1    0    1    1
            │    │    │    │    │    │      each column added on its own:
            ▼    ▼    ▼    ▼    ▼    ▼      0+1+0, 1+0+0, 0+1+1, ...
s_1         1    1    2    1    2    1
```

`s_y[2] = prev[2] + cur[2] + next[2] = 0 + 1 + 1 = 2`. No entry can exceed 3, because
three cells go into it.

The table above is the window for `y = 1` — rows 0, 1 and 2 standing as `prev`, `cur`
and `next`. Add a fourth row and build `y = 2` as well:

```
   row 0   0 1 0 0 1 0       s_1 = 1 1 2 1 2 1      from rows 0+1+2
   row 1   1 0 1 1 0 0       s_2 = 2 1 2 2 1 2      from rows 1+2+3
   row 2   0 0 1 0 1 1
   row 3   1 1 0 1 0 1
```

`s_1` and `s_2` are different lists, because their inputs are different rows. Both
are correct, each as the three-row window of its own row.

Which is why the two phases are done **for one fixed `y`**: build `s_y`, then walk
`s_y`. Advancing `y` builds the next row's scratch from the next three rows, which
is what [the row rotation](#rows-themselves-rotate) is for.

`colsum` is that line written as the walk it has to be:

```python
{{#include ../life/life_row.bend:77:92}}
```

All three rows are matched at once, so the three lists are consumed in lockstep:
`hp`, `hc` and `hn` are the three cells at the current position, and the recursive
line appends one entry — `hp + hc + hn` — per position. No position is ever
computed; the position is wherever the walk has got to.

### Why one scratch row is enough

`s_y` is one-dimensional: `w` numbers, and its length does not depend on `h`. It is
enough because a 3×3 sum **factors**. The block is three columns by three rows, and
a rectangle of cells can be summed one axis at a time, either axis first:

```
   the 3×3 block   =   three columns,   each already summed down its three rows
                   =   three rows,      each already summed along its three columns
```

The pass across rows compresses each column's three cells into one number; the pass
along a row then adds three of those numbers. The second pass only ever wants sums,
so nothing it needs was thrown away by the first.

The order is not arbitrary: summing the rows first needs **one** scratch row,
summing the columns first would need three.

### Along a row: three entries of `s`

The other direction — and still the same `y`, so still the same `s_y`. `s_y[x-1]`,
`s_y[x]` and `s_y[x+1]` are three **columns**, in the same row of `s_y`, and each
entry already holds one whole column of the block:

```
   s_y[x-1]  =  prev[x-1] + cur[x-1] + next[x-1]     the block's left column
   s_y[x]    =  prev[x]   + cur[x]   + next[x]       the middle column
   s_y[x+1]  =  prev[x+1] + cur[x+1] + next[x+1]     the right column
```

A 3×3 block is three columns and nothing else, so those three entries are the whole
block. Exactly one of the nine cells is the cell itself — `cur[x]`, which sits
inside `s_y[x]` and in neither of the others — so it comes off once:

```python
s_y[x-1] + s_y[x] + s_y[x+1]              =   all nine cells
s_y[x-1] + s_y[x] + s_y[x+1] - cur[x]     =   the eight neighbours
```

The same example, for the cell at `x = 2`:

```
   column 1:  prev[1]=1  cur[1]=0  next[1]=0     s_1[1] = 1
   column 2:  prev[2]=0  cur[2]=1  next[2]=1     s_1[2] = 2     ← cur[2] is the cell
   column 3:  prev[3]=0  cur[3]=1  next[3]=0     s_1[3] = 1
                                              ─────────────
                                nine cells  =  1 + 2 + 1  =  4
                 minus the cell itself, cur[2] = 1   →   3 neighbours
```

That gives the count. Turning the count into the next state is the rule, three
lines:

```python
{{#include ../life/life_row.bend:39:41}}
```

and the formula above is one line of `rowstep`, which walks a row applying it:

```python
{{#include ../life/life_row.bend:115:118}}
```

`hl`, `hs` and `hr` are the three heads of the three rotated `s_y` lists — that
is `s_y[x-1]`, `s_y[x]` and `s_y[x+1]` — and `hc` is `cur[x]`.

Nine cells, three additions and a subtraction, no index anywhere. And the board's
size never entered it: eight neighbour offsets always fall in three rows and three
columns. Size decides only *where* those columns land once the board wraps, which
is why the rest of this chapter is rotations rather than arithmetic.

## What that saves

The identity is half of it. This is what it buys.

A list in Bend is a chain, and `nth` walks it. The previous chapter's numbers show
a per-cell cost that grew with the grid: the grid grew fourfold, and so did the
cost of reaching one cell — eight walks per cell, each starting from the head.
Count what this version does instead. `colsum` visits every cell once and adds it.
`rowstep` visits every cell once, and does three additions and a subtraction there.
A cell therefore costs a constant number of list steps rather than a walk to its
position:

```
naive    n cells x 8 walks of up to n steps    ->  O(n^2)
this     n cells x a constant number of steps  ->  O(n)
```

The rotations that the next two sections build are what that costs, and they are
the honest part of the trade. Each one traverses a whole row, so a generation pays
O(w) per row — O(n) across the grid, the same order as the pass it enables. Buying
an O(n) pass with an O(n) pass is a good trade. The alternative was an O(n) walk
*inside* every cell, once per neighbour, which is what made the naive version
quadratic.

The flat `ns` column in the results below is the measurement of exactly this.

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
pass over the row, the same order as the pass we are already doing.

`newrow` is one output row's worth of work: it builds `s_y` and walks it. Here is
the whole function — the code calls the scratch row `s`, as promised above:

```python
def newrow(+p: List<&2, Nat>, +c: List<&2, Nat>, +n: List<&2, Nat>) -> List<&2, Nat>:
  +s = colsum(p, c, n, Nil{})
  rowstep(rot_r(s), s, rot_l(s), c, Nil{})
```

**The `+` marks in that listing are not additions.** They are the affinity
chapter's *reuse* mark, and they say something about how often a value is used —
`+p` means the caller's row may be used more than once, and `+s` means the scratch
row may. It needs to be, because the next line uses `s` three times, in `rot_r(s)`,
`s` and `rot_l(s)`. Take the `+` off and the checker refuses the line with
`expected : s` / `observed : s (consumed more than once)`.

So `+` means two different things in this code, and where it sits is what tells
them apart: **in front of a name being bound or declared it is the reuse
mark; between two numbers it is addition** — of cell counts in the formula, and of
positions in `x-1`, `x+1` and `y*w + x`. The arithmetic in this chapter never
mixes the two.

`rot_r(s)` is `s` shifted so that position `x` holds `s[x-1]`, and `rot_l(s)` is `s`
shifted so that it holds `s[x+1]`. `rowstep` then walks the four lists — `s[x-1]`,
`s[x]`, `s[x+1]` and `cur[x]` — in lockstep, and the three terms of the formula are
simply the three heads. No rotation is ever undone and no position is ever
computed: the window slides by walking.

## Rows themselves rotate

The same problem one level up. To produce row `y` you need rows `y-1`, `y` and
`y+1`, and the grid is a list of rows — so the row list has to rotate too.

```python
def gen(+a: Rows) -> Rows:
  zip3(rows_rotm1(a), a, rows_rot1(a))
```

`zip3` is what walks them:

```python
{{#include ../life/life_row.bend:125:138}}
```

`zip3` walks the three staggered row lists together, one row from each per step,
and calls `newrow` — one `newrow` call, and therefore one `s`, per output row. Note what this means: **the grid is never indexed, at either
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
