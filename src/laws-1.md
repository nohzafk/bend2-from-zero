# Your first law and proof

The last chapters left two claims dangling.

The first is from [Is it actually parallel?](life-parallel.md). We said the
fork-join tree computes the same cells as the sequential loop. Our evidence was
running both and counting live cells — `live=5` every time. That is evidence
about the handful of grids we happened to try. It is not a statement about the
code.

The second is from [Making it move](life-anim.md). The renderer only works if
every cell is a palindrome, and that fact lives in a comment above `cell`.
Change `"██"` to `"▐█"` some day — the chapter's own words, "a perfectly
reasonable thing to do" — and each row flips internally. Nothing between your
edit and your terminal will object.

Both claims are real, both are load-bearing, and both are the kind that break
silently. Bend has a facility for exactly them: you write the claim down in a
form the compiler reads, the compiler refuses to build until the claim is
**proved**, and it refuses again the moment an edit makes the proof stop
working.

That facility is also the reason this language exists. [What Bend 2
is](what-is-bend.md) quotes the pitch: code written by machines, which you will
not read, and which therefore has to be *checked* instead of reviewed. The type
checker already covers one half of that — a machine writes a program, and the
types hold. Laws and proofs are the other half: a machine writes a program, and
the fact that it computes what you asked holds too. That bet is about a future
this book does not try to test. What it tests is the mechanism — and the
mechanism starts here, on claims you have already made yourself.

One thing to say before the first definition, because it is the question a
tutorial owes you: **no law is required to write a Bend program.** Every
chapter so far ran without one, and the compiler never asked. You reach for a
law when a claim has three properties at once:

- it is **load-bearing** — the program is wrong, not merely different, if it breaks;
- it is **not already held by a type** — "this function returns a `String`" is
  a claim too, and the type checker has that one;
- a test can only **sample** it — three grids out of infinitely many, one
  rendering run out of a million.

The palindrome constraint and the parallel-tree equality are both that shape,
and they are what the rest of this part is spent on. Three chapters: how to
write a law and a proof (this one), what they cost (the next), and what the
gate actually guarantees (the last).

## The words, first

Four words carry everything below, and they are worth pinning down before
anything else is said.

A **proposition** is a claim. Here is one about a number `x`:

```python
{Nat.add(x, 0n) == x : Nat}
```

Read it as a sentence: *the value of `Nat.add(x, 0n)` is the value `x`*. It
looks like a boolean test; it is not one. It is a **type** — the type "these
two terms are the same `Nat`". Hold that thought for one paragraph.

A **proof** is a value of that type. So writing a proof is not a separate
activity with its own language: because the claim is a type, a proof is **an
ordinary `def`** — checked exactly the way every `def` in this book was
checked, against its type. No tactics, no separate proof editor.

A **law** is a proposition that has been given a name and declared as an
obligation:

```python
law add_zero:
  for x: Nat
  {Nat.add(x, 0n) == x : Nat}
```

The `for` line introduces the variable the claim is about — `for x: Nat` reads
"for every `x` of type `Nat`". While no proof exists, the law is an **open
claim**, and the compiler reports it as one when you run the file.

A **lemma** is a proof whose job is to be quoted inside other proofs. The word
names a role, not a mechanism: any proof can be quoted, and the small facts
that get quoted are the ones everyone calls lemmas.

(The propositions in this book are all equations. A proposition can be any type
at all; equations are what these claims needed.)

Why any of this works is an idea borrowed from proof assistants — Lean, Rocq —
and you are not expected to have met one. One paragraph. In that tradition a
claim and a type are the same notion: a proposition **is** a type, and a proof
**is** a term of that type. Bend takes the idea as its own, which is why the
machinery checking your claims is the same type checker that has been checking
your programs all along — and why checking here is as fast as type checking
here, rather than the minutes a dedicated proof assistant might take.

## The smallest law

A law with no variables at all. Two plus two is four:

```python
import Base

law two_plus_two:
  {Nat.add(2n, 2n) == 4n : Nat}
```

Put that in a file and run it. The compiler says precisely what is missing:

```
$ bend two_plus_two.bend
Error: 1 TODO found.
The code is incomplete, and not a valid proof yet.
```

That is what "open claim" means mechanically: the file does not compile until
a proof exists. Here is the proof. It is one line.

```python
def two_plus_two():
  {==}
```

Nothing connects the two blocks except the **name**. A `def` with no return
type whose name is a law *is* the proof of that law — no import, annotation or
registration. The connection is strict enough that the reverse is enforced
too: a `def` named after a law may not carry a return type at all, because the
law already supplies it.

```python
# ❌ a fill with its own return type -- rejected
def two_plus_two() -> {Nat.add(2n, 2n) == 4n : Nat}:
```

```
Error:
- expected : ':'
- observed : '-'
```

(This rejection and the `{==}` refusal further down are kept as runnable
files under `laws/` — the errors are indexed in
[the appendix](appendix-probes.md).)

