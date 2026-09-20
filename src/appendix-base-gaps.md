# What Base does not give you

Every chapter in this book uses `import Base`, and almost every chapter takes it
for granted. This appendix is what is actually in it — and what is conspicuously
not.

## The inventory

`Base` ships inside the Bend installation, as a single file:

```
~/.bend/bend2/base.bend
```

Measured, for Bend 2.0.20:

| | |
|---|---|
| lines | 2,908 |
| `def` | 382 |
| `def`, terms | **376** |
| `type` | 22 |
| `law` | 75 |
| `law`, propositions | **10** |
| namespaces | 28 |

`tools/base-inventory.py` re-measures every row of this table and the one below
against the installed `base.bend`. It is what caught the lemma count, so it is
worth running on a `bend update` before quoting anything here.

The 22 types break down as **13 `is Data`**, **3 `is Type`** and **6 `is Kind`** —
that division is the subject of [Kinds and copies](kinds-and-copies.md), and it is
not decoration: it is why `Array` cannot be read twice and `List<&2, T>` can.

The 16 largest namespaces, by size — `Result` ties with `TCP` at 6 and is the one
row that does not fit here; the tool prints all 28:

| | | | |
|---|---|---|---|
| `Map` 52 | `U32` 45 | `String` 40 | `List` 37 |
| `Nat` 32 | `Word` 24 | `Array` 20 | `IO` 18 |
| `Char` 12 | `F32` 10 | `Bool` 9 | `App` 9 |
| `File` 8 | `Maybe` 8 | `Set` 8 | `TCP` 6 |

## Ten lemmas, and the ones that are missing

A **proposition** law claims an equation (`{a == b}`). A **type-family** law
declares a type you fill in with `type X.*`, which is what `Word(32n)` is. Of the
75 `law` declarations in Base, **10 are propositions, and all 10 have a proof**:

| law | what it is about |
|---|---|
| `Equal.cong`, `Equal.sym`, `Equal.trans` | equality itself |
| `Nat.ge_refl`, `Nat.max_ge_l`, `Nat.max_ge_r` | `Nat.is_ge` and `Nat.max` |
| `Word.add_comm.arm`, `Word.add_comm.go`, `Word.add_comm`, `U32.add_comm` | addition commutes |

Two counting traps, and this appendix sat in the first one for a while:

- **`grep -c -e '-> {' base.bend` returns 0, and that number means nothing.**
  Base writes its proofs as `def Nat.ge_refl(a):` with *no return type* — the law
  it fills supplies it. A grep for `-> {` asks for a shape Base never uses, so it
  reports zero however many lemmas are there. The count above is taken from what
  each `law` declares, not from the shape of the `def` that proves it.
- **`law` in Base is usually not the `law` of the last two chapters.** 65 of the
  75 declare a *type family*, not a proposition. That is the trap at the end of
  this appendix, and it counts on the other side of this one.

The correction is small and the conclusion is not. **None of the ten touches the
functions a proof actually needs.** There is no fact about `Nat.add`, none about
`String.append`, none about `List`, `Nat.mod` or `Nat.cmp`. `U32.add_comm` is the
one lemma here a reader might have imported, and this book never reaches for it —
the Hub package defines its own `add_comm`, about `Nat.add`, because Base's is
about `U32` and `Word` and does not generalise. The gap is per-type, not only
per-name.

This is what sets the price of everything in the last part of this book. Writing
a law is cheap. Proving it is cheap **if** every fact you need reduces to
structural induction. If it does not, you are writing the standard library
yourself, first, inside your own file.

## What the two proofs had to fill in

`life/LIFE_PAR_PROOF.bend` and `life/LIFE_ANIM_PROOF.bend` between them define
eleven lemmas. Only three are about Life:

| lemma | what it is | whose gap |
|---|---|---|
| `add_zero` | `a + 0 == a` | `Nat` |
| `add_assoc` | `(a + b) + c == a + (b + c)` | `Nat` |
| `append_nil2` | `a == append(a, "")` | `String` |
| `append_assoc2` | append is associative | `String` |
| `reverse_go_spec` | the invariant of `String.reverse`'s accumulator | `String` |
| `reverse_append2` | `reverse(append(a,b)) == append(reverse(b), reverse(a))` | `String` |
| `pick_pal` | a two-character literal equals its own reversal | `String` |
| `cell_pal` | **a cell equals its own character-reversal** | `String` — and the law's key fact |
| `cells_add` | splitting a sequential loop in two | the law's |
| `rowrev_spec` | the invariant of `rowrev`'s accumulator | the law's |
| `inner` | the accumulator invariant over `Rows` | the law's |

