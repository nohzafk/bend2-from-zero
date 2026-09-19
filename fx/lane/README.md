# lane — the checker is lazy, the binaries are strict

Upstream keeps this as WONTFIX #775: `bend file.bend` runs a pure main lazily,
compiled lanes are strict. These probes measure the difference with a dead
argument.

| file | what |
|---|---|
| `lazy_checker.bend` | `apply1((y: Nat) => (7n : Nat), spin(200000000n))` — the argument is never used |
| `lazy_checker_baseline.bend` | the same call with `spin(0n)` — no work in the argument at all |

Measured on this machine, steady state:

| | run mode | compiled |
|---|---|---|
| `lazy_checker.bend` | 0.057 s — the 200M steps are **not run** | 0.18 s — they are |
| `lazy_checker_baseline.bend` | 0.057 s | 0.01 s |

Same value (`7n`), different cost: the checker skips an unused argument, a
binary evaluates it. The number is small; the rule is not — this is one of the
places where "it did not run anything" and "it ran everything" look identical
from the outside.

Running:

```sh
cd fx/lane
bend lazy_checker.bend                     # lazy: returns at once
bend lazy_checker.bend -o lazy && ./lazy   # strict: ~0.18 s
```

Book: chapter 20.
