# List.append, List.reverse and List.length — the lemmas Base does not ship.
#
# Base ships a rich term library for List and not one fact about it: nothing
# says append is associative, that reverse.go meets append, or that length is
# additive.  These six are the facts every proof over List ends up writing by
# hand.  Same shape, same proof idiom and same rewrite rule as the String
# package (0x89df026edd2acf2673b5e469e037eaf1/string.bend):
#
#   %lem(args) : P    P is the goal AFTER the rewrite, with `_` at the
#   position the lemma's LEFT side was put in; the right side is the form
#   being eliminated.  So a lemma is written {target == what-the-goal-holds-now}.
#
#   append_nil2      {a == append(a, [])}                    eliminates append(a, [])
#   append_assoc2    {append(a, append(b,c)) == append(append(a,b), c)}
#   reverse_go_spec  {append(reverse(a), acc) == reverse.go(a, acc)}
#   reverse_append2  {append(reverse(b), reverse(a)) == reverse(append(a, b))}
#   reverse_reverse  {a == reverse(reverse(a))}              eliminates reverse(reverse(a))
#   length_append    {length(a) + length(b) == length(append(a, b))}
#
# The rewrite rule decides each statement's orientation, so the statements are
# the ones a proof wants to rewrite *towards*: the left side is the shape the
# goal should end up in.
#
# Every parameter is used exactly once, except acc in reverse_go_spec and ys in
# reverse_append2: those two proofs rewrite twice through the same value, so the
# checker needs them marked + (reusable) -- the same mark string.bend puts on
# its acc. Every cons is matched as Con{+h, +t} for the same reason: the proofs
# mention the head in the goal and again in a step, and the tail in two steps.

import Base
# No Nat facts are imported: length_append's step goal prints with the
# successor already pulled out of the Nat.add (it matches on its first
# argument), so that proof needs only its own induction hypothesis.

def append_nil2(xs: List<&2, Nat>) -> {xs == List.append(&2, Nat, xs, Nil{}) : List<&2, Nat>}:
  match xs:
    case Nil{}:
      {==}
    case Con{+h, +t}:
      %append_nil2(t) : {h <> t == h <> _ : List<&2, Nat>}
      {==}

def append_assoc2(xs: List<&2, Nat>, ys: List<&2, Nat>, zs: List<&2, Nat>)
  -> {List.append(&2, Nat, xs, List.append(&2, Nat, ys, zs)) == List.append(&2, Nat, List.append(&2, Nat, xs, ys), zs) : List<&2, Nat>}:
  match xs:
    case Nil{}:
      {==}
    case Con{+h, +t}:
      %append_assoc2(t, ys, zs) : {h <> List.append(&2, Nat, t, List.append(&2, Nat, ys, zs)) == h <> _ : List<&2, Nat>}
      {==}

def reverse_go_spec(xs: List<&2, Nat>, +acc: List<&2, Nat>)
  -> {List.append(&2, Nat, List.reverse(&2, Nat, xs), acc) == List.reverse.go(&2, Nat, xs, acc) : List<&2, Nat>}:
  match xs:
    case Nil{}:
      {==}
    case Con{+h, +t}:
      %reverse_go_spec(t, h <> Nil{}) : {List.append(&2, Nat, _, acc) == List.reverse.go(&2, Nat, t, h <> acc) : List<&2, Nat>}
      %append_assoc2(List.reverse(&2, Nat, t), h <> Nil{}, acc) : {_ == List.reverse.go(&2, Nat, t, h <> acc) : List<&2, Nat>}
      %reverse_go_spec(t, h <> acc) : {List.append(&2, Nat, List.reverse(&2, Nat, t), h <> acc) == _ : List<&2, Nat>}
      {==}

def reverse_append2(xs: List<&2, Nat>, +ys: List<&2, Nat>)
  -> {List.append(&2, Nat, List.reverse(&2, Nat, ys), List.reverse(&2, Nat, xs)) == List.reverse(&2, Nat, List.append(&2, Nat, xs, ys)) : List<&2, Nat>}:
  match xs:
    case Nil{}:
      %append_nil2(List.reverse.go(&2, Nat, ys, [])) : {_ == List.reverse.go(&2, Nat, ys, []) : List<&2, Nat>}
      {==}
    case Con{+h, +t}:
      %reverse_go_spec(t, h <> Nil{}) : {List.append(&2, Nat, List.reverse.go(&2, Nat, ys, []), _) == List.reverse.go(&2, Nat, List.append(&2, Nat, t, ys), [h]) : List<&2, Nat>}
      %reverse_go_spec(List.append(&2, Nat, t, ys), h <> Nil{}) : {List.append(&2, Nat, List.reverse.go(&2, Nat, ys, []), List.append(&2, Nat, List.reverse(&2, Nat, t), h <> Nil{})) == _ : List<&2, Nat>}
      %reverse_append2(t, ys) : {List.append(&2, Nat, List.reverse.go(&2, Nat, ys, []), List.append(&2, Nat, List.reverse(&2, Nat, t), h <> Nil{})) == List.append(&2, Nat, _, h <> Nil{}) : List<&2, Nat>}
      %append_assoc2(List.reverse.go(&2, Nat, ys, []), List.reverse(&2, Nat, t), h <> Nil{}) : {List.append(&2, Nat, List.reverse.go(&2, Nat, ys, []), List.append(&2, Nat, List.reverse(&2, Nat, t), h <> Nil{})) == _ : List<&2, Nat>}
      {==}

def reverse_reverse(xs: List<&2, Nat>) -> {xs == List.reverse(&2, Nat, List.reverse(&2, Nat, xs)) : List<&2, Nat>}:
  match xs:
    case Nil{}:
      {==}
    case Con{+h, +t}:
      %reverse_go_spec(t, h <> Nil{}) : {h <> t == List.reverse.go(&2, Nat, _, []) : List<&2, Nat>}
      %reverse_append2(List.reverse(&2, Nat, t), h <> Nil{}) : {h <> t == _ : List<&2, Nat>}
      %reverse_reverse(t) : {h <> t == List.append(&2, Nat, List.reverse(&2, Nat, h <> Nil{}), _) : List<&2, Nat>}
      {==}

def length_append(xs: List<&2, Nat>, ys: List<&2, Nat>)
  -> {Nat.add(List.length(&2, Nat, xs), List.length(&2, Nat, ys)) == List.length(&2, Nat, List.append(&2, Nat, xs, ys)) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case Con{+h, +t}:
      %length_append(t, ys) : {1n+Nat.add(List.length(&2, Nat, t), List.length(&2, Nat, ys)) == 1n+_ : Nat}
      {==}
