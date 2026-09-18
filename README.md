# bend2-play

Notes from playing with [Bend 2](https://github.com/bendlang/bend), as a book:
**https://nohzafk.github.io/bend2-from-zero/**

Each directory is one topic. It holds runnable code, and **probes that are
deliberately wrong** — written to make the compiler talk. That second kind usually
teaches more than reading the docs does, so they are kept, and every README says
"this one is ❌, and here is the error it gives".

- Environment: Bend 2.0.5, macOS 27, Apple M3 Max (10 performance cores + 4 efficiency)
- `bend/` is a clone of the upstream repo. **It is not our code** — reference only,
  do not edit anything inside it.

## The tutorial (mdBook)

`src/` is a from-zero Bend 2 tutorial; `book.toml` is its mdBook config.

```sh
mdbook serve      # http://localhost:3000
mdbook build      # writes to book/ (gitignored)
```

Every ❌ and ⚠️ in the book corresponds to a **probe file in this repo that really
runs**. The error text is pasted output, not something written by hand, so you can
reproduce each one yourself.

`src/` contains symlinks into the topic directories. That is forced: mdBook only
copies non-markdown files that are *inside* `src/`, so `[hello_bad.bend](../basics/hello_bad.bend)`
would be a **dead link** in the rendered HTML. With the symlink, mdBook walks in and
carries the `.bend` files into `book/` — the links work, and the HTML book becomes
self-contained.

## Setup

```sh
curl -fsSL https://bend-lang.com/install.sh | sh
bend --version                                       # this repo was written against 2.0.5
```

**Where it lands.** The installer writes to `${BEND_HOME:-$HOME/.bend}`; `BEND_HOME`
is unset on this machine, so `~/.bend`:

| Path | What it is |
|---|---|
| `~/.bend/bin/bend` | a 3.5 KB **POSIX shell launcher** (resolves the version → self-updates → hands off to bun) |
| `~/.bend/current` | symlink to `~/.bend/app/2.0.5/ZRx01G` |
| `~/.bend/app/<version>/<hash>/` | the TypeScript that is actually interpreted |

The `bend/` directory in this repo is **not** that. It is a clone of the upstream
source — same name, no relation.

The launcher sends anonymous telemetry by default (a background POST of
`{id, ver, os, arch, cmd, exit, ms}` to `bend-lang.com/ping` on every run) and
auto-downloads new versions. `BEND_NO_TELEMETRY=1` turns that off.

**The installer's PATH step does not know about fish.** It picks the rc file by
`case ${SHELL:-} in *zsh) ...;; *bash) ...;; *) ~/.profile;; esac`, so a fish user
falls into the `*)` branch and gets a line written to `~/.profile`, which fish never
reads — while the script prints *"Your PATH now has ~/.bend/bin; open a new shell to
use bend."* On a fish machine, add `~/.bend/bin` to PATH yourself.

## Running things

```sh
# Interpreter: the JS backend
bend basics/hello.bend

# Native: this is the only one with real multicore
cd life && bend life_row.bend -o life_row && ./life_row --threads 8
```

**The two backends differ enormously, and this is the easiest thing to get wrong:**

| | Interpreter | Native |
|---|---|---|
| Parallelism | **fully serial** — `a b = f(x) g(y)` does not fork | real multicore |
| GPU (`f!(x)`) | ignored | handed to Metal, with a `.gpu` MetalLib emitted alongside |
| Speed | an order of magnitude slower | fast |
| Use it for | checking results and type errors | **measuring anything** |

The first time we measured parallelism we measured it under the interpreter and got
"parallelism doesn't help" — a wrong conclusion with a plausible-looking table.

## Contents

| Directory | What it covers | In the book |
|---|---|---|
| `basics/` | first contact: hello, strings, modulo, lists | ch. 4–7 |
| `affinity/` | **affinity** — the first key to everything in Bend (plus a 199-line `notes.md`) | ch. 8–9 |
| `arrays/` | reading an array gives you a *pair*; how to take it apart | ch. 10 |
| `parallel/` | fork-join on the CPU: `a b = f(x) g(y)` | ch. 11 |
| `gpu/` | `f!(x)` and Metal; mandelbrot vs queens | ch. 12–14 |
| `life/` | Game of Life: four implementations, a terminal animation, and two complete laws with proofs | ch. 15–20 |
| `GUIDE.txt` | the official guide in full (**an unmodified copy of an upstream file**; `GUIDE.txt:NNN` references in the notes point here) | — |

Three files here are **unmodified copies** of files from the upstream Bend compiler —
`GUIDE.txt`, `gpu/mandelbrot/main.bend`, `gpu/queens/main.bend` — redistributed under
Apache-2.0. For provenance, the upstream revision, and the licence text, see
[`THIRD-PARTY.md`](THIRD-PARTY.md).

## Findings, in one place

Worth knowing before you write code, and **the compiler will not tell you**:

**Affinity**

- Affine is not linear: a value is used **at most once**, and using it zero times is
  perfectly legal
- `+x` is the escape hatch, but the type must be `Data` (`expected : Data, observed : Type`)
- `Type` = `Kind(&1)` = something with identity, not copyable. Base has exactly three:
  `Array`, `IO.OP`, `App` — all mutable memory or resource handles
- **A closure can never be copied**, `+` does not save it
- The count is per **execution path**, not per occurrence: using `x` once in each arm
  of a `match` is legal

**Syntax shapes**

- There is no `if`: `match` on `True{}` / `False{}`, or `Bool.pick(T, cond, a, b)`
- `match` can only scrutinise a **parameter** or a field — not a local binding, and
  not a computed value. The error says "give it its own def"; do that
- The signature uses parentheses (`-> IO(Unit)`), the `do` block uses angle brackets
  (`do IO<Unit>:`). Get it wrong and you get `unknown: IO`, which reads like a missing import
- Constructors take positional arguments (`SCon{Chr{c}, SNil{}}`); field names are for
  patterns only
- A parallel `let` has to be on one line
- In a self-recursive function, **the shrinking parameter must come first**, or the
  termination checker refuses it

**Performance**

- `bend` run as an interpreter is always serial. Measuring parallelism requires a
  native build
- Under a native build, `a b = f(x) g(y)` forks across cores by itself. `!` is what
  sends a call to the GPU — it is not what enables parallelism
- **Pick the algorithm before you pick the core count.** See `life/`: same Game of
  Life, same 64×64 grid, same 16 generations, same single thread — O(n²) takes
  ≈ 8,100 ms and O(n) takes 5 ms, about **1,600×**. All of it from the algorithm, none
  of it from the cores (ten cores buy about 3×, see the next line)
- **A parallel number has to be recorded together with the implementation that
  produced it.** See `life/README.md`: a rewrite done so the code could be *proved*
  made the serial version ~18% faster and dropped the 10-thread speedup from 4.14×
  to 2.57×, flipping the best granularity from `blk=1` to `blk=16`. Change how one
  algorithm is written and the conclusion reverses
- **The `LAWS.bend` gate really does stop you.** See `life/LIFE_PAR_PROOF.bend`:
  break the right-subtree offset in `tree_cells`, or the leaf's value in `block`, and
  `bend` refuses immediately. The isomorphic law in `pure_par_sum` proves in three
  lines because `Nat.add` has no cons structure and a list does
- **Every `!` program pays a fixed entry fee of about 85 ms**, whatever it computes
  (`gpu_floor` computing 4 costs what `pow2!(26n)` computing 67 million costs, and a
  second call in the same process costs a few ms more). So **a GPU wall-clock number
  is not a statement about the GPU** — subtract the door and mandelbrot goes from
  "6× faster" to "about 20× faster", while pow2 was never a comparison of arithmetic
  at all. To find out which one you are measuring, write a program that does nothing
  and measure that. See `gpu/README.md`
