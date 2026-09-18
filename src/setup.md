# Getting set up

## Install

```sh
curl -fsSL https://bend-lang.com/install.sh | sh
```

Then, in a **new shell**:

```sh
bend --version
```

```
bend 2.0.5
```

That is the version this book was written against.

## Where it actually goes

The installer puts everything under `${BEND_HOME:-$HOME/.bend}` — on a machine
that has not set `BEND_HOME`, that means `~/.bend`:

| Path | What it is |
|---|---|
| `~/.bend/bin/bend` | a **3.5 KB POSIX shell launcher** — not the compiler |
| `~/.bend/current` | a symlink to the version currently installed |
| `~/.bend/app/<version>/<hash>/` | the real implementation, in TypeScript |

That first row matters more than it looks. `bend` is a shell script that
resolves the version, checks for updates, and then hands the work to **bun**
running the TypeScript. So the thing on your `PATH` is a launcher, and every
invocation carries a small startup cost you will notice later when you are
timing things — and an automatic update check, which is why a first run
sometimes stalls.

> **Careful with the repository you downloaded.** If you cloned
> `github.com/bendlang/bend` to read its source, there is a directory in it
> named `bend/`. It is unrelated to `~/.bend/bin/bend`. One is the upstream
> source tree; the other is the thing on your `PATH`.

## The trap: the installer does not know about fish

The install script ends by adding `~/.bend/bin` to your shell's startup file,
and it decides which one with this:

```sh
case ${SHELL:-} in
  *zsh)  rc=$HOME/.zshrc ;;
  *bash) rc=$HOME/.bashrc ;;
  *)     rc=$HOME/.profile ;;
esac
```

**Only zsh and bash are handled.** If your login shell is zsh, the line lands
in `~/.zshrc` — which fish does not read. If your login shell *is* fish, you
fall through to the `*)` branch and it writes to `~/.profile`, which fish does
not read either. Either way the script cheerfully prints:

```
Your PATH now has ~/.bend/bin; open a new shell to use bend.
```

…and `which bend` finds nothing.

The fix is one line in your fish config:

```fish
fish_add_path ~/.bend/bin
```

This is worth knowing about for a second reason: it is the kind of thing that
makes people conclude a language is broken when it is a five-line shell script
in the installer. Bend's compiler is fine. Its installer assumes bash.

## Telemetry, and turning it off

The launcher sends an anonymous report on every run — version, OS, architecture,
which subcommand, exit code, elapsed milliseconds — by POSTing to
`bend-lang.com/ping` in the background. Set:

```sh
export BEND_NO_TELEMETRY=1
```

This book sets it everywhere, and so should you if you are going to run the
benchmarks in it, since the reports are fire-and-forget but they are not free.

## The thing that will waste your afternoon: two backends

Bend has two ways to run your program, and they are not equivalent.

```sh
bend hello.bend              # ① interpreted, on a JavaScript backend (bun)
bend hello.bend -o hello     # ② compiled to a native executable
./hello
```

① is instant and good for everything in the first half of this book. ② takes a
few hundred milliseconds and is what you need for the second half.

**The difference is parallelism.** The JavaScript backend **runs everything
sequentially** — Bend's own documentation says so plainly, and it means what it
says. A `fork-join` program under ① produces exactly the right answer, at
exactly the speed of the non-parallel version. If you measure a Bend program
without compiling it, you will find no parallelism anywhere, and conclude the
whole thing is marketing.

So:

```sh
cd parallel
bend pow2.bend -o pow2
./pow2 --threads 1
./pow2 --threads 8
```

`--threads` only exists on the native binary. It is how you tell the runtime how
many cores to spread the work over.

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
[Next: a first program](basics-hello.md).
