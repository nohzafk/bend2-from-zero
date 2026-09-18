# A second law, and the wall underneath

The previous chapter's law compared two functions that both compute Life. This
one compares two functions that both compute **a string**, and it is the more
interesting of the two — because the thing being proved is not an optimisation
detail, it is a constraint we discovered the hard way.

## The setup

The animation's renderer builds a frame backwards and reverses once at the end,
because appending cell by cell in order would be O(frame²). Two levels are
reversed in that one pass: the order of rows, and within a row the order of
cells.

The law has to compare that against something. So the first job is to write the
**spec** — the same frame, written the slow and obvious way, with no cleverness
to get wrong:

```python
def spec_row(+r: List<&2, Nat>) -> String:
  match r:
    case Nil{}:
      SNil{}
    case Con{h, t}:
      String.append(Anim.cell(h), spec_row(t))

def spec_rows(+rs: Anim.Rows) -> String:
  match rs:
    case Anim.RNil{}:
      SNil{}
    case Anim.RCons{r, t}:
      String.append(spec_row(r), String.append("\n", spec_rows(t)))
```

Two structural recursions, appended in order. Nobody would use this — it is
quadratic — and that is exactly what makes it a good specification. It is
obviously right.

Then the law is one line:

```python
law frame_is_spec:
  for +rs: Anim.Rows
  {Anim.frame(rs) == String.append("\u{1B}[H", spec_rows(rs)) : String}
```

Fast renderer equals cursor-home escape followed by the slow renderer. This is
the same shape as the previous chapter: **implementation on the left, obvious
specification on the right.**

## The palindrome constraint is a theorem

Look again at the comment in `life_anim.bend`:

> every cell must be a palindrome. `"██"` and `"  "` both are; change to `"▐█"`
> and every row flips internally (measured).

In the previous chapter that was a note in the source and a paragraph in the
book. Here it is a lemma:

```python
def pick_pal(b: Bool)
  -> {Bool.pick(String, b, "██", "  ") == String.reverse(Bool.pick(String, b, "██", "  ")) : String}:
  match b:
    case False{}:
      {==}
    case True{}:
      {==}

def cell_pal(v: Nat) -> {Anim.cell(v) == String.reverse(Anim.cell(v)) : String}:
  %pick_pal(Nat.is_eq(v, 1n)) : {Anim.cell(v) == _ : String}
  {==}
```

*A cell is equal to its own character-reversal.* The proof is two cases and both
are `{==}`, because `"██"` and `"  "` are each their own reverse — the checker
just looks.

Note what this buys. Change `cell` to return `"▐█"` and `cell_pal` no longer
holds, so `frame_is_spec` no longer goes through, and the program **fails to
prove**. The constraint that was a comment for two chapters is now a
compile-time obligation. It is not decoration: the break test at the end of this
chapter changes exactly that one string and the gate closes.

## Five of the seven lemmas are not about Life

| lemma | why it exists |
|---|---|
| `append_nil2`, `append_assoc2` | Base has no `String` lemmas at all |
| `reverse_go_spec`, `reverse_append2` | `String.reverse` goes through an accumulator, so it is stuck on a variable |
| `pick_pal`, `cell_pal` | Base has nothing about `String.reverse` of a literal — and this is the palindrome constraint |
| `rowrev_spec` | this law's own: `reverse(rowrev(r, acc))` is the row in order, then the reversed accumulator |
| `inner` + `frame_is_spec` | this law's own: the accumulator invariant over `Rows` |

**Only two of the seven are about frames.** The rest is standard library that
does not exist yet, re-derived here because there was no import to reach for.

That is the honest cost of proving in Bend today, and it should be counted before
choosing what to prove. The Bend README says its Lean formalisation lags the
TypeScript implementation; this is what that looks like from the outside. It is
not a flaw in the design — it is a young language whose lemma library has not
been written.

## Two things to know when writing the proofs

