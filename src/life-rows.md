# Life in O(n), by rows

The previous chapter ended on a diagnosis. The cost is not the rule, and not the
neighbour sum: it is **computing an index at all**. `nth` walks a list one step per
position, so reading a cell costs as many steps as the cell's index is large — and
the naive engine reads eight cells for every cell of the grid.

This chapter removes the index. The neighbours of a cell are found by walking the
three rows it can see, never by asking for a position.

## Coordinates, and one row at a time

The grid is `w` wide and `h` tall, and a cell is written `(x, y)`:

- **`x` is a column position** — how far along a row, `0` to `w-1`.
- **`y` is a row position** — which row of the grid, `0` to `h-1`.

This is the same convention the [previous chapter](life-naive.md) used, and the
reason its index was `y*w + x`. `y` is multiplied by the width because a row is
`w` cells long; `x` is the position inside that row. Walking a row means varying
`x`; walking a column means varying `y`.

The board is one `List<Nat>` holding 0s and 1s, `w × h` long, read as `h` rows of
`w` cells. Two consequences that the rest of the chapter leans on:

- **a row is a `List<Nat>` of length `w`** (so `prev`, `cur` and `next` are rows —
  lists, not numbers);
- **a cell is a single `Nat`**, either `0` or `1`.

A cell's neighbours are the eight cells around it:

```
           x-1   x    x+1
    y-1     ·    ·     ·
     y      ·    ▣     ·      eight of these nine cells are neighbours
    y+1     ·    ·     ·      ▣ is the cell itself, and is not a neighbour
```

