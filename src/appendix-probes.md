# Every deliberately-broken probe, and the error it produces

This book contains a lot of code that does not compile. That is on purpose:
Bend's error messages are precise, local and mechanical, and in many places they
taught us more in ten seconds than the guide did in ten minutes. So every failure
shown in the book is a **real file in this repository**, and every error quoted is
pasted from running it.

This appendix is the index. Run any of them yourself.

```sh
cd basics && bend hello_bad.bend
```

## ❌ does not compile

| probe | what it does wrong | what Bend says |
|---|---|---|
| [`basics/hello_bad.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/basics/hello_bad.bend) | writes the return type `IO<Unit>` instead of `IO(Unit)` | `a declared datatype (unknown: IO)` |
| [`basics/hello_arg.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/basics/hello_arg.bend) | passes a bare `42` where a `String` is wanted | `expected : String` / `observed : U32` |
| [`basics/term_bad.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/basics/term_bad.bend) | a recursion that cannot be shown to shrink | `expected : a decreasing self-call ...` / `observed : loop` |
| [`basics/term_order.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/basics/term_order.bend) | shrinks the right argument, not the leftmost | `expected : a decreasing self-call ...` / `observed : evolve` |
| [`affinity/affine_bad.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/affinity/affine_bad.bend) | uses `x` twice | `expected : x` / `observed : x (consumed more than once)` |
| [`affinity/t9_listonly.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/affinity/t9_listonly.bend) | `List<U32>` (not `List<&2, U32>`) used twice | `expected : xs` / `observed : xs (consumed more than once)` |
| [`affinity/t4_arrplus.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/affinity/t4_arrplus.bend) | puts `+` on an `Array`, which is `Type` | `expected : Data` / `observed : Type` |
| [`affinity/t5_closure.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/affinity/t5_closure.bend) | calls a closure twice | `expected : f` / `observed : f (consumed more than once)` |
| [`affinity/t6_closureplus.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/affinity/t6_closureplus.bend) | puts `+` on a closure | `expected : Data` / `observed : Type` |
| [`affinity/t11_templatemiss.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/affinity/t11_templatemiss.bend) | omits `~` at the *call site* of a `~f` parameter | `expected : -f` / `observed : f (consumed more than once)` |
| [`arrays/exp_arr.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/arrays/exp_arr.bend) | annotates an array read in place: `a[5] : U32` | `expected : a term` / `observed : ':'` |
| [`arrays/exp_arr2.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/arrays/exp_arr2.bend) | destructures an array read: `(a2, v) = a[5]` | `a match cannot scrutinize a computed value: give it its own def` |
| [`arrays/a_fail.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/arrays/a_fail.bend) | binds the write first, then destructures the binder | `a match cannot scrutinize a local binder: give it its own def` |
| [`arrays/d_write.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/arrays/d_write.bend) | treats a write as a pair, like a read | `expected : Sigma<&1, &1, Array<U32>, _ => U32>` / `observed : Array<U32>` |
| [`laws/two_plus_two_open.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/laws/two_plus_two_open.bend) | states the law and stops — the proof line is not written yet | `Error: 1 TODO found.` / `The code is incomplete, and not a valid proof yet.` |
| [`laws/fill_rettype_bad.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/laws/fill_rettype_bad.bend) | gives a law's fill its own return type | `expected : ':'` / `observed : '-'` |
| [`laws/add_zero_bad.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/laws/add_zero_bad.bend) | proves `x + 0 == x` with `{==}` alone | `expected : Nat.add(x, 0n)` / `observed : x` |

Two of these are worth singling out, because they are the cases where the error
message is *less* helpful than Bend's usual standard:

- **`hello_bad.bend`** points at the signature line and says `unknown: IO`. It
  never mentions angle brackets, so it reads as though `Base` failed to import.
  The rule the message does not state: **`IO(Unit)` in a signature, `do IO<Unit>:`
  in a do block.**
- **`t11_templatemiss.bend`** says `consumed more than once`, which reads as
  "closures cannot be called twice". The actual complaint is that `~` is missing
  at the call site. The corrected form is `twice(~(x => (x + 1 : U32)), 40)`.

## ⚠️ compiles, runs, and lies

The most instructive category. Nothing here fails — which is the problem.

| probe | what it does | what you get |
|---|---|---|
| [`basics/pat_bad.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/basics/pat_bad.bend) | `case 1n+p` used to mean "equal to 1" | prints **`1`** — it does not |
| [`basics/esc_bad.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/basics/esc_bad.bend) | `\033` meant as the ESC byte | prints **` 33`** — a space, then `33` |

**`pat_bad.bend`.** Bend's `Nat` patterns are `0n` and `1n+p`, where the second
means *"at least 1"*, not *"exactly 1"*. The obvious way to write a three-way
dispatch —

```python
  match n:
    case 0n:  ...
    case 1n+p: ...
    case 2n+p: ...
```

— compiles, runs, and **silently swallows `n = 1` into the second case**, because
`1n+p` matches `1` with `p = 0n`. The `2n+p` arm is only reached for `n ≥ 2`.
There is no warning. This is the closest thing to a footgun in the language, and
it is a direct consequence of `Nat` being a Peano datatype rather than a machine
integer.

**`esc_bad.bend`.** Bend's string escapes are exactly
`\n \t \r \0 \\ \' \" \u{...}`. There is **no `\e` and no `\x1b`**. `\033` does
not error — it parses as `\0` followed by the two literal characters `33`, so you
get a NUL byte and the text `33`. On a terminal the NUL is invisible and you see
a space and `33`. The working spelling is `\u{1B}`.

Both of these are exactly the shape to watch for: **a wrong program that runs and
produces output that looks plausible.** The animation chapter hit the same class
of bug — a mirrored render, correct in `y`, wrong in `x`.

## The proofs are probes too

`life/LIFE_PAR_PROOF.bend` and `life/LIFE_ANIM_PROOF.bend` are not just proofs;
they are two more gates in this same list. Each is paired with a table of
deliberate changes to the *implementation* that it must reject. Those tables are
in [Your first law and proof](laws-1.md) and
[A second law, and the wall underneath](laws-2.md), and re-running them is part of
maintaining this repository.

One caveat, learned the hard way three times: **a break test that silently fails
to replace anything passes.** Confirm `s.count(old) == 1` before writing. The
full story is in `life/README.md` in the repository.
