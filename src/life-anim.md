# A bug that type-checks

The O(n) engine renders a 40×16 grid in well under a millisecond, so the last
thing the Life example does with it is none of Life's business: it wraps the
engine in a loop that writes a frame and sleeps. The animation is not the point.
The loop is the first time this book calls IO for real, and the renderer goes
wrong in a way that nothing between your edit and your terminal objects to —
the types pass, the program runs, the output is garbage. One of the two failures
this chapter walks into is worth more than the animation it came from.

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

Write a frame, sleep 70 ms, compute the next generation, repeat. This is the
recursion shape every earlier chapter used — match on the shrinking parameter,
 recurse on the rest — with one difference: the result is no longer a value,
it is **an effect**, `IO(Unit)`, a program that touches the world. The shrinking
parameter — generations remaining — is leftmost, as the termination checker
requires. `IO.write` writes exactly the string; `IO.print` would append a
newline, which for a frame you have already ended with one is a stray blank
line per generation.

The Effects part picks this up and takes it apart. Here it only has to be
recognisable.

## There is no `\e`

The frame is text, and text on a terminal starts with escape characters. Bend's
string escapes are:

```
\n  \t  \r  \0  \\  \'  \"  \u{...}
```

**There is no `\e` and no `\x1b`.** ESC is `\u{1B}`. And `\033` does not error —
it parses as `\0` followed by a literal `33`, giving you a NUL byte and the
characters "33" in your output, which is a much worse failure than a
rejected program.

The rendering strategy itself needs one sentence: the first frame hides the
cursor, and every frame prepends `\u{1B}[H` — cursor to the top-left — and
overwrites in place. Clearing the whole screen each frame repaints it and
flickers; overwriting does not.

## The bug

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

Both are `String`, both type-check, both run. The type system has nothing to
say about it.

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

## Checking it without eyes

"It looks right" is not a check, and a 22-second animation is not something to
re-run to compare. So the three patterns in the grid were chosen because each
has a **distinguishable behaviour** — the glider moves one cell diagonally every
four generations, the blinker alternates horizontal and vertical, the block
does nothing — and the frames were decoded and measured, not watched. The
glider's live cells did shift by exactly (+1,+1) across four generations.

## Running it

```sh
cd life && bend life_anim.bend
```

320 generations × 70 ms ≈ 22 seconds. Both backends work; the compiled one is
smoother. One thing was confirmed before the animation was worth writing: the
output **streams** — bytes appear from the first seconds and grow roughly
linearly, measured, native-compiled. If the runtime buffered, the first 21
seconds would be a blank screen and the last second a mess; that would have
killed the whole idea, so it was checked rather than suspected.

To change the length or speed, two numbers at the end of `life_anim.bend`:
`loop(320n, ...)` and `IO.sleep(70)`.

Next: Inside a `do` block.