Run the file again, and the open claim is closed:

```
All terms check.
```

`{==}` is the proof of `{x == x}`: "both sides are the same term". It closes
this goal because the checker *computes* — `Nat.add(2n, 2n)` reduces to `4n`,
the goal becomes `{4n == 4n}`, and the two sides are literally identical.
When a goal is not closing and you want to see exactly what the checker is
looking at, replace the body with `?anything`:

```python
def two_plus_two():
  ?goal
```

```
Error:
- expected : {4n == 4n : Nat}
- observed : ?goal
```

The `expected` line is the goal in the form it has **right now** — note that it
reads `4n == 4n`: the computation already happened, and this is what remains to
be said. Keep this instrument nearby; it answers "what do I owe?" at any point
in a proof. The second instrument is `?TODO`, a hole that reports itself as
`1 TODO found` — the same message as an unfilled law.

## The first proof with a variable

`two_plus_two` proves nothing interesting, because the checker can compute both
of its sides. Interesting claims have variables in them — like the first fact
the Life proof needed, which you can now derive for yourself:

```python
law add_zero:
  for x: Nat
  {Nat.add(x, 0n) == x : Nat}
```

For every `x`: `x + 0` is `x`. Try the one-liner:

```python
def add_zero(x):
  {==}
```

❌ The compiler refuses:

```
Error:
- expected : Nat.add(x, 0n)
- observed : x
```

Read the complaint: `{==}` demanded that the two sides *be* the same term, and
they are not, because one of them cannot even run. `Nat.add` matches on its
**first** argument, and that argument is the unknown `x` — there is nothing to
match, so the addition is stuck and sits in the goal unevaluated. (Note also
that the fill takes the law's binder as its parameter, left untyped: the law
already says `x: Nat`, and the def does not have to say it again.)

That one mechanical fact — *which argument a function matches on decides when
it can compute* — matters more than any other in this part of the book.

To prove a claim "for every `x`", you look at how the value can be built. `Nat`
has two ways to be: zero, or one-plus-something-smaller. So the proof has two
cases, and "look at how the value is built" is spelled `match`:

```python
def add_zero(x):
  match x:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}
```

**Case `0n`.** Both sides compute — `Nat.add(0n, 0n)` is `0n` — so `{==}`
closes it.

**Case `1n+p`.** Here `x` is one more than a smaller number `p`, and the goal
is now `{1n+Nat.add(p, 0n) == 1n+p}`: the `+ 0` is still stuck, this time on
`p`. The move to look at twice is the line quoting **`add_zero` itself**, at
`p`:

```python
%add_zero(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
```

Calling the proof you are currently writing, on a smaller value, is
**induction** — and the "smaller" requirement is not new: it is the decreasing
argument rule from [Numbers and patterns](basics-numbers.md), applied to the
proof's own recursive call. `p` is what `1n+p` is made of, so it shrinks, and
the compiler is satisfied for the same reason it was satisfied by every
recursive function in this book.

What the line does: `add_zero(p)` is the statement "`p + 0` is `p`", and the
rewrite uses it to replace the `p` on the goal's right — the spot marked `_` —
with `Nat.add(p, 0n)`. The right side becomes `1n+Nat.add(p, 0n)`, identical to
the left, and `{==}` closes the case.

Dwell on that direction for a second, because it is the one thing in the
mechanics that surprises everyone: the rewrite made the goal *bigger*, not
smaller. `%` does not simplify. It **moves the goal toward a shape you choose
when you write the lemma**. The rule is stated in full below, but you have now
seen it work.

And that is the whole toolkit. `{==}` is the only axiom; `%` is the only rule;
every proof in this book, however long, is those two moves repeated — *move one
side until it equals the other, one lemma at a time*.

## Two containers for a proof

A proof can be kept in two ways, and the difference is when you commit to the
claim, not how the proof is checked.

**The law form** — the claim is declared, and the proof fills it in:

```python
law add_zero:
  for x: Nat
  {Nat.add(x, 0n) == x : Nat}

def add_zero(x):
  ...           # the match you just wrote
```

The claim is an obligation from the moment it is written: while the proof is
missing, the file reports `1 TODO found`.

**The plain-def form** — no law anywhere, just a fact:

```python
def add_zero(a: Nat) -> {Nat.add(a, 0n) == a : Nat}:
  ...           # same match, same two cases
```

Same proof, one line different: the proposition appears as the def's **return
type** and has no name in the file. Nothing fails while it does not exist —
and once it exists, it can be quoted with `%` like any law's proof.

The law form is for claims that must not be forgotten: requirements, stated up
front, that fail the build until they are filled. The plain-def form is for
facts discovered *while* proving something else — which is what the word
**lemma** is for in practice. The Life proof files use both, and the division
is visible in them: `tree_is_serial` is a law, while `add_zero` and
`add_assoc` are plain defs, written on the spot when the proof needed them.

