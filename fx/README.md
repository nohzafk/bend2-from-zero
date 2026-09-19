# fx — effects: the world outside

Everything that is not arithmetic goes through `IO` and the effect system:
channels, files, sockets, and the host interfaces you write yourself in C and
JS. The probes here are grouped by what they pin down.

| dir | what it pins |
|---|---|
| `io/` | the event loop: chan, fork/join/spawn, deadlock, die/try/args |
| `custom/` | writing effects: host files in C and JS, needs, blocking work |
| `file/` | the File handle: roundtrip, errors, and what affinity refuses |
| `tcp/` | a loopback roundtrip and a refused connection |
| `lane/` | the interpreter's laziness versus the compiled lanes' strictness |

Every probe runs in **both lanes** — `bend file.bend` is the JS lane, a
compiled binary is the native one — unless its README says otherwise.

Run one from its own directory:

```sh
cd fx/io && bend deadlock.bend
```

❌ marks a probe that is deliberately broken; its README says which error to
expect.

Book: chapters 19–20 (Effects).
