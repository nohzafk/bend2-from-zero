# custom — writing an effect

An effect is a def whose body is two imports. The `.c` file serves the
compiled lanes, the `.js` file serves run mode, and the host function is named
after the def — lowercased, dots to underscores.

| file | question | result |
|---|---|---|
| `clock.bend` | the guide's own example | ✅ `ms since boot: ...` — but read the lanes: native counts from boot, JS counts from process start |
| `shout_repeat.bend` | two effects that are not in Base (`Shout.upper`, `Str.repeat2`) | ✅ `HELLO, BEND` / `ababababab` / `XXX` — in run mode, native, and `-o x.js` + bun |
| `utf8.bend` | strings through a custom effect | ✅ byte-identical in both lanes (`héllo·世界`) |
| `delay.bend` | a custom NEED (`IO_TIME`) | ✅ `d_builtin=307 d_custom=303` — a custom need parks the loop exactly like `IO.sleep` |
| `busy.bend` | a BLOCKING effect via `io_work` | ✅ a forked ticker fires at 300/600/900 **during** the 1000 ms of work — the loop is not stalled |
| `misnamed_host.bend` | the JS host function named wrong | ❌ run mode: `TypeError: op.run is not a function` — while the compiled lane works, its C file is fine |
| `missing_registration.bend` | the C file without its `io_eff` registration | ❌ compiles; native run: `bend: an alien request`, rc 1 — while the JS lane is unaffected |

The lesson of the last two is worth its own sentence: **each lane has its own
host file, and a mistake in one is invisible to the other.** A program can be
green in run mode and dead compiled, or the other way round.

One command-level guard, checked by hand: naming the output after one of the
effect's own files is refused, and the file is left untouched.

```
$ bend shout_repeat.bend -o shout_upper.c
bend: -o shout_upper.c is a file the program reads, or a directory (see bend --help)
```

Running:

```sh
cd fx/custom
bend shout_repeat.bend    # ✅ all three lanes green
bend busy.bend            # ✅ (~1 s, watch the ticks)
bend clock.bend           # ✅ then compile it and compare the two numbers
```

Book: chapter 20.
