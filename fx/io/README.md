# io — the event loop

A Bend program is a set of computations interleaved by one event loop: each
runs its pure code (in parallel, on every core) up to its next effect, and one
that waits on a socket, a sleep or a channel steps aside for the others. These
probes pin what that model actually does.

| file | question | result |
|---|---|---|
| `deadlock.bend` | a computation waits on a channel nobody sends to | ❌ `bend: deadlock: every computation waits on a channel`, rc 1 |
| `sleep_par.bend` | two forked 700 ms sleeps | ✅ `total ms=709` — one sleep's time, not two |
| `join_reuse_bad.bend` | join a channel twice, plain | ❌ does not compile: `consumed more than once` |
| `join_twice.bend` | the same with `+ch` | ❌ compiles, dies: `IO.join: the channel was closed`, rc 1 |
| `match_in_do_bad.bend` | `match` written inside a `do` block | ❌ `a match heads a def body, not a term` |
| `close_recv.bend` | send, recv, close, recv again | ✅ `send=true`, `recv=7`, then `recv=none` |
| `send_after_close.bend` | send on a closed channel | ✅ `send-after-close=false` |
| `orphan_deadlock.bend` | main returns while one task still waits | ❌ `main done`, then the whole program reports deadlock, rc 1 |
| `die.bend` | `IO.die(Unit, 7, "custom failure message")` | ✅ message on stderr, rc **7** |
| `try_fail.bend` | `IO.try` on a failing effect | ❌ `No such file or directory`, rc **2** (the errno) |
| `room_full.bend` | a second send into a room-1 channel, nobody receiving | ❌ first send `true`, then deadlock, rc 1 — a full room **blocks** |
| `chan_fifo.bend` | room 4: four sends, then receives | ✅ `10, 20, 30, 40` — FIFO |
| `spawn.bend` | `IO.spawn` a task that outlives main | ✅ the program waits for it: `spawned ran after 300ms` |
| `args.bend` | `IO.args` | ✅ `argc=3` for `bend args.bend alpha beta -- gamma`; the `--` itself is not passed |

The two deadlock cases print the same line — the runtime does not distinguish
"everyone is stuck" from "main is done but one task is still waiting". Both
exit 1, and the second one is the honest surprise: **main returning is not the
program ending.**

Running:

```sh
cd fx/io
bend deadlock.bend          # ❌ rc 1
bend sleep_par.bend         # ✅
bend args.bend alpha beta   # ✅ argc=2
```

Book: chapter 19.
