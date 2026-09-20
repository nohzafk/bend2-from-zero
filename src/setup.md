# Getting set up

## Install

```sh
curl -fsSL https://bend-lang.com/install.sh | sh
```

Then, in a **new shell**:

```sh
bend --help | head -1
```

```
Bend 2.0.20: check, run, build and publish Bend programs.
```

That is the version this book was written against.

## Where it actually goes

The installer puts everything under `${BEND_HOME:-$HOME/.bend}` — on a machine
that has not set `BEND_HOME`, that means `~/.bend`:

| Path | What it is |
|---|---|
| `~/.bend/bin/bend` | the compiler — a single native binary |
| `~/.bend/bend2/` | `base.bend`, and `effs/`, the effect definitions |
| `~/.bend/guide/` | the guide, plus the effects and shaders guides |
| `~/.bend/lib/` | packages pulled from the hub, keyed by content hash |
| `~/.bend/check.json` | when it last asked whether a newer version exists |

One self-contained file, with no runtime behind it. That is worth knowing
before you read any timing in this book: nothing in the numbers is startup
cost.

> **Careful with the repository you downloaded.** If you cloned
> `github.com/bendlang/bend` to read its source, there is a directory in it
> named `bend/`. It is unrelated to `~/.bend/bin/bend`. One is the upstream
> source tree; the other is the thing on your `PATH`.

## The installer does not touch your shell

It prints the line to add, and leaves it to you:

```
  Add it to your PATH: export PATH="$HOME/.bend/bin:$PATH"
```

On fish it prints the fish spelling instead:

```
  Add it to your PATH: fish_add_path $HOME/.bend/bin
```

Nothing is written to your startup files, so `bend` resolves only once you have
added that line yourself — on any shell, fish included.

## The once-a-day version check

Once a day, `bend` asks `bend-lang.com` what the latest version is. It sends its
own version, the OS and the CPU type, and nothing else — no code, no file names,
no timings. If a newer version exists it says so, and that is all: **the
installed bend never updates itself.**

```sh
export BEND_NO_TELEMETRY=1
```

turns the question off. This book sets it everywhere, and so should you if you
are going to run the benchmarks in it.

## The thing that will waste your afternoon: two backends

Bend has two ways to run your program, and they are not equivalent.

```sh
bend hello.bend              # ① the JavaScript target
bend hello.bend -o hello     # ② compiled to a native executable
./hello
```

① starts instantly and is good for everything in the first half of this book. ②
takes a few hundred milliseconds to build and is what you need for the second
half.

**The difference is parallelism.** The guide is blunt about it:

> The JavaScript target ignores all that and just runs sequentially.
>
> — `bend guide`, *Parallelism*

A `fork-join` program under ① produces exactly the right answer, at exactly the
speed of the non-parallel version. If you measure a Bend program without
compiling it, you will find no parallelism anywhere, and conclude the whole
thing is marketing.

So:

```sh
cd parallel
bend pow2.bend -o pow2
./pow2 --threads 1
./pow2 --threads 8
```

`--threads` only exists on the native binary — `bend file.bend --threads 8` is
refused as an unknown option. It is how you tell the runtime how many cores to
spread the work over.

## Two kinds of `main`

A Bend program's entry point can have either of two shapes, and it is worth
knowing both now because the small experiments use the second:

```python
# ① does something, prints it itself
def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("hello, bend 2")
```

```python
# ② computes a value; the CLI prints it for you
def main() -> Nat:
  mod(9n, 4n, 0n)
```

The second is what you will reach for constantly while exploring, because it
turns a program into a one-line answer:

```sh
$ bend exp_mod.bend
1n
```

Note the trailing `n` — that is Bend telling you the value is a `Nat`, and it is
the first hint of something this book leans on constantly: **Bend almost never
infers a type, and says so out loud.**

Now that it is installed, let's write something.
Next: a first program.
