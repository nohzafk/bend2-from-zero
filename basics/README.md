# basics

Four small programs from first contact with Bend. Each answers exactly one question.

| File | The question | Result |
|---|---|---|
| `hello.bend` | what does the smallest program look like | `hello, bend 2` |
| `exp_str.bend` | do `\n` and `\t` escape inside a string | `a` newline `b<TAB>tab` — yes, escaping works |
| `exp_mod.bend` | does the termination checker accept modulo written as structural recursion | ✅ returns `1n`, i.e. `9 mod 4` |
| `exp_list.bend` | a hand-written `nth` that walks the list | `2`, i.e. `[1,2,3][1]` |

## `exp_mod`: why this is worth trying on its own

Bend requires recursion to terminate, and it proves that from a **parameter
getting structurally smaller**. Modulo is not naturally structural recursion, so
this uses a detour: recurse structurally on `x` (which is definitely shrinking) and
accumulate the remainder in `k`.

```python
def mod(+x: Nat, +n: Nat, +k: Nat) -> Nat:
  match x:
    case 0n:      k
    case 1n+p:    mod(p, n, bump(k, n))     # x → p, structurally smaller
```

It passes. That pattern came back constantly when the Game of Life was written
later — **the termination checker looks at the parameters, not at the meaning**.

## `exp_list`: element access is O(n)

`nth` walks the list one link at a time, so `xs[i]` costs `O(i)`. That plain fact
became the starting point for the whole run of experiments in `../life/`: a program
that is "only missing an index function" turned out to be two orders of magnitude
away from the fast one.

## Running

```sh
cd basics
bend hello.bend
```

Book: chapters 4–7.
