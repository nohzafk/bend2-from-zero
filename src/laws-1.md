# Your first law and proof

Everything so far has been a program. This chapter is about the other thing Bend
is for, and it is the reason the language exists at all.

Consider what we have been doing for four chapters. We wrote a parallel Life
step, measured it, and concluded it computes the same thing as the sequential
loop. We concluded that **by testing it** — running both, counting live cells,
seeing 5 each time. That is evidence about the inputs we happened to try. It is
not knowledge about the code.

Bend lets you replace it with something that is not evidence: a proof the
compiler checks. Here is that claim, as a thing the compiler can read.

## A law is a type

```python
law tree_is_serial:
  for +d: Nat
  for +g: List<&2, Nat>
  for +w: Nat
  for +h: Nat
  for +blk: Nat
  for +k: Nat
  {Par.tree_cells(d, g, w, h, blk, k) == Par.block(g, w, h, Par.cells_in(d, blk), k) : List<&2, Nat>}
```

Read it as a sentence. *For any depth, grid, width, height, block size and start
index: the fork-join tree produces exactly the list that one sequential loop over
the same range produces.*

(A note for later, because it is a trap: `Base` uses the same `law` keyword 72
times to declare *type families* rather than propositions. In user code those are
written with `def` — `def Tree(d: Nat) -> Data:`. Both uses are the same idea, a
declaration you fill in, but the mechanism is not interchangeable. See
[What Base does not give you](appendix-base-gaps.md).)

There is nothing imperative here and nothing to run. `==` is not a comparison
that returns a `Bool` — it is a **type**, and the law `tree_is_serial` names the
type "both sides are the same list". A proof is a `def` of that type:

```python
def Laws.tree_is_serial(d, g, w, h, blk, k):
  match d:
    case 0n:
      {==}
    case 1n+p:
      ...
```

Note the shape. It is an ordinary function — it takes the law's parameters and
its body is **induction on `d`**, which is a `match` because `Nat` is a datatype.
The case `d = 0` is proved by `{==}`.

## `{==}` is reflexivity

`{==}` is the proof of `{x == x}`: the two sides are already the same term.

That is the whole of the interesting content in this kind of proof. There is no
tactic language, no `auto`, no `simp`. `{==}` is the only axiom and `%` is the
only rule. So the entire craft is: **move one side until it equals the other, one
lemma at a time.** The depth-0 case needs no work because a tree of depth zero
*is* one leaf, and one leaf *is* the loop.

At depth `p + 1`, the tree is two depth-`p` trees joined, and the spec is one
undecomposed loop. Something has to split that loop in two. That is the first
non-trivial lemma.

## `%`: applying a lemma

```python
%cells_add(g, w, h, Par.cells_in(p, blk), Par.cells_in(p, blk), k) : {Par.tree_cells(1n+p, g, w, h, blk, k) == _ : List<&2, Nat>}
```

`%lemma(args) : P` rewrites the goal using `lemma`. The rule, and it is the one
thing to get right:

> **A lemma `e : {a == b}` applied as `%e(...) : P` replaces `b` with `a` in the
> goal.** `P` is the goal written out with the occurrence of `b` replaced by `_`.

So `_` sits exactly where the lemma's **right-hand side** was. Which gives the
working rule for writing lemmas:

> **Write a lemma as `{what you want == what is there now}`.**

The right side is what the goal currently contains; the left side is what
replaces it. Getting this backwards gives an error that says so plainly —
`expected` and `observed`, with the two terms — and the fix is to swap them.

In the line above, `cells_add(...)` has conclusion
`{app(block(n,k), block(m,k+n)) == block(n+m,k)}`, so its *right* side is the
combined loop `block(..., n+m, k)`. The goal's second component is
`block(g, w, h, cells_in(p,blk) + cells_in(p,blk), k)` — the same form. The `_`
marks it, and after the rewrite the spec's single loop has become two loops,
which is exactly the shape of `tree_cells` at depth `p+1`.

Then two more rewrites — the induction hypothesis, applied once to each
half — and the case is done:

