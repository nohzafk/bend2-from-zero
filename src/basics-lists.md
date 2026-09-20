# Lists

A `List` in Bend is what it is in every functional language: a chain of cells,
each holding one value and a pointer to the rest, ending in an empty cell.

```python
type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}
```

Every piece of that header was introduced in the [types
chapter](basics-types.md): `a` is a quantity parameter, `A` the element
type, `is Kind(a)` says a list is exactly as reusable as its elements.
(The field is typed `A`, not `a` — an earlier edition of this book printed
`head: a`, which does not compile: `a` is a quantity, and the checker
refuses a field typed with one.) What that header *means at runtime* —
why copyability decides anything — is the subject of
[copies and kinds](kinds-and-copies.md), three chapters from here.

There is also an infix spelling. `h <> t` builds or matches a cell, and `Base`
uses it; `Con{h, t}` is the same thing. Both work.

## Walking a list is the only way to read it

There is no indexing. To get at element `i` you walk `i` cells:

```python
{{#include ../basics/exp_list.bend}}
```

```
$ bend exp_list.bend
2
```

Correct — `[1, 2, 3][1]` is `2` — and it cost two steps. That cost is `O(i)`,
and it is worth pausing on, because **this five-line function is the reason the
second half of this book exists.**

Here is the arithmetic. Suppose you keep a `w × h` grid as one flat list of
`w*h` cells, and you want to compute the next generation. Each cell needs its
eight neighbours, and each neighbour lookup is a walk to that index — so one
generation is `O((w·h)²)`. At 64×64 that is 4096 cells and about 4096 steps per
neighbour lookup. Nothing looks wrong; the program is short and correct.

That is exactly the trap the Life chapters walk into, measure, and then climb
out of — and the climb is not "use a better data structure" in the abstract. It
is a specific rewrite that turns `O(n²)` into `O(n)` while keeping the same
output. Keeping this chapter's `nth` in mind makes that chapter much easier to
follow.

## `List.range`, and the quantity on its return type

`Base` gives you a few list functions. The useful one here is `range`, which
produces the numbers from `0` to `n-1`:

```python
List.range(4n)    # [0n, 1n, 2n, 3n]
```

Its return type is written `List<&2, Nat>` rather than `List<Nat>`, and that
`&2` means **this list may be used more than once**. It is a small detail with
large consequences: it is why `range` is the natural starting point for building
a grid, and why some other functions are not.

## The oddest signature in the standard library

Here is `List.append` as `Base` declares it:

```python
def List.append(a, -A: Kind(a), xs: List<a, A>, ys: List<a, A>) -> List<a, A>
```

The first argument is not a list. It is a **quantity** — the `&2` from the line
above, passed at the call site:

```python
List.append(&2, Nat, xs, ys)
```

and the second is the element type. `Base`'s own source writes it both ways,
because inside the library the quantity is usually a parameter that is already
in scope.

You met this shape in the types chapter, on a hand-written `Chain`; here it
is in `Base`, where you cannot avoid it. It is Bend being honest about
something most languages hide: the *"may this be copied?"* question is part of a
list's type, so a function that takes lists cannot ignore it. If you have ever
wondered why Bend's type annotations feel like they leak, this is the leak.
[copies and kinds](kinds-and-copies.md) explains where it comes from and why
the language considers it a feature.

> **A note on the direction of travel.** While writing the Life chapters, this
> book's author eventually wrote a four-line `app` rather than call
> `List.append`, purely to stop threading `&2` and `Nat` through every call
> site. Both work. If you find yourself doing the same, that is a fair reading
> of the language and not a mistake.

## Lists versus arrays

Bend has an `Array` type as well, with real random access. It is not a drop-in
replacement, because an array is **not copyable** — the type system refuses to
duplicate one. That is what buys in-place mutation without giving up purity, and
it is why the Life chapters end up using lists for the grid even though an array
would be faster to index.

Hold on to that tension. It is the same tension as `&2`, seen from the other
side, and the chapters on [copies](kinds-and-copies.md) and
[arrays](arrays.md) are about resolving it.

## The files

| | |
|---|---|
| [`basics/exp_list.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/basics/exp_list.bend) | walking a list, and its cost |

Next: strings and characters — another linked list, wearing
a friendlier face, and a trap that produces the wrong bytes without complaining.
