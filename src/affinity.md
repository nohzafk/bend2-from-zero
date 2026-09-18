# Affine values: everything is used at most once

Everything up to here would be recognisable in a language you already know.
This chapter is not. It is one rule about values, it is stated in a single
sentence, and it is the reason Bend exists in the shape it does.

> **Bend, by default, is *affine*, meaning variables must be used, at most, once.**
>
> — `GUIDE.txt:55`

Here it is failing:

```python
{{#include ../affinity/affine_bad.bend}}
```

```
Error:
- expected : x
- observed : x (consumed more than once)
Location: main
4 |   x = {3 : U32}
5>|   (x + x : U32)
```

That error message — *consumed more than once* — is the one you will see most
often in Bend. Not "undefined variable", not "type mismatch". **Consumed.**

## The word "used" is doing something specific here

`x + x` does not *read* `x` twice. It **consumes** it twice. In Bend a value is
less like a number sitting in memory and more like a key: to use it you hand it
over, and once handed over you no longer have it.

Two experiments bracket the rule, and each is surprising in a different
direction. One you have already seen — `affine_bad.bend`, used twice, refused.
Here is the other:

**You may not use a value at all.**

```python
{{#include ../affinity/t1_drop.bend}}
```

```
$ bend t1_drop.bend
7
```

`x` is declared and then never used, and Bend is perfectly happy. This is the
detail that separates **affine** from **linear**, and it is the one most people
get backwards on first contact. "At most once" is not "exactly once".

**And "once" is counted per execution path, not per appearance.**

```python
{{#include ../affinity/t7_paths.bend}}
```

```
$ bend t7_paths.bend
11
```

`x` appears in *two* branches — twice in the source — and Bend accepts it,
because no single run of that `match` takes both branches. The rule is about
the paths a value's life can take, not about how many times a name is typed.

## Where the name comes from, because it is not arbitrary

Bend is built on a **substructural type system**, which is a two-hundred-year
detour through logic that pays off here. The classical rules of logic let you do
three things to an assumption you have been handed:

| rule | what it lets you do |
|---|---|
| **weakening** | ignore it — never use it at all |
| **contraction** | duplicate it — use it more than once |
| **exchange** | reorder it |

Ordinary programming languages have all three, and never think about it. If you
throw them away one at a time you get a family:

```
exactly once   linear       (no weakening, no contraction)
at most once   affine       (weakening back, no contraction)   <-- Bend, and Rust
at least once  relevant     (contraction back, no weakening)
any number     unrestricted (everything)                        <-- most languages
```

Bend sits at **at most once**: you may drop a value (weakening is back), you may
not duplicate it (contraction is gone). That is the whole of it. The word
"affine" comes from affine geometry by the same analogy — an affine combination
is a linear one that is allowed a coefficient of zero, so one term may be
dropped.

> If you want the real thing rather than this sketch: David Walker,
> *Substructural Type Systems*, chapter 1 of Pierce (ed.), *Advanced Topics in
> Types and Programming Languages*, MIT Press, 2005. The lineage starts with
> Girard's linear logic in 1987.

## Why anyone would do this

Read the rule again as a statement about ownership rather than usage:

> **A value has exactly one owner at a time.**

Every headline feature of Bend is a consequence of that sentence, and they are
not three features. They are one feature seen from three sides.

**You get memory management for free, with no collector.**

> There is no garbage collector. Since values are affine, a `match` frees the
> node it opens on the spot, and only `+` values carry a reference count.
>
> — `GUIDE.txt:586`

If nobody else can be holding the value, then the moment you take it apart there
is nothing left to do with it — so taking it apart *is* freeing it. That is why
Bend forces you to `match` on things instead of reading fields out of them. It
is not a style rule. It is the only way the language has to free memory.

**You get parallelism that cannot race.**

> A parallel call promises the compiler two things: 1. The calls are
> independent. 2. They run in roughly the same time. **Since Bend is pure and
> affine, the first point always holds.**
>
> — `GUIDE.txt:147-153`

The first promise is not something you assert. It is something the type system
has already made true: if `x` has one owner, it cannot be in two parallel
branches at once, so there is no way to write a race. Notice which promise is
left for you — the second one. Load balancing is the entire human job.

It is worth seeing how strong this is. The one type in `Base` that *can* be
mutated in place is `Array`, and `Array` is not copyable, so **there is no
syntax in the language that hands the same array to two parallel calls.**
Racing on it is not forbidden; it is unspellable.

**You get proofs that cost nothing at runtime.**

The third payoff is set up here and cashed in at the end of the book. There is a
third quantity, `-x`, meaning *erased*: the checker can see the value, the
compiler deletes it. Nothing you prove about your program needs to exist when
the program runs.

## What it costs

- **Function arguments are consumed.** After `f(xs)`, `xs` is gone. This is the
  single biggest source of friction when adapting code you already know.
- **There is no borrowing.** Rust's `&x` has no counterpart here. This is not an
  omission — search the whole guide and `borrow` appears zero times. Bend
  answers "I want to use it twice" with `+x`, which is a different and heavier
  answer, and it does not answer "let me look without taking" at all.
- **Closures are affine and cannot be marked otherwise.** The next chapter is
  largely about that, because the workaround is one of the more elegant things
  in the language.

The comparison with Rust is worth making explicit, since Rust is where most
readers will have met "affine" before:

| | Rust | Bend 2 |
|---|---|---|
| default | affine (`move`) | affine |
| use it briefly | `&x` | no such thing |
| use it twice | `.clone()`, or restructure ownership | `+x`, which is reference counting |
| don't want it at runtime | monomorphisation | `-x`, erased |

## The files

| | | |
|---|---|---|
| [`affinity/affine_bad.bend`](../affinity/affine_bad.bend) | ❌ | used twice |
| [`affinity/t1_drop.bend`](../affinity/t1_drop.bend) | ✅ | never used at all |
| [`affinity/t7_paths.bend`](../affinity/t7_paths.bend) | ✅ | twice in the source, once per path |

Next: [copies, kinds and the `+` mark](kinds-and-copies.md) — what `+` really
costs, and why it is refused for some types and not others.
