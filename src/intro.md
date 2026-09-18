# Introduction

Bend is a programming language that makes an unusual promise: that you can
trust a program **you have not read**.

The pitch, in Bend's own words:

> In the post-AGI economy, humans will eventually stop writing and reading
> code, but we still need an ambiguity-free language to communicate our
> intents to the AIs building the world around us. Bend is that language.
>
> With **laws**, intents can be more precise than natural language. With
> **proofs**, we can mechanically verify the AI implemented our prompts
> correctly. And with a **fast compiler**, we can run that code at peak compute.

That is a large claim, and a claim about the future, which is hard to test.
This book does not try to test the future. It tests the language.

## What this book is

A tutorial. It was written by **playing** with Bend, not by reading its
documentation — which turns out to be the right way round, because Bend's error
messages teach faster than its prose does.

Everything here was run. Every number was measured on the machine described
below, and the book says how, so you can disagree with it. Where a claim of
Bend's could not be reproduced, or came out backwards, that is in the book too
— those parts are usually the most useful.

## Who it is for

**You can already program**, in some language, and you know **nothing about
Bend**. That is the assumption, and it is the only one.

Bend introduces a few ideas that most working programmers have no reference
point for: values that can be used *at most once*, parallel work that needs no
locks, and propositions enforced by a compiler. Each of those is built up from
nothing when it appears. There will be no sentence of the form "as you know,
in dependently typed languages…".

What is *not* explained is programming itself: what a function is, what a type
is, why a program has an output.

## The convention for broken code

Bend's compiler is precise, and its errors are short. Several of the
experiments in this book consist of **deliberately writing something wrong**
and seeing what it says, because that is where the language's real rules live.

Code that does not work is marked **❌**, and the error underneath is quoted
**verbatim**, pasted from a real run. Nothing in this book is an imagined
error message.

```python
# ❌ this is wrong on purpose
def f() -> Nat:
  1n + 0n

```
```
Error:
- message  : ...what the compiler really said
```

Code marked ❌ is kept in the repository as runnable files, so you can break
it yourself.

## How to read it

The chapters are ordered the way the ideas depend on each other, and they are
meant to be read in order. Roughly:

- **The language** — the syntax and the parts of the standard library this book
  actually uses.
- **The idea that changes everything** — affine values. Until this lands,
  nothing about Bend makes sense; after it, most of the language is obvious.
- **Making it fast** — parallel work on the CPU, then the GPU, and when each
  one loses.
- **A worked example** — Conway's Life, built four times: naively, then fast,
  then parallel, then moving. Every number is measured.
- **Laws** — turning a belief about your program into something a compiler
  checks for you.

Each chapter ends with the files it came from, so you can read the code without
the book in the way.

## What this was built on

| | |
|---|---|
| Bend | 2.0.5 |
| Machine | Apple M3 Max, 10 performance cores + 4 efficiency cores, macOS |
| Verified on | this machine only — the numbers are one machine's numbers |

Bend is young. Version 2.0.5 was current while this was written, and some of
what follows will have been fixed by the time you read it.
