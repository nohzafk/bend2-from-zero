# Writing an effect

Nothing in the previous chapter was privileged. Every effect in `Base` — the
printing, the sleeping, the sockets — is a def whose body is two imports, and
effects you write yourself have exactly the same shape. The compiler treats
them identically. This chapter writes two from scratch, breaks them on
purpose in two different ways, and measures what happens.

## The def, and the two files

```python
def Clock.now() -> IO(U32):
  import "./clock.c"
  import "./clock.js"
```

That is the whole declaration. The `.c` file serves the compiled lanes, the
`.js` file serves run mode, and the host functions are named after the def —
lowercased, dots to underscores. So `Clock.now` is `clock_now` in both files.
Run it, and it answers:

```
$ bend clock.bend
ms since boot: 53
$ bend clock.bend -o clock && ./clock
ms since boot: 264817041
```

Both lanes print a number and call it "ms since boot". Only one of them means
it. The native side calls `io_tick()`, the machine's uptime clock — 264817041
milliseconds is the three-odd days this Mac has been up. The run-mode side is
JavaScript at heart, and `performance.now()` counts from the **process start**,
53 ms ago. Same def, same words in the output, two different quantities.

Here is the part to sit with: **nothing checks that the two host files agree.**
The compiler reads the `.c` into the native build and the `.js` into run mode,
and never compares them. The delta across a sleeping program matches in both
lanes (303 ms for a 300 ms sleep) — they agree about *rate* and disagree about
*origin*, and the only thing that ever noticed was a probe that printed both.

## The C side

```c
Term clock_now_run(Env e, Term* f, IoWork* w) {
  return (Term)(uint32_t)(io_tick() / 1000000ull);
}

static void __attribute__((constructor)) clock_now_use(void) {
  io_eff(CID_CLOCK_NOW, clock_now_run, 0);
}
```

The compiler splices your `.c` into the program's C source after the runtime,
so the runtime's symbols are in scope. The def's arguments arrive in `f` in
order — a `U32` is `(u32)f[0]`, a `String` is taken with `io_cstr(e, f[0], &n)`
and must be freed, a handle comes back with `io_hand_v`. The answer is a term:
a number is `(Term)n`, `Unit` is `term_pak(CID_UNIT, 0)`, a string is
`io_str(e, p, n)`, and a fallible answer is `io_done(e, v)` or
`io_fail(e, code, NULL)`. The constructor registers everything with one line —
`CID_CLOCK_NOW` is the def's name uppercased, dots to underscores — and the
last argument of `io_eff` is the *need*: `0` runs the call at once, `IO_TIME`
parks it for `f[0]` milliseconds, `IO_READ` until a handle is readable.

Two probes beyond `clock` show this is not a toy interface: `Shout.upper` and
`Str.repeat2`, effects that exist nowhere in `Base`, work in all three lanes
(run mode, native, and `-o x.js` plus `bun`), and strings cross the boundary
byte-exact — `héllo·世界` in, identical bytes out, in both lanes.

## The JS side

```js
function clock_now() {
  return Math.floor(performance.now()) >>> 0;
}
```

The compiler finds the function by name. A need is a second function,
`clock_now_need`, returning `{time: true}` or `{read: true}`; a blocking call
takes one more argument and parks with `io_park_on`. `libc` is reachable
through `bun:ffi` for the cases that need it (`io_sys()`: `read`, `recv`,
`poll`, `errno`).

## Blocking without stalling

The loop is single and sacred: an effect that blocks it stops every other
computation. The runtime's answer is `io_work` — run the waiting on a helper
thread, come back on the loop when it is done. The probe is a 1000 ms busy
call, with a ticker forked beside it:

```
tick 300
tick 600
tick 900
busy done after 1010 ms
```

The ticks fire **during** the work. A custom blocking effect, written by hand
in twenty lines of C, does not stall the event loop; the JS lane gets the same
behavior from a need. That is the mechanism to reach for whenever an effect
would otherwise wait — and the reason `file_read.c` and `tcp_recv.c` in
`bend2/effs/` are worth reading before writing anything slower than a think.

## Two ways to get it wrong

Both lanes have their own host file, so both have their own way to be wrong,
and the mistakes are invisible from the other side:

| mistake | run mode | native |
|---|---|---|
| JS function misnamed (`shout_upperX`) | ❌ `TypeError: op.run is not a function.` | ✅ works — its `.c` is fine |
| `.c` file missing its `io_eff` registration | ✅ works — it never looks at the `.c` | ❌ compiles, then at first use: `bend: an alien request`, exit 1 |

Neither error is caught by the compiler, and neither can be: the host files
are outside the language. The practical rule is the same one the races
chapter gave for threads — **test both lanes for anything with a custom
effect**, because each one is someone else's program.

## What the compiler still will not do for you

Three more edges, from the same probes and from upstream's own list:

- **No ABI.** "The C side tracks the exact compiler version: the names above
  are the runtime's internals, and a release may rename any of them. There is
  no ABI promise. Rebuild your effects with every update." (the guide's
  effects note, about itself.)
- **No custom handle types.** `File`, `Socket`, `Window` are handle types
  that only `Base` may declare; a custom effect speaks through them but
  cannot introduce its own (`WONTFIX.txt`, under DESIGN). The reason is
  consistency of the affine story: a handle is a one-owner value, and the
  language is not yet ready to let user code mint one.
- **An output name may not collide with the program's own files:**

  ```
  $ bend shout_repeat.bend -o shout_upper.c
  bend: -o shout_upper.c is a file the program reads, or a directory
  ```

  — refused, and the file is left untouched.

## Lazy, and strict

One last measurement, because it is about everything above. Upstream keeps it
as WONTFIX #775: `bend file.bend` runs a pure main lazily, compiled lanes are
strict. Put a 200-million-step computation in a **dead argument** — one the
callee never uses:

| | real |
|---|---|
| `bend lazy_checker.bend` | 0.057 s — the steps are not run |
| `./lazy_checker` (compiled) | 0.18 s — they are |
| compiled, with the argument at `spin(0n)` | 0.01 s |

Same value, different cost. The rule that generalises past this probe: **run
mode is for correctness, a compiled binary is the truth about cost** — a
distinction the parallel chapters met from the other side.

## Running it

```sh
cd fx/custom
bend shout_repeat.bend    # ✅ two effects that are not in Base, three lanes green
bend busy.bend            # ✅ watch the ticks land during the work
bend clock.bend           # ✅ then: bend clock.bend -o clock && ./clock
```

## The effect, all three files

```python
{{#include ../fx/custom/clock.bend}}
```

```c
{{#include ../fx/custom/clock.c}}
```

```js
{{#include ../fx/custom/clock.js}}
```

Next: turning a belief into a compiler check.
