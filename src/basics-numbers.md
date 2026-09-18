# Numbers and patterns

There are two numeric types in the part of Bend this book uses: `Nat` — the
natural numbers, unbounded — and `U32`, a 32-bit unsigned integer. The suffix
is what picks:

```python
42      # a U32
42n     # a Nat
```

Mixing them is an error rather than a conversion, which you already met in
chapter one. This chapter is about the stranger half: **how you are allowed to
look at a `Nat`.**

## `Nat` is not a machine word

`Nat` in Bend is a datatype with two constructors, and the pattern you write to
match it is a shorthand for them. Every `Nat` match has this shape:

```python
match n:
  case 0n:
    ...
  case 1n+p:
    ...
```

`1n+p` is not "equals one". It is **one or more**, and it *binds `p` to the
predecessor*. If you have seen `x :: xs` for lists, this is the same idea: the
pattern takes the number apart and hands you the rest.

That is the whole reason recursion over a `Nat` terminates: `p` is genuinely
smaller than `1n+p`, so a self-call on `p` walks downhill.

## ❌ The pattern that swallows everything, silently

Because `1n+p` means "one or more" and not "one", the natural way to branch on
a small number does not work:

```python
{{#include ../basics/pat_bad.bend}}
```

```
$ bend pat_bad.bend
1
```

**It compiles. It runs. It invents an answer.** `f(2n)` is `1`, because the
second case caught the `2n` before the third case was ever considered, and Bend
does not warn you that the third case is unreachable.

This file is kept in the repository as
[`basics/pat_bad.bend`](../basics/pat_bad.bend), and it is the most dangerous
kind of example in this book: not one that fails loudly, but one that passes.

When you want to branch on the *value* of a number — "is this equal to 1?" —
you do not reach for `match`. You reach for `Bool.pick`, which you will meet
below.

## The rule you will trip over most: recursion must walk downhill

Bend requires every recursive call to be **demonstrably** closer to the ground.
Not "closer in fact" — closer by the shape of the arguments. Here is a function
that is obviously going to stop, and that Bend refuses:

```python
{{#include ../basics/term_bad.bend}}
```

```
Error:
- expected : a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)
- observed : loop
Context:
- p : Nat
Location: loop
7 |     case 1n+p:
8>|       loop(Nat.add(p, 1n))
```

Read the error carefully, because Bend told you the whole rule in one line:

> **arguments are read left to right: each passed unchanged until one shrinks**

So a self-call is allowed when, walking the arguments in order, everything is
passed through untouched until you reach one that is *the* shrinking thing —
usually `p` from the pattern, passed bare. `Nat.add(p, 1n)` is not `p`, and the
checker does not evaluate it to find out.

Which gives the second half of the rule, and it is the one that bit this book's
author while writing Conway's Life at two in the morning:

```python
{{#include ../basics/term_order.bend}}
```

```
Error:
- expected : a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)
- observed : evolve
Context:
- g : Nat
- q : Nat
Location: evolve
10 |     case 1n+q:
11>|       evolve(step(g), q)
```

**`gens` cannot be last.** The shrinking argument has to come before anything
that changes, because the checker stops reading at the first argument that is not
the shrinking one. `evolve(g, gens)` is rejected; `evolve(gens, g)` is fine —
same function, same termination, one reordered parameter list.

### Why Bend is this strict

It is not paranoia about infinite loops. It is the price of the last third of
this book. Bend's theory keeps two checking modes apart:

> Code that runs is checked *live*; types, erased arguments and equations are
> checked *dead*. Dead code may loop forever or inhabit `Empty`, but nothing
> dead ever counts as live evidence, and **live recursion must terminate**.

A language where a live recursion might not terminate is a language where a
value of *any* type can be produced by running forever — including a value of
the type "this program is correct". So the proof system only works on top of a
running language that provably stops. You pay in parameter order.

## What you do instead: accumulate

The tools are still enough to write everything you want. `basics/exp_mod.bend`
computes `x mod n`, which is not structurally recursive in any obvious way, by
making the recursion structural anyway:

```python
{{#include ../basics/exp_mod.bend}}
```

`mod` recurses on `x` — always downhill, always `p` — and carries the running
remainder in `k`. The check passes because **the checker looks at the
parameters, not at the meaning.** `bump` is where the arithmetic lives, and it
is not recursive at all.

That shape — recurse structurally on whatever shrinks, accumulate the real work
in an argument — is the standard way to get non-structural loops past the
termination checker. You will see it again in the Life chapters, where it is
load-bearing.

## Branching on a value: `Bool.pick`

Since `match` cannot inspect a computed value, and since `1n+p` is a terrible
way to test equality, Bend provides a combinator:

```python
Bool.pick(Nat, Nat.is_lt(k, Nat.sub(n, 1n)), 1n + k, 0n)
```

Read it as: **pick a `Nat`; if the condition holds take the third argument,
otherwise the fourth.** The first argument is the type of what you are picking,
which is the annotation you now expect Bend to demand everywhere.

You will use `Bool.pick` constantly. It is how you write `if`.

## Small things about the arithmetic that are worth knowing early

Measured, not read:

```python
Nat.sub(0n, 1n)   # 0     -- Nat.sub saturates at zero, it never goes negative
Nat.sub(3n, 5n)   # 0
Nat.mod(0n, 4n)   # 0
```

`Nat.sub` saturating is what makes the ring arithmetic in the Life chapters work
without special-casing the edges: `Nat.sub(Nat.add(x, w), 1n)` is `x - 1` for
every `x` except `0`, where it is `0` — which is exactly the wrap-around a torus
wants.

## The files

| | |
|---|---|
| [`basics/exp_mod.bend`](../basics/exp_mod.bend) | structural recursion with an accumulator |
| [`basics/term_bad.bend`](../basics/term_bad.bend) | ❌ a recursion that cannot be shown to shrink |
| [`basics/term_order.bend`](../basics/term_order.bend) | ❌ the shrinking argument is not leftmost |
| [`basics/pat_bad.bend`](../basics/pat_bad.bend) | ⚠️ compiles, runs, and lies |

Next: [lists](basics-lists.md), where a one-line function turns out to be the
reason the second half of this book exists.
