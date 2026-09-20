# Types, quantities, and the two brackets

Four chapters in, you have written types in every file — `IO(Unit)`, `Nat`,
`String` — and never declared one. This chapter is the `type` declaration:
what it states, what the compiler refuses to let you leave out, and what the
two kinds of bracket in that declaration are doing.

It exists because the next chapter's first line is this:

```python
type List<a, -A: Kind(a)> is Kind(a):
```

By the end of this chapter you can read every piece of that line. The one
question it opens and this chapter does not close — why the language makes
copyability part of a type at all — belongs to
[copies and kinds](kinds-and-copies.md).

## Your first type

The smallest useful declaration has no parameters at all:

```python
{{#include ../basics/exp_type.bend}}
```

```
$ bend exp_type.bend
25
```

Read it as you would read a Rust or Haskell enum, because it is one. `type`
names the type — `Shape`. The indented lines are its **constructors**, the
values the type has: a `Circle` or a `Square`. The braces are the
constructor's **fields** — the data each value carries — and a constructor
with no fields, like `Nil{}` in the next chapter, carries none.

`is Data` is the clause this chapter keeps coming back to: it says **values
of this type may be copied**. That is a statement about the type, not about a
particular value, and it is mandatory — the next section shows the compiler
refusing a declaration that leaves it out. What `Data` means at runtime is
the copies chapter's subject; for now it is one word of vocabulary:
`Data` = copyable, `Type` = not copyable.

One more thing in that file is doing real work: the `+` in `Circle{+r: Nat}`.
Fields are affine like everything else, and this `area` multiplies a field by
itself — two uses. Remove the `+` from the declaration and the same function
is refused:

```python
{{#include ../basics/type_field_affine.bend}}
```

```
Error:
- expected : r
- observed : r (consumed more than once)
Location: area
14>|     case Circle{r}:  r * r
```

The fix is not at the call site and not in `area`: the field must be marked
`+` **where the type declares it**. A match hands out the marks the
constructor carries, so the decision belongs to the declaration — which is
where a type decides what its values are allowed to do.

## The clause you cannot leave out

Drop the `is` clause and see what the compiler says:

```python
{{#include ../basics/type_is_missing.bend}}
```

```
Error:
- expected : 'is'
- observed : ':'
Location:
7>| type Tree<a>:
```

Read it slowly: it explains the shape of every type declaration in this
book, including the ones that look decorated for no reason. The `is` clause is **where a type says how often its
values may be used** — `is Data` for copyable, `is Type` for single-use, and, further down this
chapter, `is Kind(a)` for "depends on the element". A checker
that never searches for a type also never searches for a permission: the
declaration has to carry it. So a bare `type Tree<a>:` is not a declaration
in Bend at all — it does not parse.

## The first parameter is a quantity

Parameterise the type, and the natural first mistake is to type the field
with the parameter itself:

```python
{{#include ../basics/type_quantity_field.bend}}
```

```
Error:
- expected : Kind(a)
- observed : Quant
Context:
- a : Quant
- A : Kind(a)
Location: Cell
10>|   Cell{head: a, tail: Chain<a, A>}
```

The line to read is `a : Quant`. The guide states the rule that produces it
in one line: **a bare `a` in a parameter list is short for `-a: Quant`** — so
`a` is not a type, it is a **quantity**: a number saying how many times a
value may be used. The `-` is the affinity chapter's erased mark, because a
quantity exists for the checker and is gone before anything runs. There are
three of them, and you have been reading two of them as words:

```
&0   zero uses              nothing may use the value
&1   at most once           the affine default -- what `Type` means
&2   as often as you like   copyable -- what `Data` means
```

`Type` is short for `Kind(&1)` and `Data` for `Kind(&2)`. So the `is Data` on
`Shape` was `&2` all along, and every `List<&2, Nat>` in the lists chapter is
a list whose elements may be copied. The three are ordered, and combining two
of them keeps the smaller — that is the `<&>` in the ladder below.

`&0` is the bottom of that scale: zero uses, *nothing may use this*. It is a
mark to read rather than one to write. `base.bend` contains no `&0` at all,
and the guide mentions it only in a comment and in its grammar table; `&1`
and `&2` are the two you will write, mostly in the shorthand `List<Nat>` for
`List<&1, Nat>` and `+List<U32>` for `List<&2, U32>`.

That leaves the error itself. A quantity is a number and a field carries a
type: `head: a` asks the checker to treat a count of uses as data. The
element type therefore needs a parameter of its own, `A` — and `Kind(a)` is
what states which kind of type `A` is allowed to be.

## Two brackets, and the question each one answers

Two lines in that error carry brackets, spelled differently: `A : Kind(a)` in
the context, and `Cell{head: a, tail: Chain<a, A>}` below it. The name in
front is what decides which spelling a name takes. **`Kind` is a `def`.
`Chain` is a `type`.**

**A `def` takes round brackets, because applying it is a call.** `Kind` is a
function from a quantity to a kind, and `Kind(a)` applies it to `a`. `IO` is
declared the same way — `bend base` shows `def IO(A):` — so `IO(Unit)` is
`IO` applied to `Unit`, and the result is the type of an action producing
`Unit`. `Chan(U32)`, `Pair(U32, Bool)` read the same way: find the `def`,
count the arguments.

**A `type` takes angle brackets, and there is nothing to apply.** `Chain` is
a datatype, not a function. `Chain<a, A>` is one concrete type out of the
family the declaration names, with the parameters the declaration left open
fixed — there is no call, and nothing is computed. `List<Nat>`,
`Maybe<U32>` are the same shape.

Getting the pairing wrong has a message of its own for each direction:

