# Effects, and the event loop

Every program in this book so far computed a value. This chapter is about
programs that do things — print, wait, read a file, open a socket — and about
the machine that lets them do those things without threads. Bend calls it `IO`.

One honest note before starting. The guide's prose on IO is thin, and its own
effects note (`bend guide effects`) says of itself that an AI wrote it and a
human will revise it. So this part of the book came from probes rather than
from reading: `fx/` in this repository holds them, and its READMEs are the
full tables. What follows is what they measured.

## The shape at the seam

You have written `do IO<Unit>:` blocks since the first chapter; this is where
their rules were pinned down. Each is a corner where the pure language meets
the loop, and each one cost a compile cycle while the probes were written:

| what you write | what you get |
|---|---|
| `match` inside a `do` block | `a match heads a def body, not a term` — pull the match into its own def |
| a let without its type (`path = "..."`) | a parse error that points at the *next* line |
| a block that ends with a bind (`x : T <- m`) | `expected : a term / observed : end of input` — end with a Unit step or `return` |
| `f(g(x))` where `g` is an effect | a type error — `g(x)` is an `IO(..)`, not a value; bind it with `<-` first |

None of these is deep. The fourth is the one that generalises: **an effectful
call is not a value**, so it can never be an argument. Every `IO` needs its
own line.

## The event loop

The guide states the model in one sentence:

> A Bend program is a set of computations interleaved by one event loop, as in
> Node.js: each runs its pure code (in parallel, on every core) up to its next
> effect, and one that waits on a socket, a sleep or a channel steps aside for
> the others.

The probes give that sentence numbers. Two computations, each sleeping 700 ms,
forked and joined:

```python
c1 : Chan(U32) <- IO.fork(U32, nap(700))
c2 : Chan(U32) <- IO.fork(U32, nap(700))
r1 : U32 <- IO.join(U32, c1)
r2 : U32 <- IO.join(U32, c2)
```

Measured: `total ms=709`. One sleep's worth of wall clock, two sleeps' worth
of work — the loop really does overlap them, with no threads in sight.

Then the sentence's second half — "the program ends when every computation is
done, or reports a deadlock when the remaining ones all wait" — has a case
the guide does not spell out. **Main returning is not the program ending.**

| what the probes do | what happens |
|---|---|
| `IO.spawn` a task that sleeps 300 ms, then return from main | the program waits for it: `spawned ran after 300ms`, exit 0 |
| fork a task that waits on a channel nobody will ever send to, then return from main | prints nothing else, then `bend: deadlock: every computation waits on a channel`, exit 1 |

The second one is the surprise worth keeping: a leftover task turns the whole
exit into a deadlock report — the runtime refuses to exit quietly while
someone is still waiting. And it prints the same line when *everyone* is
stuck; the two situations are not distinguished. Both exit 1.

## Channels

Fork and join are built on channels, and the whole state table is small enough
to pin down completely:

| operation | state | result |
|---|---|---|
| `Chan.send` | room available | `true` |
| `Chan.send` | room full | **blocks** until a receiver appears |
| `Chan.send` | channel closed | `false` |
| `Chan.recv` | value available | `Some(value)`, FIFO order |
| `Chan.recv` | closed and empty | `None` |

Two rows deserve a second look. **A full room blocks; it does not refuse.** The
probe sends twice into a room-1 channel with nobody receiving; the first
`send` answers `true`, the second never returns, and the program ends as the
deadlock above. And **closed is not an error**: `send` on a closed channel
answers `false`, `recv` answers `None`, and the program continues.

`IO.join` is the pair done for you: one `recv`, one `close`. That makes it
sharper than it first looks.

```python
+ch : Chan(U32) <- IO.fork(U32, one())
r1 : U32 <- IO.join(U32, ch)
r2 : U32 <- IO.join(U32, ch)     # the channel is closed now
```

With the channel marked `+`, both joins compile, and the second one dies at
runtime: `IO.join: the channel was closed`, exit 1. Without the `+`, it does
not even compile — `consumed more than once` — which is the affine rule from
earlier chapters arriving on schedule. **A join consumes the channel; a
consumer that wants more values uses `Chan.recv` directly.**

## Things that fail

An effect can fail, and Bend makes that a value: the effect answers
`Result<&1, &1, U32 & String, A>` — an error code and message, or the answer.
`IO.try` unwraps it or exits with the error. The exit codes are the machine's:

| probe | stderr | exit |
|---|---|---|
| open a file that is not there | `No such file or directory` | 2 (`ENOENT`) |
| connect where nobody listens | `Connection refused` | 61 (`ECONNREFUSED`) |

The message is `strerror` and the code is the errno — **an exit code is the
interface a shell sees**, so it is the one the runtime keeps exact. When you
want your own, `IO.die(A, code, msg)` exits with your code and prints your
message:

```
$ bend die.bend
before die
$ echo $?        # 7
custom failure message          # on stderr
```

and the statements after the `die` do not run.

## A file, up close

`File` is the effect family worth reading closely, because every fallible
effect works the same way: **the handle is affine, so every effect on it hands
the handle back beside its result.** A read is
`(File & Result<&1, &1, U32 & String, String>)` — the file, and what happened.

The unwrap worth memorising, because it is the shape you will write a dozen
times:

```python
def r_done(m: File & Result<&1, &1, U32 & String, String>) -> IO(Unit):
  (f, r) = m
  do IO<Unit>:
    s : String <- IO.pass(String, r)
    IO.print("read back: " ++ s)
    File.close(f)
```

Destructure the pair in a parameter position; `IO.pass` the Result. This is
the same bargain as arrays, for the same reason — one owner at a time — and it
buys the same thing: **the compiler catches handle misuse.** A read after
close is not a runtime surprise; it does not compile.

The full roundtrip — write, size, close, reopen, read — is one probe, and it
prints `size=11`, `read back: hello, file`. The errors are probes too:
opening a missing file exits 2; that is the whole File story that matters
before you write your own effects.

## Two loose ends

`IO.args` answers the command line, minus the runtime's own options — and
`--` is how you draw that line yourself. `bend args.bend alpha beta -- gamma`
passes `alpha`, `beta`, `gamma`: the `--` stops Bend's own option parsing and
is not itself passed. `argc=3`.

The window, audio and graphics effects (`App.run` and friends) are out of
scope here: this book's probes all run headless. They are the one branch of
the effect tree left untested by it, and they are honest about why.

## Running it

```sh
cd fx/io
bend deadlock.bend          # ❌ the deadlock message, rc 1
bend sleep_par.bend         # ✅ total ms=709
bend close_recv.bend        # ✅ send/recv/close semantics
bend join_twice.bend        # ❌ IO.join: the channel was closed, rc 1
```

Next: [writing an effect of your own](effects-2.md).
