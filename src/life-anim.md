# Making it move

The engine from the O(n) chapter is fast enough that animation is free. Forty by
sixteen is 640 cells; at the measured rate of about 70 ns per cell per generation
that is a rounding error. So this chapter is not about performance at all — it is
about the two things that went wrong the first time, both of which are about
**text**, and one of which is a good example of a bug that type-checks.

## The loop

```python
def loop(+left: Nat, +k: Nat, +rs: Rows) -> IO(Unit):
  match left:
    case 0n:
      IO.write("\u{1B}[?25h\n")
    case 1n+p:
      do IO<Unit>:
        IO.write(frame(rs))
        IO.sleep(70)
        loop(p, Nat.add(k, 1n), gen(rs))
```

Write a frame, sleep 70 ms, compute the next generation, repeat. The shrinking
parameter — generations remaining — is leftmost, as the termination checker
requires. `IO.write` writes exactly the string; `IO.print` would append a
newline, which for a frame you have already ended with one is a stray blank line
per generation.

Everything else in the animation is that loop plus a renderer.

## Trap 1: do not clear the screen

The first frame clears everything and hides the cursor:

```python
IO.write("\u{1B}[?25l\u{1B}[2J")
```

After that, **never again**. `[2J` erases the whole screen, and doing it every
frame makes the terminal blank and repaint — visible flicker on every generation.
Instead each frame starts with `[H`, which moves the cursor to the top-left and
overwrites in place:

```python
def frame(+rs: Rows) -> String:
  String.append("\u{1B}[H", String.reverse(framerev(rs, SNil{})))
```

The visible difference is immediate and it is worth trying both ways once, because
"clear the screen each frame" is the obvious implementation and it is the wrong
one.

A note on writing the escape itself. Bend's string escapes are:

```
\n  \t  \r  \0  \\  \'  \"  \u{...}
```

**There is no `\e` and no `\x1b`.** ESC is `\u{1B}`. And `\033` does not error —
it parses as `\0` followed by a literal `33`, giving you a NUL byte and the
characters "33" in your output, which is a much worse failure than a
rejected program.

## Trap 2: `String.reverse` flips characters, not cells

This is the bug worth the chapter.

Building a frame by appending cell by cell would be O(frame²) — each `append`
copies its left argument, and the left argument keeps growing. So the renderer
builds **backwards** and reverses once at the end:

```
framerev:  accumulate each row onto the front of the accumulator
frame:     String.reverse once, then prepend the cursor-home escape
```

One reversal, O(frame) total. But `String.reverse` reverses **characters**, and a
cell is *two* characters (`"██"` or `"  "`).

The first version reversed at two levels — once per row and once for the whole
frame — so every row was flipped twice and the result came out mirrored:

```
y coordinates all correct, x became 39 - x
```

That signature is what gave it away. A whole-grid mirror with one axis intact
points at per-row reversal, not at the pattern or the neighbour logic.

**The cost of fixing it is a constraint that now has to hold forever: every cell
must be a palindrome.** `"██"` and `"  "` both are, so reversing the character
stream reverses the cell order correctly. Change a cell to `"▐█"` — a perfectly
reasonable thing to do — and each row flips internally. That was measured: a 4×4
glider renders as

```
OXOX][][          instead of     []XO[][]
][][OX][                         [][]XO[]
```

Both are `String`, both type-check, both run. The type system has nothing to say
about it.

The mechanism, written out because it is easy to get backwards: `rowrev`
appends `cell(h)` **before** the accumulator, so it reverses the *order of cells*
and never touches the inside of one. The single `reverse` in `frame` flips
*characters*. Composing them gives

```
reverse (rowrev r)  ==  map reverse (map cell r)
```

so a row only comes out right when each cell equals its own character-reversal.
The palindrome property is not a style note. It is the **precondition of the
O(frame) optimisation**, and in the last part of this book it stops being a
comment and becomes a theorem: `LIFE_ANIM_PROOF.bend` has a lemma called
`cell_pal`, and without it the law does not hold.

## Verifying it without watching it

"It looks right" is not a check, and a 22-second animation is not something to
re-run to compare. So the three patterns in the grid were chosen so that each has
a **distinguishable behaviour**, and the behaviour was extracted and checked:

| pattern | what it should do | what the coordinates did |
|---|---|---|
| glider (left) | move +1,+1 every 4 generations | `(1,2)-(3,4)` → `(1,3)-(3,5)` → `(2,3)-(4,5)` → `(3,4)-(5,6)` ✓ |
| blinker (top right) | period 2, horizontal ↔ vertical | `(32,3)-(34,3)` ↔ `(33,2)-(33,4)` ✓ |
| block (bottom right) | nothing | `(32,10)-(33,11)` unchanged ✓ |

The glider's coordinates were obtained by decoding each frame's live cells and
running a connected-component analysis on them — so the claim is "four frames,
four component sets, each shifted by exactly (1,1) from the one before", not
"the shape looked like a glider".

## Streaming

One thing had to be confirmed before the animation was worth writing: **does the
output stream, or does it emerge all at once at the end?** If the runtime buffers,
the first 21 seconds are a blank screen and the last second is a mess.

It streams. Measured, native-compiled:

| elapsed | bytes written |
|---|---|
| 2 s | 39 KB |
| 4 s | 77 KB |
| 7 s | 114 KB |

Roughly linear, starting immediately. That is the fact the whole animation rests
on, and it is cheaper to check than to suspect.

## Running it

```sh
cd life && bend life_anim.bend
```

320 generations × 70 ms ≈ 22 seconds. Both backends work; the compiled one is
smoother.

To change the length or speed, two numbers at the end of `life_anim.bend`:
`loop(320n, ...)` and `IO.sleep(70)`.

Next: [Effects, and the event loop](effects.md).