Five of the eight library lemmas are `String` lemmas, and the reason is visible in
the inventory above: **`String` has 40 functions and no facts at all.** There is no
`String.append_nil` to import. There is no `String.reverse_reverse`.

If you want to prove anything about string manipulation in Bend today, you begin
by writing these. There is no shortcut and no `simp`.

## Why the lemmas look the way they do

Two shapes recur, and both are consequences of how Base is written rather than of
what is true mathematically.

**A function that recurses on its first argument is stuck on a variable.**
`String.append` matches on its first argument, so `append(a, SNil{})` does not
reduce when `a` is a variable — the reducer has nothing to match on. Hence
`append_nil2`, whose statement is written with `a` on the *left* precisely so the
goal can be reoriented. `Nat.add` is the same, hence `add_zero`.

**A function with an accumulator hides its own structure.** `String.reverse` is not
a structural recursion; it calls `reverse.go(s, acc)`. A goal containing
`reverse(x)` for a variable `x` is therefore stuck, and induction will not go
through until the invariant is generalised over the accumulator. That is what
`reverse_go_spec`, `rowrev_spec` and `inner` are for.

## The two taxes, and why they are not the same size

The book's last chapter explains why one law was written and a second, equally
desirable one was not. The distinction is worth restating here as a piece of
planning advice:

| obligation | shape |
|---|---|
| `a < a + 1` | one induction over `a`, `{==}` to close |
| `Nat.add` associative | one induction over `a` |
| `Nat.mod x n < n` | induction over `x` **and** an inner case needing `r ≤ m + r`, which goes through `Nat.cmp` |
| `a < h ∧ b < w ⟹ a*w + b < h*w` | distribution of `Nat.mul`, plus monotonicity through `Nat.cmp` |

The `String` lemmas are all of the first kind. The arithmetic ones are of the
third and fourth: `Nat.cmp` compares two numbers, so an induction over it needs a
hypothesis about a *pair*.

So when choosing what to prove: **prefer laws whose proof obligation reduces to
structural induction.** The distance from a structural recursion is the cost, and
it is an order of magnitude, not a percentage.

## A trap: `law` in Base is not the `law` of the last two chapters

`Base` uses the `law` keyword **72 times**, and every one of them declares a *type
family*, not a proposition:

```python
law Word:
  for n: Nat
  Data

type Word.Nil is Data:
  WNil{}

type Word.Con<-p: Nat> is Data:
  WCon{head: Bool, tail: Word(p)}
```

`Word(32n)` is then a type, and it is what `U32` is made of (`type U32 is Data:
U32{data: Word(32n)}`).

Both uses are the same idea — **a `law` is a declaration you have to fill in** —
but the mechanism is not interchangeable, and it is worth not being surprised:

- In **Base**, a `law` is filled by the `type X.*` declarations in its namespace.
- In **user code**, write the type family with `def` instead:
  ```python
  def Tree(d: Nat) -> Data:
  ```
  This is what `bend/demos/pure_par_sort/main.bend` does upstream, and what
  `life/life_par.bend` does here.

Declaring a type family with `law` in a user file does not work, and the failure
is not a syntax error:

```python
law MyWord:
  for n: Nat
  Data
```
```
Error: 1 TODO found.
The code is incomplete, and not a valid proof yet.
```

Adding the `type MyWord.Nil` / `type MyWord.Con` declarations does not change it,
and using `MyWord(2n)` as a type gives `expected : a datatype, observed :
MyWord(2n)`. Whether that is a limitation or a deliberate restriction is not
something this book established — it is a measured behaviour, and it is why no
chapter ever writes `law` for anything except a proposition.

The same message is what you get for a **law you have declared and not proved**,
which is a genuinely useful thing: write the law first, run, and let the compiler
tell you it is unfinished.

## The short version

Base gives you a rich **term** library — 376 definitions covering lists, strings,
maps, numbers, arrays, IO, files, TCP and UDP — and a **reasoning** library of ten
lemmas, none of them about anything on that list.

For programming, that is fine and it is generous. For proving, it means the first
law you prove is cheap and every law after it that touches arithmetic is not, and
the difference between those two cases is whether your obligation reduces to a
structural recursion.
