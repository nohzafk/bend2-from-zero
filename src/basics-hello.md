# A first program

Here is the smallest Bend program that does something.

```python
{{#include ../basics/hello.bend}}
```

Save that as `hello.bend` and run it:

```sh
$ bend hello.bend
hello, bend 2
```

Five lines, and at least three of them are doing something you have not seen
before. Let's take them one at a time.

## `import Base`

The standard library. In Bend 2 the core library is not loaded for you, and it
is called `Base`. You will write this line in every file in this book.

There is no `Base.` prefix at the call site — `import Base` brings the names in.

## `def main()`, and a type that means something

```python
def main() -> IO(Unit):
```

`def` defines a function. `main` is the one the runtime calls. The part to slow
down on is `-> IO(Unit)`, because it is not decoration — it is the entire
answer to "how does this program run".

Read it as: **a program that performs input and output, and produces nothing
interesting.** `Unit` is the type with exactly one value in it, the way a
Python function returning `None` has nothing to hand back.

## The first idea that is genuinely new: an action is a value

Now look at the body.

```python
  do IO<Unit>:
    IO.print("hello, bend 2")
```

If you come from Python, Ruby or Go, you will read `IO.print("...")` as "print
this". **It is not that.** It is a *value* — a description of a print — and its
type is `IO(Unit)`, the same type `main` returns.

Nothing has happened when that line is evaluated. `IO.print("hello, bend 2")` is
a **recipe**, not a meal. The only reason the text appears on your screen is
that it is the last thing in the block, so it becomes the value of `do IO<Unit>:`,
which becomes the return value of `main`, and the runtime — which knows what to
do with an `IO(Unit)` — runs it.

This is why `main`'s type is `IO(Unit)` rather than `Unit`. The type is what
tells the runtime "there is something to perform here". A `main` returning a
plain `Nat` has nothing to perform; the CLI just prints the number. (You met
that in the setup chapter.)

It will feel like ceremony for now. It stops feeling like ceremony the moment
you want to know, by looking at a function's type, whether it can touch the
outside world. In Bend, that question has a one-word answer, and it is written
down.

`do IO<Unit>:` is a block of such actions, run in order, top to bottom. Every
line in it produces a value of some type; the block's own value is the last
one.

## What `IO.print` actually prints

Run this and look very carefully:

```python
import Base

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("X")
    IO.print("Y\n")
    IO.print("Z")
```

```
X
Y

Z
```

There is a blank line after `Y`. Here are the raw bytes:

```
58 0a 59 0a 0a 5a 0a          X\n  Y\n  \n  Z\n
```

So **`IO.print` appends a newline of its own.** `IO.print("X")` writes
`X` plus `\n`; `IO.print("Y\n")` writes `Y\n` plus `\n`, which is your blank
line. There is no separate "print without a newline" in what this book uses —
and when we get to the animation chapter, that trailing newline is one of the
things that decides how the frame is built.

## ❌ Two things that do not compile

### The bracket trap

Bend uses **two different kinds of bracket**, and they are not interchangeable:

```python
import Base

def main() -> IO<Unit>:
  do IO<Unit>:
    IO.print("hello, bend 2")
```

```
Error:
- message  : a declared datatype (unknown: IO)
Location: main
5>| def main() -> IO<Unit>:
6 |   do IO<Unit>:
```

This one is worth meeting early, because the error message is actively
misleading. `a declared datatype (unknown: IO)` reads like "you forgot to
import `Base`". What actually happened is the **angle brackets in the return
type**.

The rule:

- in a **signature**, a type is applied with **parentheses**: `IO(Unit)`,
  `List(Nat)`;
- in a **`do` block**, and in some other positions, it is written with **angle
  brackets**: `do IO<Unit>:`, `List<&2, Nat>`.

The compiler points at the signature line and never mentions the brackets. The
same mistake cost this book's author a bisection session, and it is preserved
in the repository as [`basics/hello_bad.bend`](../basics/hello_bad.bend).

### `42` is not a `Nat`

```python
def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(42)
```

```
Error:
- expected : String
- observed : U32
Location: main
6 |   do IO<Unit>:
7>|     IO.print(42)
```

Two facts, and only one of them is the obvious one.

The obvious one: `IO.print` wants a `String`. The second one: **`42` is a
`U32`.** Bend's bare integer literals are 32-bit unsigned integers, and a `Nat`
is written with a trailing `n`:

```python
IO.print(Nat.show(42n))    # 42
IO.print(U32.show(42))     # 42
IO.print(Nat.show(7n + 5n))  # 12
```

So there is no silent widening, no "it's just a number". Every numeric literal
in Bend announces its type in the source, and mixing them is an error — not a
conversion. This file is kept as
[`basics/hello_arg.bend`](../basics/hello_arg.bend).

## Why you have to write all this out

You have now written a program that a Python programmer would write in one line,
and you had to annotate two types and choose a numeric suffix. Two things are
worth knowing about that trade.

**Bend does almost no type inference.** The documentation says so, and it is not
an oversight — it is the mechanism behind the claim that Bend *checks* faster
than any other proof assistant. A checker that never has to search for a type is
a checker that never has to search, period.

**The errors are local and precise.** Look again at both mistakes above: each
one names the expected type, the observed type, the enclosing def, and points at
a line. Neither one required you to trace through a call stack. You are paying
in keystrokes and being repaid in error messages.

That is the deal Bend offers all the way through, and the proof chapters at the
end are where it is paid out in full.

## The files

| | |
|---|---|
| [`basics/hello.bend`](../basics/hello.bend) | the program above |
| [`basics/hello_bad.bend`](../basics/hello_bad.bend) | ❌ `IO<Unit>` in the signature |
| [`basics/hello_arg.bend`](../basics/hello_arg.bend) | ❌ `IO.print(42)` |

Next: [numbers and patterns](basics-numbers.md) — where Bend's most load-bearing
syntax, the `n` suffix on a `match` pattern, makes a promise about termination.