Bend's convention for a project puts the two forms in two files at the root:
`LAWS.bend` states the laws — written when the requirement is stated, the
human's file — and `PROOF.bend` imports it and holds the fills plus any helper
lemmas. `bend PROOF.bend` is the gate: it answers `All terms check.` only when
every law is filled and every proof holds. (The Life files follow the
convention with a subject prefix — `LIFE_PAR_LAWS.bend`, `LIFE_PAR_PROOF.bend`
— because this repository proves things about more than one subject.)

## The claim we actually made

Now the dangling claim from the parallel chapter, written as a law:

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

Read it as a sentence. *For any depth, grid, width, height, block size and
start index: the fork-join tree produces exactly the list that one sequential
loop over the same range produces.*

(The binders carry the same quantity marks as anywhere else — `for +d` says
how often the proof may use `d`; choosing them is the next chapter's subject,
so write them as the example does until then.)

(A note for later, because it is a trap: `Base` uses the same `law` keyword 72
times to declare *type families* rather than propositions. In user code those
are written with `def` — `def Tree(d: Nat) -> Data:`. Both uses are the same
idea, a declaration you fill in, but the mechanism is not interchangeable. See
[What Base does not give you](appendix-base-gaps.md).)

And the proof begins the way the small one did — a `def` named after the law,
with the law's binders as parameters:

```python
def Laws.tree_is_serial(d, g, w, h, blk, k):
  match d:
    case 0n:
      {==}
    case 1n+p:
      ...
```

(The `Laws.` prefix is the module: the law is declared inside `LAWS.bend`,
imported under the alias `Laws`, and a fill is named after the law including
the module it came from.)

Depth zero needs no work — a tree of depth zero *is* one leaf, and one leaf
*is* the loop, so `{==}` closes that case. At depth `p + 1` the tree is two
depth-`p` trees joined, while the spec is still one undecomposed loop.
Something has to split that loop in two. That is the first non-trivial lemma.

## `%`: one rule, and how to aim it

You have used `%` once — the self-quote inside `add_zero`. Here is the rule
stated once, in full, because every remaining step of every proof is it:

> **A lemma `e : {a == b}` applied as `%e(...) : P` replaces `b` with `a` in the
> goal.** `P` is the goal written out with the occurrence of `b` replaced by `_`.

So `_` sits exactly where the lemma's **right-hand side** was. Which gives the
working rule for writing lemmas:

> **Write a lemma as `{what you want == what is there now}`.**

The right side is what the goal currently contains; the left side is what
replaces it. Getting this backwards gives an error that says so plainly —
`expected` and `observed`, with the two terms — and the fix is to swap them.

In the proof, the needed lemma splits a sequential loop in two:

```python
%cells_add(g, w, h, Par.cells_in(p, blk), Par.cells_in(p, blk), k) : {Par.tree_cells(1n+p, g, w, h, blk, k) == _ : List<&2, Nat>}
```

`cells_add(...)` has conclusion
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

Two lemmas in the proof file exist for reasons that have nothing to do with
Life:

```python
def add_zero(a: Nat) -> {Nat.add(a, 0n) == a : Nat}:
def add_assoc(a: Nat, -b: Nat, -c: Nat) -> {Nat.add(Nat.add(a, b), c) == Nat.add(a, Nat.add(b, c)) : Nat}:
```

You have met `add_zero` already — it is the fact you derived above, and the
reason it exists is the one you watched fail: `Nat.add` is stuck when its first
argument is a variable, so an equation containing `Nat.add(k, 0n)` for a
variable `k` cannot be closed by computation, only by a lemma. `add_assoc` is
the same diagnosis one level deeper: the offsets in the proof meet as
`(k + 1) + q`, and no amount of computation turns that into `k + (1 + q)`.

Both are plain defs, not laws, because they were *needs*, not requirements —
the distinction from "Two containers" doing its work.

This is worth naming because it recurses through everything below. **Base has
no lemma library.** There is no `Nat.add_zero` to import; there are no standard
facts about `Nat.add`, `Nat.mul`, `Nat.mod` or `Nat.cmp`. Every proof that
touches arithmetic brings its own small arithmetic with it. For this law that
was two lemmas, both easy. For the law we *did not* write — index safety — the
same beginning leads into `Nat.cmp` and iterated induction on two variables at
once, and that is a different order of work. We will come back to that.

## Running it

```sh
cd life && bend LIFE_PAR_PROOF.bend
```

```
All terms check.
```

The law is in `life/LIFE_PAR_LAWS.bend`, the proof — lemmas included — in
`life/LIFE_PAR_PROOF.bend`; both are printed in full at the end of this
chapter.

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
It says nothing about whether that type is the thing you meant. Prove a false
law and it will happily check.

So the only evidence that the law is real is the other direction: **break the
implementation and watch the gate close.** All three breaks below are made in
the implementation file `life_par.bend` — never in the law:

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
