# example.bend — what a consumer writes: pin the three packages by content
# hash, then use them.  The hashes are the current versions from the log in
# README.md; a consumer that pinned an older hash keeps working, unchanged,
# forever.
import Base
import 0x1ee1b5d0c2a66817bf368b849f3117fc/nat.bend as Nat
import 0x89df026edd2acf2673b5e469e037eaf1/string.bend as String
import 0x085d89db9ee8a21865e959816bb20e5b/list.bend as List

def rotate(+a: Nat, +b: Nat, +c: Nat)
  -> {Nat.add(Nat.add(a, b), c) == Nat.add(Nat.add(b, c), a) : Nat}:
  %Nat.add_comm(a, Nat.add(b, c)) : {Nat.add(Nat.add(a, b), c) == _ : Nat}
  %Nat.add_assoc(a, b, c) : {Nat.add(Nat.add(a, b), c) == _ : Nat}
  {==}

def reverse_cons(a: String, +c: Char)
  -> {String.append(SCon{c, SNil{}}, String.reverse(a)) == String.reverse(String.append(a, SCon{c, SNil{}})) : String}:
  %String.reverse_append2(a, SCon{c, SNil{}}) : {String.append(SCon{c, SNil{}}, String.reverse(a)) == _ : String}
  {==}

def append_nil_sym(xs: List<&2, Nat>)
  -> {List.append(&2, Nat, xs, Nil{}) == xs : List<&2, Nat>}:
  %List.append_nil2(xs) : {_ == xs : List<&2, Nat>}
  {==}
