# The gate, and its edges

The two chapters before this one ended with the same small print: "All terms
check." is the only evidence, and it is not evidence at all. This chapter runs
down what the gate actually guarantees. Every output below is pasted from a
real run of `tools/drift/gate_matrix.sh`, on Bend 2.0.16.

## The distance between two sentences

What a CI job would like to say is: *this property cannot regress.* What the
gate can honestly say is: *this proof checks.* The distance between the two
sentences has three shapes, and each one is a small file.

### The escape hatch

Start with a law that is false — not subtly, plainly:

```python
law false_law:
  for x: Nat
  {x == 1n : Nat}
```

No proof of this exists, so here is an "implementation":

```python
@unsafe
def Laws.false_law(x):
  Laws.false_law(x)
```

It compiles, and `bend PROOF.bend` prints:

```
All terms check, with 1 unsafe annotation.
```

and exits 0. A non-terminating function inhabits any type; `@unsafe` turns off
the termination check; the false law is "proved". This is not a bug and not a
secret — it is the first entry in upstream's `WONTFIX.txt`, under DESIGN:

> **`@unsafe` programs check and exit 0 (#776, #805)**
> The checker prints "All terms check, with N unsafe annotations." and exits
> 0. `@unsafe` is a choice the author made in the source; read the note, not
> the exit code.

Two measured details about the note. First, the count is **book-wide**: one
`@unsafe` def anywhere in the import graph — even one no proof touches —
degrades the message. Second, the count covers more than `@unsafe`: on 2.0.16 a
file containing a `~` template instance prints it too, "until the checker
verifies template expansion itself" (the changelog's words). A template skips
no check; that line is a disclosure, not a hole. But it means the message is
something to read, not a bit to parse.

### The vanishing spec

`LAWS.bend` is the human's file, and the gate is a check on the files it is
handed — whatever is there. Delete the law and see. With the proof def left
behind, the report is:

```
Error:
- expected : '->'
- observed : ':'
Location:
4>| def Laws.add_zero_law(x):
```

A parse error that names nothing. It reads as "add a return type" — the wrong
repair for a law that went missing (this message is filed upstream as
bendlang/bend#850). Delete the def too, and:

```
All terms check.
```

Zero laws checked, all of them fine. What stops the quiet half of this is one
check, added in 2.0.8: a `PROOF.bend` that sits beside a `LAWS.bend` must
import it.

```
$ bend PROOF.bend        # with the import line removed
bend: PROOF.bend must import ./LAWS.bend (see bend --help)
```

That closes "the AI skipped the law file". It cannot close "the law file was
edited", because the law file **is** the spec — and a spec the constrained
thing can edit is not a spec. The gate checks that two files agree; keeping
them in agreement is a social arrangement, and it is the load-bearing part.

### The CI that greps wrong

Three plausible ways to wire the gate into CI, run against the `@unsafe`
fixture above:

| check | on the fixture | verdict |
|---|---|---|
| `bend PROOF.bend`'s exit code | 0 | fooled |
| `grep -q "All terms check"` | matches | fooled |
| `grep -qx "All terms check."` | no match | correct |

The exit code is fooled because the design says so. The substring grep is
fooled because `All terms check, with 1 unsafe annotation.` contains
`All terms check`. Only the exact-line match notices the difference.

## The recipe

```sh
bend PROOF.bend > gate.out 2>&1 || exit 1
grep -qx 'All terms check.' gate.out || exit 1
```

Two lines, one job each. The first fails on compile errors, open laws
(`1 TODO found.`), and the import check. The second insists on the verdict
line exactly — no `with N annotations`, no skip, no partial run. If a future
version rewords the line, this CI goes red; for a check that depends on a
message, that is the correct failure mode, and `gate_matrix.sh` is what
notices it first.

## What the gate does guarantee

Stated with the same care, because it is not nothing:

- **The break tests.** Change the implementation and the gate closes; restore
  it and the gate opens. Five of the six patches the previous chapters record
  — the three `life_par` ones and two of the three `life_anim` ones — were
  re-run on 2.0.16 while this chapter was written, and every one still closes
  the gate. (Each patch asserts it changed exactly one spot before writing,
  and every file was restored byte-identical — the discipline of the
  appendix, re-used.)
- **Open laws are refused.** A declared law without a proof is
  `1 TODO found. The code is incomplete, and not a valid proof yet.` — exit 1.
  A `?TODO` hole is the same.
- **Skipped law files are refused** (the import check above).
- **It is fast.** The two Life proofs check in 0.07 s and 0.06 s —
  re-measured while writing this chapter. None of this is bought with
  patience.

## The library, arriving

The previous chapter stopped at a wall: a law about index safety would need
facts about arithmetic that `Base` does not state, and the wall's height was
the work of writing them. What has changed since those chapters were written
is small but real — the lemmas they had to write by hand are now published
packages on the Bend hub, importable by content hash:

```python
import 0x1ee1b5d0c2a66817bf368b849f3117fc/nat.bend as Nat
```

Six facts about `Nat.add`: zero, successor, associativity, commutativity, and
two of them in the reverse orientation a rewrite needs. Beside it,
`0x89df026edd…/string.bend` carries the `String.append` and `String.reverse`
lemmas that `life_anim`'s proof had to derive, and `0x085d89db…/list.bend` the
`List` analogues. The wall has not moved — index safety needs `Nat.cmp` facts
that nobody has written yet — but the tax is now paid once per ecosystem
instead of once per proof. And a package is importable only as its hash: the
file a proof reads cannot change afterwards, and anyone can re-check a package
by running `bend` on it, because `All terms check.` is a claim any reader can
re-run.

## The three edges

Keep them in view and the guarantee is shaped like this: a change that breaks
a stated property cannot pass unnoticed, provided three things stay separately
true.

1. **No `@unsafe` in the import graph** of anything you gate. It is not a
   scan the compiler does for you; it is a choice in your sources, and one
   `grep` if you want a machine to check it.
2. **The spec file is the humans'.** The compiler can refuse a proof that skips
   its laws; nothing can refuse a law that was deleted. That half is a review
   habit, not a check.
3. **The CI reads the verdict line exactly**, in the two lines above.

The gate is a young instrument, and this chapter is its boundary map: what it
proves, what it only promises, and how to tell which one you are looking at.
Within those edges, "All terms check." means exactly what the previous two
chapters said it means. Outside them, it means whatever you let it mean.

## Running it

```sh
sh tools/drift/gate_matrix.sh
```

Seven fixtures, seven lines, one per case — the false law, the TODO, the
missing import, the emptied spec, the stray `@unsafe`, the stray proof def.
Run it after a `bend update`; the day one of those lines changes is the day
the boundary moved.
