# basics

Four small programs from first contact with Bend. Each answers exactly one question.

| File | The question | Result |
|---|---|---|
| `hello.bend` | what does the smallest program look like | `hello, bend 2` |
| `exp_str.bend` | do `\n` and `\t` escape inside a string | `a` newline `b<TAB>tab` — yes, escaping works |
| `exp_mod.bend` | does the termination checker accept modulo written as structural recursion | ✅ returns `1n`, i.e. `9 mod 4` |
| `exp_list.bend` | a hand-written `nth` that walks the list | `2`, i.e. `[1,2,3][1]` |
| `exp_type.bend` | the no-parameter `type` declaration, fields marked `+` in the declaration | `25`, i.e. `5*5` |
| `exp_chain.bend` | the smallest parameterised type that checks: `a` quantity, `A` element type | `2`, i.e. the chain's length |

The ❌ files pin the three errors a reader meets before the correct shape:

| File | The question | Result |
|---|---|---|
| `type_is_missing.bend` | can a `type` declaration leave out `is` | ❌ `expected : 'is'` — the clause is mandatory |
| `type_field_affine.bend` | can a field be used twice without `+` in the declaration | ❌ `consumed more than once` |
| `type_quantity_field.bend` | can a field be typed with the bare parameter `a` | ❌ `a : Quant` — `a` is a quantity, not a type |

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