**This chapter computes one row at a time.** Pick the row you are producing and
call it `y`; its inputs are rows `y-1`, `y` and `y+1`. From here to the end of the
mechanism, `y` stays fixed and every `x` ranges over that one row. Doing it for
every row of the grid is [the row rotation](#rows-themselves-rotate), later on.

### Three rows are enough

Why three, and not more? Because a neighbour is never further than one row away.
Nothing in row `y-2` touches row `y`, and neither does anything in `y+2`:

```
row y-2  ────────────────  no neighbour of row y lives here
row y-1  ┐
row y    ├─  every neighbour of a cell in row y is in these three rows
row y+1  ┘
row y+2  ────────────────  no neighbour of row y lives here
```

So the height of the board never comes up again. Not because the method is clever
enough to avoid `h`, but because `h` was never part of the question: a cell has
eight neighbours whether the grid is 17 rows tall or 17,000.

## Adding the three rows into one

Here is the move. Take the three rows and add them together **position by
position**, into a scratch row `s`:

```python
s[x] = prev[x] + cur[x] + next[x]
```

The `+` there is **ordinary addition of `Nat`s**. It is worth saying plainly,
because a row of numbers over another row of numbers invites a different reading:
there is no operation in this book — or in Bend — that adds two lists. What
happens is that the three *numbers* at column `x` are added, and then the same is
done at column `x+1`, and so on. One column at a time, `w` times. `s` is not
`prev + cur + next` as a single expression; there is no such expression.

(The same character will show up again in the code below meaning something else
entirely — the reuse mark from the affinity chapters. That one is labelled when
it arrives.)

Every name in that line, with what kind of thing it is:

| name | what it is | type |
|---|---|---|
| `x` | a column position — the same `x` as above | `Nat` |
| `prev`, `cur`, `next` | the three rows `y-1`, `y`, `y+1` of the board | `List<Nat>`, each `w` long |
| `s` | the scratch row | `List<Nat>`, `w` long |
| `s[x]` | one entry of the scratch row | a single `Nat` |

**`s` is a row. `s[x]` is a number.** That is the whole distinction, and it is
easy to lose: `s` is as long as a row is, so it is row-shaped, but it is not a row
of the board and its entries are not cells. Each entry is a *count* — how many of
the three cells in that column are alive. `s[2] = 2` says "two of the three cells
at column 2, in rows `y-1`, `y` and `y+1`, are alive".

Six columns, so the whole window fits on the page. The boards measured below are
much bigger — 32×32 up to 256×256 — but the width changes nothing here, and six
columns are enough to see every step of the arithmetic.

```
          x=0  x=1  x=2  x=3  x=4  x=5
prev        0    1    0    0    1    0
cur         1    0    1    1    0    0
next        0    0    1    0    1    1
            │    │    │    │    │    │      each column added on its own:
            ▼    ▼    ▼    ▼    ▼    ▼      0+1+0, 1+0+0, 0+1+1, ...
s           1    1    2    1    2    1
```

One column at a time: `s[2] = prev[2] + cur[2] + next[2] = 0 + 1 + 1 = 2`. Every
entry of `s` is at most 3, because three cells went into it and there is nothing
else for it to hold.

The code that builds `s` is `colsum`, and it is this formula turned into a walk:

```python
{{#include ../life/life_row.bend:77:92}}
```

All three rows are matched at once, so the three lists are consumed in lockstep:
`hp`, `hc` and `hn` are the three cells at the current position, and the recursive
line appends one entry — `hp + hc + hn` — to the accumulator. No position is ever
computed; the position is wherever the walk has got to.

## The neighbours are three entries of `s`

Now the point of building `s` at all. A 3×3 block is *three columns by three
rows*, and each entry of `s` is *one column by three rows*:

```
   s[x-1]  =  prev[x-1] + cur[x-1] + next[x-1]   the block's left column,  3 cells
   s[x]    =  prev[x]   + cur[x]   + next[x]     the block's middle column, 3 cells
   s[x+1]  =  prev[x+1] + cur[x+1] + next[x+1]   the block's right column,  3 cells
```

Three columns is all a 3×3 block has, so the three entries together are the whole
block:

```python
s[x-1] + s[x] + s[x+1]     =   all nine cells of the block
```

Exactly one of those nine is the cell itself: `cur[x]` sits inside `s[x]`, and it
appears nowhere else, because the other two entries are different columns. Take it
off once:

```python
neighbours(x) = s[x-1] + s[x] + s[x+1] - cur[x]        # the cell at (x, y)
```

That expression gives the neighbour count. Turning it into the cell's next state
is the rule, and the rule is three lines:

```python
{{#include ../life/life_row.bend:39:41}}
```

and the formula above is one line of `rowstep`, the function that walks a row
applying it:

```python
{{#include ../life/life_row.bend:115:118}}
```

`hl`, `hs` and `hr` are the three heads of the three rotated `s` lists — that is
`s[x-1]`, `s[x]` and `s[x+1]` — and `hc` is `cur[x]`, the cell being decided.

The same example, for the cell at `x = 2`:

```
   column 1:  prev[1]=1  cur[1]=0  next[1]=0      s[1] = 1
   column 2:  prev[2]=0  cur[2]=1  next[2]=1      s[2] = 2     ← cur[2] is the cell itself
   column 3:  prev[3]=0  cur[3]=1  next[3]=0      s[3] = 1
                                                ─────────────
                                  nine cells  =  1 + 2 + 1  =  4
                   minus the cell itself, cur[2] = 1   →   3 neighbours
```

Nine cells, three additions and a subtraction, no index anywhere.

**Does the board size matter?** Not to the arithmetic. A cell has eight neighbour
offsets, and they always occupy three columns and three rows, whatever `w` and `h`
are. The size only decides *where* those three columns fall once the board wraps —
which is why the rest of this chapter is about rotations rather than arithmetic.

## What that saves

The identity is half of it. What it buys is the reason this chapter exists.

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

`newrow` uses both, to put the three columns of the window side by side as three
lists that can be walked together:

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

So `+` means two different things in these chapters, and where it sits is what
tells them apart: **in front of a name being bound or declared it is the reuse
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
