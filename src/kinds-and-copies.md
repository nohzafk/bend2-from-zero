# Copies, kinds, and the `+` mark

The last chapter left a promise unkept: there is a way to use a value twice —
write `+x` — but it is refused for some types and not others. This chapter is
about what decides that, and about the loose end from the lists chapter, where
`List.range` returned a `List<&2, Nat>` and nobody said what the `&2` was.

## Three quantities

A value can be bound three ways. The mark goes on the *variable*, at the point
where it is introduced:

```python
-x = ...     # erased     -- the checker sees it, the compiler deletes it
 x = ...     # affine     -- at most once. the default
+x = ...     # reusable   -- as many times as you like
```

`-x` is the one for proofs and type-level arguments: it exists so the checker
can reason about something that has no runtime representation at all. You will
meet it properly in the laws chapters.

`+x` is the interesting one, and it does not always work:

```python
{{#include ../affinity/t4_arrplus.bend}}
```

```
Error:
- expected : Data
- observed : Type
Location: main
4>|   +a = [0 : U32*4n]
```

Bend is telling you that `+` is not a permission you grant. It is a property you
*ask* for, and the type has to already have it. An `Array` does not.

## Kinds: the property lives on the type

Types themselves are sorted into two kinds, and the kind is part of a type's
declaration:

```python
type Array<-T: Type> is Type:      # <- not copyable
type List<a, -A: Kind(a)> is Kind(a)   # <- copyable when A is
```

```
Type = Kind(&1)   may be used at most once -- a thing with identity
Data = Kind(&2)   may be copied           -- a thing without identity
```

So `Data` is not a different sort of value; it is a type that carries a
permission. `+x` demands `Data` because **you cannot copy a thing that cannot be
copied**, and that is the whole content of the error message above.

`Base` declares 22 types. **13 are `is Data` and exactly 3 are `is Type`.** The
other 6 — `List`, `Maybe`, `Either`, `Result`, `Map`, `Sigma` — are parameterised
by their own kind, which is the subject of the next section. The three `Type`s
are worth reading as a list, because they are not arbitrary:

```
Array      a block of mutable memory
IO.OP      one IO operation
App        an application window
```

All three are *handles*. Copying a block of mutable memory would break the
guarantee that in-place rewriting does not need to copy — two names for one
block means the rewrite is visible through both, which is precisely what the
`Type`/`Data` split exists to prevent. Copying an IO operation would forge a
resource that was never created.

And `List<U32>` is `Data`, because copying a list just copies a structure. So
this is accepted:

```python
{{#include ../affinity/t8_listplus.bend}}
```

```
$ bend t8_listplus.bend
6n
```

while the same shape without `+` is refused:

```python
{{#include ../affinity/t9_listonly.bend}}
```

```
Error:
- expected : xs
- observed : xs (consumed more than once)
```

## The loose end from the lists chapter

Now the signature that looked strange makes sense:

```python
type List<a, -A: Kind(a)> is Kind(a)
```

`A` is the list's own kind, threaded through as a type parameter — so a list's
declaration *says* whether it may be copied, and `List.range` returns
`List<&2, Nat>` because the numbers it builds are freely copyable.

It also explains the oddest signature in the standard library, which the lists
chapter flagged:

```python
def List.append(a, -A: Kind(a), xs: List<a, A>, ys: List<a, A>) -> List<a, A>
```

The quantity is the first argument because a list is parameterised by its kind,
and a function that takes lists cannot ignore that. You thread it through at the
call site:

```python
List.append(&2, Nat, xs, ys)
```

Bend is not hiding the copy question. It is making you answer it, at every call
site, forever.

## What `+` actually costs

It is not free, and the guide says why in the same breath as the no-GC claim:

> Since values are affine, a `match` frees the node it opens on the spot, and
> **only `+` values carry a reference count.**
>
> — `GUIDE.txt:586`

So the price of `+x` is a runtime reference count — a real increment, decrement
and check, on every use. When you write `+x` you are trading the thing that makes
Bend fast for the convenience of not restructuring your code. Do it when the
restructure is worse, not by default.

## Closures, and a restriction that made the language faster

One more type refuses `+`, and the refusal is the same one:

```python
{{#include ../affinity/t6_closureplus.bend}}
```

```
Error:
- expected : Data
- observed : Type
Location: main
4>|   +f = {x => (x + 1 : U32) : U32 -> U32}
```

A closure is `Type`, so it can be called exactly once, and there is no way to
mark it otherwise. `+` does not open this door.

This looks like a real limitation, and for a while it is. Then you find the
answer, and the answer is better than the thing it replaced:

```python
{{#include ../affinity/t10_template.bend}}
```

```
$ bend t10_template.bend
42
```

The `~` on the parameter means **template**, and the `~` at the call site is what
makes the argument one. `twice` is inlined at compile time, and each distinct
argument compiles its own copy of the function — so `f` can be called as many
times as the body likes, because at runtime there is no closure there at all. Not
a function pointer, not a reference-counted box. Inlined, and free.

> **The error you will actually hit** is not about templates at all. Leave the `~`
> off the call site and the argument becomes an ordinary affine value, which
> cannot be used twice — and Bend says so, without mentioning the `~` it is
> missing:
>
> ```
> Error:
> - expected : -f
> - observed : f (consumed more than once)
> Location: twice~0
> ```
>
> Kept as [`affinity/t11_templatemiss.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/affinity/t11_templatemiss.bend).
> `Location: twice~0` is the only hint that this is a specialized copy — and it
> is not much of a hint unless you already know what `~` is.

> Bend's type system refuses to let you copy a closure. The answer the language
> arrived at is not "write more code" — it is **"inline the function"**, which is
> faster than the version that would have been allowed.

Hold on to that shape. It recurs throughout this book: a restriction that looks
like a wall turns out to be the reason the thing is fast.

## The files

| | | |
|---|---|---|
| [`affinity/t2_plus.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/affinity/t2_plus.bend) | ✅ | `+` on a `Data` type |
| [`affinity/t4_arrplus.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/affinity/t4_arrplus.bend) | ❌ | `+` on an `Array` |
| [`affinity/t5_closure.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/affinity/t5_closure.bend) | ❌ | a closure called twice |
| [`affinity/t6_closureplus.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/affinity/t6_closureplus.bend) | ❌ | `+` on a closure — same error |
| [`affinity/t8_listplus.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/affinity/t8_listplus.bend) | ✅ | `+` on a list |
| [`affinity/t9_listonly.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/affinity/t9_listonly.bend) | ❌ | the same list, without `+` |
| [`affinity/t10_template.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/affinity/t10_template.bend) | ✅ | `~f`, called twice |
| [`affinity/t11_templatemiss.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/affinity/t11_templatemiss.bend) | ❌ | the same call without `~` |

Next: [arrays](arrays.md) — where the two kinds collide, and a read hands you
back more than you asked for.
