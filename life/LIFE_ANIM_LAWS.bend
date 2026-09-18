# The law of the animated frame.
#
# `frame` builds the whole screen with ONE String.reverse at the end: rows are
# accumulated backwards (framerev), each row's *cells* backwards (rowrev), and
# the single char-level reverse undoes both at once. That is what makes it
# O(frame length) instead of O(n^2) with an append chain.
#
# The spec below is the same frame written the slow, obvious, append-heavy
# way. The law says the fast one equals it.
#
# The catch -- and the reason this law is not just a restatement -- is that
# the two levels disagree about what a "unit" is. rowrev reverses CELLS and
# leaves each cell's characters alone; String.reverse reverses CHARACTERS.
# Composing them gives
#
#     reverse (rowrev r) == map reverse (map cell r)
#
# so a row only comes out right if every cell is its own character-reversal,
# i.e. a palindrome. `cell` returns "██" or "  ", and both are. Change it to
# "▐█" and every row comes out mirrored -- measured, not reasoned: the 4x4
# glider renders as `OXOX][][` / `][][OX][` instead of `[]XO[][]` / `[][]XO[]`.
# That is the exact shape of the bug this repository already hit once.
#
# Written by hand, not by the AI. LIFE_ANIM_PROOF.bend proves it.
import Base
import ./life_anim.bend as Anim

# ---- the spec: what a frame should be, written the slow obvious way ----
def spec_row(+r: List<&2, Nat>) -> String:
  match r:
    case Nil{}:
      SNil{}
    case Con{h, t}:
      String.append(Anim.cell(h), spec_row(t))

def spec_rows(+rs: Anim.Rows) -> String:
  match rs:
    case Anim.RNil{}:
      SNil{}
    case Anim.RCons{r, t}:
      String.append(spec_row(r), String.append("\n", spec_rows(t)))

# LAW: the frame is the cursor-home escape, then the rows in order, each row's
# cells in order, each row followed by a newline.
law frame_is_spec:
  for +rs: Anim.Rows
  {Anim.frame(rs) == String.append("\u{1B}[H", spec_rows(rs)) : String}
