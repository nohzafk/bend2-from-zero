# String.append and String.reverse — the lemmas Base does not ship.
#
# Base has 40 String functions and zero facts about any of them; every proof
# that touches strings writes these by hand.  First written for the Life
# proofs of bend2-from-zero, extracted here so the next proof can import
# them.  The rewrite rule that fixes each statement's orientation:
#   %lem(args) : P   P is the goal AFTER the rewrite, with `_` at the
#   position the lemma's LEFT side was put in; the right side is the form
#   being eliminated.
#
#   append_nil2      {a == append(a, "")}            eliminates append(a, "")
#   append_assoc2    {append(a, append(b,c)) == append(append(a,b), c)}
#   reverse_go_spec  {append(reverse(s), acc) == reverse.go(s, acc)}
#   reverse_append2  {append(reverse(b), reverse(a)) == reverse(append(a, b))}
#   reverse_reverse  {a == reverse(reverse(a))}      eliminates reverse(reverse(a))

import Base

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

def reverse_reverse(a: String) -> {a == String.reverse(String.reverse(a)) : String}:
  match a:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      %reverse_go_spec(t, SCon{h, SNil{}}) : {SCon{h, t} == String.reverse.go(_, SNil{}) : String}
      %reverse_append2(String.reverse(t), SCon{h, SNil{}}) : {SCon{h, t} == _ : String}
      %reverse_reverse(t) : {SCon{h, t} == String.append(String.reverse(SCon{h, SNil{}}), _) : String}
      {==}
