# Life the obvious way, and the trap in it

Time to build something. Conway's Game of Life is a good choice because everyone
already understands it, so all the difficulty is in the language rather than the
problem — and because the obvious implementation has a trap in it that does not
show up until you measure.

The rules, for completeness: a cell's eight neighbours are summed. The cell is
alive next generation if that sum is 3; it stays as it was if the sum is 2; it
dies otherwise.

## The world

The grid is a flat `List<&2, Nat>` of length `w × h`, holding 0 or 1. Coordinates
become an index with `y*w + x`, and wrapping is done with `Nat.mod`, so the world
is a torus — walk off the right edge and you arrive at the left.

The whole program is [here](https://github.com/nohzafk/bend2-from-zero/blob/main/life/life.bend), 120 lines. Four of them are the
interesting part:

```python
def nth(+xs: List<&2, Nat>, +i: Nat) -> Nat:
  match xs:
    case Nil{}:
      0n
    case Con{h, t}:
      match i:
        case 0n:
          h
        case 1n+p:
          nth(t, p)

def at(+g: List<&2, Nat>, +w: Nat, +h: Nat, +x: Nat, +y: Nat) -> Nat:
  nth(g, Nat.add(Nat.mul(Nat.mod(y, h), w), Nat.mod(x, w)))
```

`nth` walks a list `i` steps and returns the element. `at` turns a coordinate into
an index and calls it. Then `nb` calls `at` eight times, and `step` calls both `at`
and `nb` for each cell in the grid.

Run it and you get a glider, which is the standard check that the rules are right:

```
generation 0        generation 4
.#......            ........
..#.....            ..#.....
###.....            ...#....
........            .###....
```

Generation 4 is the canonical glider shape, one cell down and to the right of
where it started. The logic is correct.

## ❌ The trap

Look again at `at`:

```python
nth(g, Nat.add(Nat.mul(Nat.mod(y, h), w), Nat.mod(x, w)))
    #  ^ nth walks, one step per index. Its cost IS the index.
```

**Reading element number 4000 costs 4000 steps.** There is no array here, no
pointer arithmetic, no skip — a list is a chain and you follow it.

So the cost of computing one cell grows with the size of the grid, and computing
the whole grid makes it quadratic. The numbers, sixteen generations on one
thread, from `./life_par --threads 1`:

| grid | cells | total | **per cell, per generation** |
|---|---|---|---|
| 32×32 | 1,024 | 488 ms | **29.8 µs** |
| 64×64 | 4,096 | 7,840 ms | **119.6 µs** |

**The grid grew fourfold and the per-cell cost grew fourfold too.** That is the
signature: a fixed amount of work per cell would have left the right-hand column
flat. The right-hand column doubling with each dimension *is* the O(n²).

It is worth being precise about what is slow here, because the usual instinct is
wrong. It is not the rule, and it is not the neighbour sum. `rule` is two
comparisons. What is slow is *finding the cell* — and we are doing it eight times
per cell, each time from the head of the list.

## Why a list and not an array

A reasonable objection: Bend has arrays, arrays have O(1) indexing, so why is
this written with a list?

Because each cell needs to read **eight** neighbours, and the arrays chapter
established what that requires: the grid must be *reusable*, which means
`Data`-kinded, which means `List<&2, Nat>` — or nothing.

```
type Array<-T: Type> is Type:        # Type: not copyable
type List<a, -A: Kind(a)> is Kind(a) # &2: copyable
```

`Array` is `Type`, and that is the price it pays for in-place rewrite without
copying. In Bend the choice is not "which is faster" but "do I need to read this
more than once" — and here the answer is eight times per cell, three generations
running.

So this chapter's code is not a mistake. It is what the type system leaves you
when you need random access to something reusable.

## Two roads out

The trap is not "lists are slow". It is that **we are indexing at all**.

Every cell reads its eight neighbours, and neighbours are exactly the cells
adjacent in the layout. If the grid were walked in order, carrying the rows we
need instead of jumping to them, no index would ever be computed.

There are two roads out of the trap, and they are not equal. One is cheap
to try: keep the engine, throw cores at it. The other changes the work
itself. The cheap road is next.

## The whole file

```python
{{#include ../life/life.bend}}
```

```sh
bend life.bend        # the interpreter is enough; this one prints, it does not benchmark
```

Next: the obvious engine on ten cores.
