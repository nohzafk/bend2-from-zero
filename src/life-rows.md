# Life in O(n), by rows

The previous chapter ended on the diagnosis: the cost is not the rule, and not
the neighbour sum — it is **computing an index at all**. So the fix is to stop
indexing.

Which raises the question of how you read a cell's neighbours without jumping to
them. The answer is the one this chapter is named after.

## The trick: sum the columns first

A cell's eight neighbours are the 3×3 block around it, minus the centre. So take
the three rows involved — the one above, the one at, the one below — and sum them
**column by column** into a single row `s`:

```
s[x] = prev[x] + cur[x] + next[x]
```

Now the 3×3 block around `(x, y)` is exactly `s[x-1] + s[x] + s[x+1]`, because
between them those three entries have visited every cell of the block once. Take
off the centre, which got counted in `s[x]`:

```
neighbours(x) = s[x-1] + s[x] + s[x+1] - cur[x]
```

Nine cells, three additions. And the whole thing is a **walk** — three lists
moving together, one position at a time. No index is ever computed, so no list is
ever traversed twice.

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
| 32×32 | 1,024 | 5 ms | **76** |
| 64×64 | 4,096 | 18 ms | **69** |
| 128×128 | 16,384 | 67 ms | **64** |
| 256×256 | 65,536 | 314 ms | **75** |

Compare the last column with the previous chapter's:

| | 32×32 | 64×64 |
|---|---|---|
| naive | 29,800 ns | 119,600 ns |
| **row window** | **76 ns** | **69 ns** |

The naive column multiplies by four when the grid does. This one does not move.
**Sixty-four times more cells for sixty-four times more time — that is what O(n)
looks like**, and the flat right-hand column is the evidence.

## The head-to-head

Both versions, 64×64, sixteen generations, **one thread each**:

| | ms |
|---|---|
| naive (`life_par.bend` with `d=0`, no fork at all) | 7,840 |
| row window (`life_row.bend`) | **4** |

**Roughly two thousand times.** Neither version used more than one core.

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
