# The proof of LIFE_ANIM_LAWS.bend's frame_is_spec.
#
# Same shape as LIFE_PAR_PROOF.bend: the goal is {impl == spec}, and every
# `%lem(args) : P` moves one side into the other's shape. P is the goal AFTER
# the rewrite, with `_` at the position the lemma's LEFT side was put in. So a
# lemma is written {target == what-is-there-now}: its right side is the form
# the goal currently holds, its left side is the form that replaces it.
#
# The first five lemmas are library gaps -- Base has no String lemmas at all.
import Base
import ./life_anim.bend as Anim
import ./LIFE_ANIM_LAWS.bend as Laws

# ---- library: append ----

# String.append matches on its FIRST argument, so append(a, SNil{}) is stuck
# when a is a variable. This is the only reason the lemma exists.
def append_nil2(a: String) -> {a == String.append(a, SNil{}) : String}:
  match a:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      %append_nil2(t) : {SCon{h, t} == SCon{h, _} : String}
      {==}

def append_assoc2(a: String, -b: String, -c: String)
  -> {String.append(a, String.append(b, c)) == String.append(String.append(a, b), c) : String}:
  match a:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      %append_assoc2(t, b, c) : {SCon{h, String.append(t, String.append(b, c))} == SCon{h, _} : String}
      {==}

# ---- library: reverse ----

# reverse.go carries an accumulator, so it is stuck on a variable. Its
# invariant: the reversed prefix comes first, then the accumulator.
def reverse_go_spec(s: String, +acc: String)
  -> {String.append(String.reverse(s), acc) == String.reverse.go(s, acc) : String}:
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      %reverse_go_spec(t, SCon{h, SNil{}}) : {String.append(_, acc) == String.reverse.go(t, SCon{h, acc}) : String}
      %append_assoc2(String.reverse(t), SCon{h, SNil{}}, acc) : {_ == String.reverse.go(t, SCon{h, acc}) : String}
      %reverse_go_spec(t, SCon{h, acc}) : {String.append(String.reverse(t), SCon{h, acc}) == _ : String}
      {==}

# reverse(append(a, b)) == append(reverse(b), reverse(a)).
def reverse_append2(a: String, +b: String)
  -> {String.append(String.reverse(b), String.reverse(a)) == String.reverse(String.append(a, b)) : String}:
  match a:
    case SNil{}:
      %append_nil2(String.reverse(b)) : {_ == String.reverse(b) : String}
      {==}
    case SCon{+h, +t}:
      %reverse_go_spec(t, SCon{h, SNil{}}) : {String.append(String.reverse(b), _) == String.reverse.go(String.append(t, b), SCon{h, SNil{}}) : String}
      %reverse_go_spec(String.append(t, b), SCon{h, SNil{}}) : {String.append(String.reverse(b), String.append(String.reverse(t), SCon{h, SNil{}})) == _ : String}
      %reverse_append2(t, b) : {String.append(String.reverse(b), String.append(String.reverse(t), SCon{h, SNil{}})) == String.append(_, SCon{h, SNil{}}) : String}
      %append_assoc2(String.reverse(b), String.reverse(t), SCon{h, SNil{}}) : {String.append(String.reverse(b), String.append(String.reverse(t), SCon{h, SNil{}})) == _ : String}
      {==}

# ---- library: cell ----

# WHY THIS LEMMA IS THE WHOLE POINT. rowrev reverses CELLS; String.reverse
# reverses CHARACTERS. A row survives the one-reverse trick only because each
# cell is restored by a character reversal, i.e. is a palindrome.
def pick_pal(b: Bool)
  -> {Bool.pick(String, b, "██", "  ") == String.reverse(Bool.pick(String, b, "██", "  ")) : String}:
  match b:
    case False{}:
      {==}
    case True{}:
      {==}

def cell_pal(v: Nat) -> {Anim.cell(v) == String.reverse(Anim.cell(v)) : String}:
  %pick_pal(Nat.is_eq(v, 1n)) : {Anim.cell(v) == _ : String}
  {==}

# ---- the row ----