```python
%Laws.tree_is_serial(p, g, w, h, blk, k) : {Par.tree_cells(1n+p, g, w, h, blk, k) == Par.app(_, Par.block(g, w, h, Par.cells_in(p, blk), Nat.add(k, Par.cells_in(p, blk)))) : List<&2, Nat>}
%Laws.tree_is_serial(p, g, w, h, blk, Nat.add(k, Par.cells_in(p, blk))) : {Par.tree_cells(1n+p, g, w, h, blk, k) == Par.app(Par.tree_cells(p, g, w, h, blk, k), _) : List<&2, Nat>}
{==}
```

Three rewrites for the inductive case, and `{==}` to close. The first is the
structural fact; the other two are the induction hypothesis. **The function you
are proving is available inside its own proof**, because the recursion of the
proof follows the recursion of the term.

## The library tax

Two lemmas in the file exist for reasons that have nothing to do with Life:

```python
def add_zero(a: Nat) -> {Nat.add(a, 0n) == a : Nat}:
def add_assoc(a: Nat, -b: Nat, -c: Nat) -> {Nat.add(Nat.add(a, b), c) == Nat.add(a, Nat.add(b, c)) : Nat}:
```

`Nat.add` recurses on its **first** argument. So when the first argument is a
variable `k`, the term `Nat.add(k, 0n)` does not reduce — the reducer has nothing
to match on. That is the entire reason `add_zero` exists: not because it is
mathematically interesting, but because one side of an equation is stuck.

This is worth naming because it recurses through everything below. **Base has no
lemma library.** There is no `Nat.add_zero` to import; there are no standard
facts about `Nat.add`, `Nat.mul`, `Nat.mod` or `Nat.cmp`. Every proof that touches
arithmetic brings its own small arithmetic with it. For this law that was two
lemmas, both easy. For the law we *did not* write — index safety — the same
beginning leads into `Nat.cmp` and iterated induction on two variables at once,
and that is a different order of work. We will come back to that.

## Running it

```sh
cd life && bend LIFE_PAR_PROOF.bend
```

```
All terms check.
```

Measured, on this machine:

| | wall clock |
|---|---|
| `LIFE_PAR_PROOF.bend` | 0.12 s |
| `LIFE_ANIM_PROOF.bend` | 0.09 s |

Under a tenth of a second, including startup. This is the "several orders of
magnitude" claim from the introduction, made concrete: a proof the size of a
small paper is checked between keystrokes. The tradeoff is the one the language
states openly — Bend does almost no type inference, so you annotate everything
and the checker never has to search. The proof is verbose and the checking is
free.

## ⚠️ "All terms check" is not evidence

A passing proof means the compiler verified your proof *of the type you wrote*.
It says nothing about whether that type is the thing you meant. Prove a false law
and it will happily check.

So the only evidence that the law is real is the other direction: **break the
implementation and watch the gate close.** All three breaks below are made in the
implementation file `life_par.bend` — never in the law:

| change to `life_par.bend` | `bend LIFE_PAR_PROOF.bend` |
|---|---|
| right subtree's offset no longer adds the left half's cells | **Error** |
| leaf start index hard-coded to `0n` | **Error** |
| join concatenates the halves in the wrong order | **Error** |
| (restored) | `All terms check.` |

That table is the actual content of this chapter. The law is a claim; the break
test is what makes the claim mean something.

And it has to be done carefully, because a break test that does not break
anything *passes*. During this book's own writing, one such test replaced the
string `"██"` in the animation — and the file also contains that string in a
comment above the code, so the replacement landed in the comment, the code was
unchanged, and the gate reported success. **A no-op is indistinguishable from a
working gate.** Every break test from here on asserts that the text it replaces
occurs exactly once before it writes:

```python
assert s.count(old) == 1
```

## The law and its proof

```python
{{#include ../life/LIFE_PAR_LAWS.bend}}
```

```python
{{#include ../life/LIFE_PAR_PROOF.bend}}
```

Next: [a second law, and the wall underneath](laws-2.md).