**Accumulator functions need the accumulator spelled out.** `String.reverse`
is not a structural recursion — it calls `reverse.go(s, acc)`. That means a goal
containing `reverse(x)` for a variable `x` is stuck, and the invariant has to be
generalised over the accumulator before induction will go through. Hence
`reverse_go_spec(s, +acc)`, and `rowrev_spec(r, +acc)`, and `inner(rs, +acc)`
which is the law generalised over the accumulator:

```python
def inner(rs: Anim.Rows, +acc: String)
  -> {String.append(String.reverse(acc), Laws.spec_rows(rs)) == String.reverse(Anim.framerev(rs, acc)) : String}:
```

The law is then `inner(rs, SNil{})` with the accumulator at empty, which is one
line of proof.

**Parameter modifiers follow use, not meaning.** A parameter that appears only in
the *type* gets `-`; one that is used more than once in the **proof body** needs
`+`. `reverse_go_spec`'s `acc` looks erased — the type mentions it twice, which is
why it is tempting to write `-acc` — but it appears in the recursive call, so it
must be `+acc`. The rule is mechanical once you look at the body, and wrong
every time you reason about it semantically.

## Reading a failed proof

When a rewrite does not apply, the error prints `expected` and `observed` as
**fully unfolded terms**. `cellnext` alone unfolds to thousands of characters, so
the part that actually differs is somewhere in a wall of text. Measured, on a
deliberately miscalled lemma:

| | size |
|---|---|
| raw error | 14,151 bytes |
| after `elide_errors.py` | 1,576 bytes |

The script in the directory folds those runs down to `CELL`:

```sh
bend LIFE_PAR_PROOF.bend 2>&1 | python3 elide_errors.py
```

This is a papercut rather than a language feature — the error is *complete* and
*correct*, it is just rendered in a form no human can diff. Worth knowing before
you spend an hour staring at one.

## The break tests

Every one of these is a change to the **implementation** `life_anim.bend`:

| change | `bend LIFE_ANIM_PROOF.bend` |
|---|---|
| drop the final `String.reverse` (row order reversed) | **Error** |
| reverse each row as well (the mirror bug from the animation chapter) | **Error** |
| `cell` returns the non-palindrome `"▐█"` | **Error** |
| (restored) | `All terms check.` |

The second entry is the one to look at twice. **The bug that was found by eye,
after it had already shipped into a working animation, is now caught at compile
time** — by a law whose proof takes 0.09 seconds.

That is the whole claim of this part of the book, and it is worth stating without
inflation: the law does not make the renderer correct. It makes *one specific
property of it* something you cannot break by accident and not notice.

## Why we stopped here

The obvious next law was index safety for `at()` — "every index stays within
`0 .. w*h`". It is a good law, it is the kind the Bend README advertises
(`array_set() may never be called out-of-bounds`), and we did not write it.

Here is the wall. Both laws needed library lemmas that Base does not have. But
the *difficulty* of the two taxes is not comparable:

| what has to be proved | shape |
|---|---|
| `a < a + 1` | one induction, `{==}` to close — easy |
| `Nat.add` associative / commutative | one induction each — done above, in `add_assoc` |
| `Nat.mod` result stays `< B` | induction, **and an inner case needing `r ≤ m + r`, which goes through `Nat.cmp`** — two variables at once |
| `a < h`, `b < w` ⟹ `a*w + b < h*w` | distribution of `Nat.mul` plus monotonicity of `Nat.cmp` — more multi-variable induction |

The `String` lemmas were all **structural**: `append` matches on its first
argument, so induction over that argument closes the proof. The arithmetic
lemmas have to go through `Nat.cmp`, whose recursion compares two numbers and
therefore needs induction over a *pair*. Same wall, two different heights — one
is an afternoon, the other is not obviously finishable in one.

So the choice of which law to prove is not free, and it is not about how
interesting the law is. It is about how far the lemma you need is from a
structural recursion. **Prefer laws whose proof obligation reduces to structural
induction.**

## The law and its proof

```python
{{#include ../life/LIFE_ANIM_LAWS.bend}}
```

```python
{{#include ../life/LIFE_ANIM_PROOF.bend}}
```
