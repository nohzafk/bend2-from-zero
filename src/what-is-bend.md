# What Bend 2 is, and why this book

Bend's README makes four claims. They are worth reading carefully, because the
rest of this book is arranged around testing them.

| Claim | In Bend's words |
|---|---|
| It is **fast** | *"be as fast as C on the CPU, as fast as CUDA on the GPU"* |
| It **checks** fast | *"outperform every proof assistant by several OOMs"* |
| It is **parallel** | *"No threads, no locks, no kernels to write"* |
| It **blocks mistakes** | *"By forcing your AI to write a correctness proof"* |

The last one is the one everything else serves. If a machine writes your code,
you cannot review it by reading — there is too much of it, and you are the
slowest component in the loop. So Bend's answer is not better review. It is to
make the *intent* machine-checkable: you write down a **law** your program must
obey, and the compiler refuses to build the program unless a **proof** of that
law is present.

That is why the other three claims are in the list. Proof checking is normally
so slow that nobody does it while coding — if checking took minutes, you would
not run it on every edit, and the whole idea collapses. And a language whose
proofs are cheap but whose programs are slow does not get used either.

## What it looks like

If you have written Python, Swift or Rust, Bend's syntax will not slow you
down:

```python
type Shape is Data:
  Circle{r: U32}
  Square{s: U32}

def area(x: Shape) -> U32:
  match x:
    case Circle{r}:
      (3 * r * r : U32)
    case Square{s}:
      (s * s : U32)
```

`match`, braces, `def`, type annotations. It reads.

What it *thinks* like is a different matter. Bend is closer to Lean or Haskell
than to Python: pure, no mutation, datatypes with real structure, and the same
machinery proving your program correct as would prove a theorem. And its
resource handling — who may copy a value, who must give it back — is closer to
Rust.

So three traditions meet here, and where they disagree, Bend looks strange.
Four things in particular are going to surprise you, and each gets a chapter:

- **Every value is used at most once**, unless you mark it otherwise. Not a
  safety warning — the memory model. Without this, Bend cannot free memory
  without a garbage collector, and cannot run two calls in parallel without
  locks.
- **Recursion must be provably terminating**, and the parameter that shrinks must
  be written first. The compiler checks the shape of your function, not its
  meaning.
- **There is no `if`.** Branching is `match` on a datatype that has `True{}` and
  `False{}` in it.
- **There are no tactics.** A proposition is a type, a proof is a value of that
  type, and you write it by hand as an ordinary `def`.

## What this book will and will not settle

It will settle:

- Whether the parallelism is real, and how well it scales, measured on 10
  performance cores.
- Whether the GPU path actually wins, on two different workloads — one where it
  does, one where it does not.
- Whether proof checking is as fast as claimed.
- What it costs you to write the proofs — in lines, in time, and in frustration.

It will not settle the claim about AI-generated code, which is a claim about a
workflow and not about a language. What it does do is make the *ingredients*
concrete: by the end, you will have written a law and a proof yourself, and you
will have a fair idea of what that would or would not buy you on a real problem.

## Where the language is not finished

Two things to know before you invest time, both true as of Bend 2.0.5:

- The compiler is, in the project's own description, largely AI-written and not
  fully audited. The Lean formalization of Bend's theory lags the actual
  TypeScript implementation.
- The standard library is small, and — as one chapter of this book discovers the
  hard way — it has almost no *lemmas*: facts about its own functions that your
  proofs can reuse. You will write those yourself.

Neither is a reason not to look. Both are reasons to measure rather than
assume, which is what the rest of this book does.

Next: [getting it installed](setup.md), including one trap that will cost you
ten minutes if nobody tells you about it.