# reverse(rowrev(r, acc)) is the row's cells in order, then the reversed acc.
# Inducting on r needs the accumulator spelled out, hence the -acc.
def rowrev_spec(r: List<&2, Nat>, +acc: String)
  -> {String.append(String.reverse(acc), Laws.spec_row(r)) == String.reverse(Anim.rowrev(r, acc)) : String}:
  match r:
    case Nil{}:
      %append_nil2(String.reverse(acc)) : {_ == String.reverse(acc) : String}
      {==}
    case Con{+h, +t}:
      %rowrev_spec(t, String.append(Anim.cell(h), acc)) : {String.append(String.reverse(acc), String.append(Anim.cell(h), Laws.spec_row(t))) == _ : String}
      %reverse_append2(Anim.cell(h), acc) : {String.append(String.reverse(acc), String.append(Anim.cell(h), Laws.spec_row(t))) == String.append(_, Laws.spec_row(t)) : String}
      %cell_pal(h) : {String.append(String.reverse(acc), String.append(Anim.cell(h), Laws.spec_row(t))) == String.append(String.append(String.reverse(acc), _), Laws.spec_row(t)) : String}
      %append_assoc2(String.reverse(acc), Anim.cell(h), Laws.spec_row(t)) : {String.append(String.reverse(acc), String.append(Anim.cell(h), Laws.spec_row(t))) == _ : String}
      {==}

# ---- the frame ----

# The accumulator invariant over Rows: reverse(framerev(rs, acc)) is the
# reversed acc, then the spec's frame. At acc = SNil that is exactly the law.
def inner(rs: Anim.Rows, +acc: String)
  -> {String.append(String.reverse(acc), Laws.spec_rows(rs)) == String.reverse(Anim.framerev(rs, acc)) : String}:
  match rs:
    case Anim.RNil{}:
      %append_nil2(String.reverse(acc)) : {_ == String.reverse(acc) : String}
      {==}
    case Anim.RCons{+r, +t}:
      %inner(t, String.append("\n", String.append(Anim.rowrev(r, SNil{}), acc))) : {String.append(String.reverse(acc), String.append(Laws.spec_row(r), String.append("\n", Laws.spec_rows(t)))) == _ : String}
      %reverse_append2("\n", String.append(Anim.rowrev(r, SNil{}), acc)) : {String.append(String.reverse(acc), String.append(Laws.spec_row(r), String.append("\n", Laws.spec_rows(t)))) == String.append(_, Laws.spec_rows(t)) : String}
      %reverse_append2(Anim.rowrev(r, SNil{}), acc) : {String.append(String.reverse(acc), String.append(Laws.spec_row(r), String.append("\n", Laws.spec_rows(t)))) == String.append(String.append(_, "\n"), Laws.spec_rows(t)) : String}
      %rowrev_spec(r, SNil{}) : {String.append(String.reverse(acc), String.append(Laws.spec_row(r), String.append("\n", Laws.spec_rows(t)))) == String.append(String.append(String.append(String.reverse(acc), _), "\n"), Laws.spec_rows(t)) : String}
      %append_assoc2(String.reverse(acc), Laws.spec_row(r), "\n") : {String.append(String.reverse(acc), String.append(Laws.spec_row(r), String.append("\n", Laws.spec_rows(t)))) == String.append(_, Laws.spec_rows(t)) : String}
      %append_assoc2(String.reverse(acc), String.append(Laws.spec_row(r), "\n"), Laws.spec_rows(t)) : {String.append(String.reverse(acc), String.append(Laws.spec_row(r), String.append("\n", Laws.spec_rows(t)))) == _ : String}
      %append_assoc2(Laws.spec_row(r), "\n", Laws.spec_rows(t)) : {String.append(String.reverse(acc), String.append(Laws.spec_row(r), String.append("\n", Laws.spec_rows(t)))) == String.append(String.reverse(acc), _) : String}
      {==}

# ---- the law ----

def Laws.frame_is_spec(rs):
  %inner(rs, SNil{}) : {String.append("\u{1B}[H", _) == String.append("\u{1B}[H", Laws.spec_rows(rs)) : String}
  {==}