```python
List(Nat)     # expected : a family instance (write List<..>)
              # parentheses on a datatype: nothing to apply
IO<Unit>      # a declared datatype (unknown: IO)
              # angle brackets on a name that is not a datatype: IO is a function
```

Both say the same thing: look at how the name was declared.

One pair of words in every program sits next to each other with both
spellings, and both are correct:

```python
def main() -> IO(Unit):     # a call: IO is a def, applied with ()
  do IO<Unit>:              # the header's own grammar: always <>
```

The first is the call described above. The second is not a call and not an
instantiation: the `do` header names the family whose `.bind` and `.pure` the
block desugars to, and it always takes `<>`. Write `do IO(Unit):` or `do IO:`
and the checker answers `expected : '<'` — the header takes the brackets of a
datatype even though `IO` is a `def`. For now the rule is just those two
lines — `IO(Unit)` in a type, `do IO<Unit>` on a block — and the header gets
a chapter to itself later: [Inside a `do` block](do-blocks.md).

## The element type is its own parameter

Which makes the corrected header readable, one piece at a time:

```python
type Chain<a, -A: Kind(a)> is Kind(a):
```

- `a` — a **quantity** parameter: the `&0`/`&1`/`&2` from above. Erased,
  but still passed at the call site, because the checker reads it.
- `-A: Kind(a)` — the **element type**. The `-` is the affinity chapter's
  erased mark again, and `Kind(a)` is its annotation: *a type whose values
  may be used `a` times*.
- `is Kind(a)` — the Chain **itself** may be used `a` times. A chain is
  exactly as reusable as its elements, and the header says so.

The corrected declaration checks, and so does a function over it:

```python
{{#include ../basics/exp_chain.bend}}
```

```
$ bend exp_chain.bend
2
```

Note what `len`'s signature looks like — the same two leading parameters,
in the same order, at every call site:

```python
def len(a, -A: Kind(a), xs: Chain<a, A>) -> Nat:
    ...
    len(&2, Nat, xs)
```

`&2` fills `a`, `Nat` fills `A`. You are passing a *number* and a *type* as
arguments, before the list itself. This is not `Chain` being exotic — it is
the minimum shape of every parameterised type in Bend, and the next section
shows `Base` using it four times in a row.

## The ladder in `Base`

`bend base --types` prints every type declaration in the standard library.
It is one short ladder, and each rung is a shape this chapter has now
introduced:

```python
type Nat is Data:                                  # no parameters
  Zero{}
  Succ{pred: Nat}                                  # self-reference, no kind to pass

type Maybe<a, -A: Kind(a)> is Kind(a):             # one element type
  None{}
  Some{value: A}

type Either<a, b, -A: Kind(a), -B: Kind(b)> is Kind(a <&> b):
  Inl{value: A}
  Inr{value: B}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}

type Array<-T: Type> is Type:                      # the contrast
  ALeaf{value: T}
  ANode{xs: Array<T>, ys: Array<T>}
```

Four things in that ladder, in order of strangeness:

**`String`-style self-reference needs no kind parameter.** A type with no
element type — `Nat`, `String` — has a fixed kind and says it once:
`type String is Data: ... tail: String`. The recursion is as plain as the
type.

**`Maybe`, `List` carry one `a`/`A` pair.** The field is typed `A` — the
element type — never `a`, which is a quantity. (`List` here is `Base`'s
real declaration, straight from `bend base --types`; if you have seen this
line with `head: a`, that version does not compile — the checker's
`a : Quant` error above is what it produces.)

**`Either` carries two**, and the two kinds combine with `<&>`:
`Kind(a <&> b)` — the smaller of the two quantities, so an `Either` is as
reusable as its *least* reusable element.

**`Array` is the counterexample.** It is `is Type` — never copyable,
whatever it holds — so it does not need the kind as a parameter, only the
fixed annotation `<-T: Type>`. A handle's copyability does not follow its
contents; that is exactly what makes it a handle, and it is the whole
story of the arrays chapter.

## At the use site

Three spellings, one meaning:

```python
List<Nat>          # the checker fills in the quantity: List<&1, Nat>
List<&1, Nat>      # spelled out: affine elements, affine list
List<&2, Nat>      # copyable elements
+List<U32>         # the + spelling, same as List<&2, U32>
```

A list literal is written with the quantity it gets: `[1n, 2n, 3n]` is a
`List<&2, Nat>` — the numbers are freely copyable and the list does not
promise otherwise. That is why `Base`'s functions announce it:

```python
List.length(&2, Nat, [1n, 2n, 3n])    # 3
```

and it is why a `List<Nat>` — a promise to use the list at most once —
gladly accepts a `List<&2, Nat>`: a value that may be used *many* times
may certainly be used *one*. The useful direction is free; the reverse is
the checker's business, and the copies chapter's.

## What this chapter leaves open

You can now read every type declaration in this book. What you cannot yet
answer is the question the machinery keeps asking: *why* does copyability
travel with the value, and what does `&2` cost at runtime? That is the
subject of [copies and kinds](kinds-and-copies.md) — two chapters from
here, and the single most consequential idea in the language.

## The files

| | |
|---|---|
| [`basics/exp_type.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/basics/exp_type.bend) | the no-parameter type, and its affine fields |
| [`basics/type_field_affine.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/basics/type_field_affine.bend) | ❌ a field used twice, unmarked |
| [`basics/type_is_missing.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/basics/type_is_missing.bend) | ❌ a declaration without `is` |
| [`basics/type_quantity_field.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/basics/type_quantity_field.bend) | ❌ a field typed with the quantity parameter |
| [`basics/exp_chain.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/basics/exp_chain.bend) | the smallest checking parameterised type |

Next: [lists](basics-lists.md) — the declaration you can now read in full,
and the one-line function that turns out to be the reason the second half
of this book exists.
