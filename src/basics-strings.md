# Strings and characters

A `String` in Bend is a linked list of characters — the same shape as the list
you just met, with one element type:

```python
type String is Data:
  SNil{}
  SCon{head: Char, tail: String}
```

So everything you know about the cost of lists applies here, and one more thing
does not: **text goes through this structure one character at a time.**

## `Char` is a character

Not a byte. Measured:

```python
String.length("█")    # 1
String.length("██")   # 2
String.length("😀")   # 1
```

This is worth stating explicitly because it will matter later, and because it is
the sort of thing that differs between languages and silently ruins programs. A
`Char` is a Unicode scalar value. So a string is a sequence of *characters*, and
`String.reverse` reverses characters — which is a precise statement you will need
in the chapter about the animation frame, where the whole renderer hangs off it.

## Escapes, and the trap with no name

The list of legal escapes is short, and the compiler will recite it at you if you
guess. This is not a made-up error message — it is what Bend answers to `"\e"`:

```python
def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("\e")
```

```
Error:
- expected : an escape (\n \t \r \0 \\ \' \" \u{1F600})
- observed : '"'
Location:
3 |   do IO<Unit>:
4>|     IO.print("\e")
```

Eight forms. `\n`, `\t`, `\r`, `\0`, a backslash, a quote, a double quote, and
`\u{...}`. That is all.

**There is no `\e` and no `\x1b`.** For a terminal escape you write `\u{1B}`:

```python
IO.print("\u{1B}[H")    # ESC [ H -- cursor to the top-left corner
```

Which brings us to the one that will cost you an afternoon, because it does not
produce an error at all:

```python
{{#include ../basics/esc_bad.bend}}
```

```
$ bend esc_bad.bend | xxd
00000000: 0033 330a                                .33.
```

`00 33 33 0a`. Not `1B`. Here is what happened: **there is no octal escape, and
`\0` is a perfectly legal one.** So `"\033"` parses as `\0` — a NUL byte —
followed by the two literal characters `3` and `3`. The program compiles, runs,
and emits something that is not the escape you wanted.

Kept as [`basics/esc_bad.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/basics/esc_bad.bend). This one is worth
remembering in the abstract, because the shape recurs: Bend's error messages are
excellent right up until you write something *legal but unintended*, and then
there is no message at all.

## The cost of text

Two functions, both `O(n)`, and neither is a problem by itself:

```python
String.append(a: String, b: String) -> String
String.length(s: String) -> Nat
```

Note that `append` takes no quantity argument, unlike `List.append`. Strings are
`Data` — freely copyable — so nothing has to be threaded through.

The cost that *is* a problem is the one you build by accident:

```python
# O(n^2): each append walks its first argument to find the end
String.append(String.append(String.append(a, b), c), d)
```

Every one of those calls copies the accumulated left side. Building a long string
this way is quadratic in its length, and nothing in the program looks wrong.

There is a standard fix, and it is the one this book's animation uses: **build
the string backwards, then reverse once at the end.** Reversing is `O(n)`, so
the whole construction becomes `O(n)`. `Base` itself uses this idiom —
`String.reverse` is an accumulator loop internally:

```python
def String.reverse.go(s: String, acc: String) -> String:
  match s:
    case SNil{}:
      acc
    case SCon{h, t}:
      String.reverse.go(t, SCon{h, acc})

def String.reverse(s: String) -> String:
  String.reverse.go(s, SNil{})
```

> **A shape to remember, and one to beware of.** That `reverse` is a helper with
> an accumulator, and the public function calls it with `SNil{}`. It is a good
> design and it will come back to bite the proof chapters: a function written
> this way is *stuck on a variable* — the checker cannot look inside it without
> knowing what `acc` is. When we get there, that is why three of the lemmas in
> the second proof exist at all.

## The files

| | |
|---|---|
| [`basics/exp_str.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/basics/exp_str.bend) | `\n` and `\t` in action |
| [`basics/esc_bad.bend`](https://github.com/nohzafk/bend2-from-zero/blob/main/basics/esc_bad.bend) | ⚠️ compiles, runs, emits the wrong bytes |

---

That is the language's surface. Syntax, numbers, lists, strings — nothing you
have seen so far would be out of place in a language you already know.

That ends now. The next chapter is about the one rule in Bend that changes how
you write every single function, and until it makes sense, nothing else about
Bend will.

Next: [affine values](affinity.md).
