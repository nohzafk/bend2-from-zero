# Inside a `do` block

You have been writing `do IO<Unit>:` since the first chapter, and the book
told you to read it as "a block of actions, run in order" and left it there.
This chapter is where that is taken apart — not because you need it to write
Bend (you do not; the sugar works with no theory behind it), but because the
whole design of effects in Bend fits in one page once you see it: there is
no sequencing primitive in the language at all, and `do` is a small amount
of sugar over two ordinary defs.

Recall the idea from the first program: an action is a **value**.
`IO.print("hi")` does not print; it is a recipe whose type is `IO(Unit)`.
The question that chapter deferred is: what *consumes* a recipe? Two defs
in `Base` are the entire answer.

## The two defs that run everything

Ask `bend base` for them:

```python
def IO.pure(-A: Type, x: A) -> IO(A):
  R => k => k(x)

def IO.bind(-A: Type, -B: Type, m: IO(A), f: A -> IO(B)) -> IO(B):
  R => k => m(R, x => f(x, R, k))
```

Read `IO.bind` in imperative terms, ignoring the odd shape of its body for
a moment: it takes an action `m`, a function `f` from the action's result
to the next action, and delivers **the result of running `m`, fed into
`f`**. That is sequencing. `IO.pure` is even simpler: it wraps an ordinary
value in an action that, when run, produces it.

Now the odd shape. An `IO(A)` is a function that takes two arguments:

- `R` — the type the whole program ultimately produces;
- `k` — **the rest of the program**, as a function from the action's value
  to that rest.

So `IO.bind`'s body `R => k => m(R, x => f(x, R, k))` says: run `m` with the
same `R` and a continuation `x => f(x, R, k)` — that is, *hand `m`'s result
to `f`, and give the result of `f` the continuation that was meant for us*.
"Hand this action what comes next" is the whole trick, and it is why a
sequence of steps runs top to bottom: the next line literally is the
continuation of the previous one. Bend has no sequencing primitive
underneath; the appearance of one is manufactured by this plumbing.

## What the block compiles into

With those two defs in place, the block syntax can be defined as pure
rewriting. From the guide, verified against the compiler by running both
sides:

> A `do M<xs.., R>:` block desugars each `x : A <- v` into `M.bind(xs..,
> A, R, v, x => ..)` and each `return e` into `M.pure(xs.., R, e)`, so any
> type with those two defs works: `IO`, `Maybe`, `Result`, or your own.

Concretely, this block:

```python
def greet(name: String) -> IO(String):
  do IO<String>:
    IO.sleep(1000)
    return "Hello, " ++ name
```

means exactly:

```python
def greet(name: String) -> IO(String):
  IO.bind(Unit, String, IO.sleep(1000), _ => IO.pure(String, "Hello, " ++ name))
```

Two rules, and nothing else in `do` is magic:

- `x : A <- v` — run the action `v`, bind its result to `x` for the rest
  of the block. Compiles to `IO.bind`.
- `return e` — produce the plain value `e` as the block's result. Compiles
  to `IO.pure`.

A line that is neither — a bare step like `IO.sleep(1000)` — binds to a
name nobody uses, which is why the block reads as "statements".

## The header's arguments

`do IO<Unit>:` — three things in that header, none of them decoration:

- `IO` names the family: it fixes **which** `.bind` and `.pure` the block
  desugars to.
- `Unit`, the **last** argument, is `R` — the block's own result type. It
  is what a `return` in the block must produce, and the desugaring passes
  it as the last argument of every bind it generates.
- any leading arguments (`xs..`) are passed along to both, unchanged.

That last rule is not decoration either; `Maybe` uses it. This def, which
reads two strings as numbers and short-circuits on the first failure:

```python
{{#include ../basics/add_strs.bend}}
```

runs as `Maybe.bind(&2, U32, U32, U32.read(a), x => ...)` — the quantity
`&2` rides along into both calls because the header carries it. The
successful and failing runs, measured — the second is
[`basics/add_strs_bad.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/basics/add_strs_bad.bend),
the same def called with a string that is not a number:

```
$ bend add_strs.bend
Some(42)
$ bend add_strs_bad.bend
None
```

The empty result came from `Maybe.bind`'s own definition — its
`case None{}: None{}` skips the continuation entirely, which is the whole
of "fail fast" in one line of `match`.

## What the header is *not*

Two negative facts, both probed, both worth knowing because each one
looks like the opposite from the outside:

- **The header is not instantiating a datatype.** `IO` is a function, not
  a datatype, and there is nothing to instantiate — yet `do IO<Unit>:`
  is correct, and `do IO(Unit):` is refused with `expected : '<'`. The
  `<>` here is the *header's own grammar*, the same for every monad; it
  does not make the header a datatype application. This is the one place
  the two brackets of the [types chapter](basics-types.md) genuinely
  part ways.
- **The header is not type-checked against the body.** When a block has
  no `<-` and no `return`, the desugaring has nothing to emit and the
  header is erased entirely — this compiles and runs:

  ```python
  def main() -> IO(Unit):
    do List<Unit>:      # List is a datatype with no .bind
      IO.print("x")
  ```

  Add one bind and it fails — `expected : a defined name`, on
  `List.bind` — naming the missing def, not the brackets (kept as
  [`basics/do_list_bind.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/basics/do_list_bind.bend)). The error will
  tell you exactly what a do-block header is: *a name for a `.bind`/`.pure`
  pair, plus arguments for them.*

## Why the book made you wait for this

Because the two ideas it rests on had to exist first. "An action is a
value" is the first chapter's job, and the machinery that runs those
values — the event loop that interleaves computations without threads —
is the next chapter's subject. The desugaring is the seam between them:
`do` manufactures the chain of continuations, and the loop is what drives
it. With both ends in place, [effects.md](effects.md) can talk about
timing instead of syntax.

Next: Effects, and the event loop.
