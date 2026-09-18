# The proof of LIFE_LAWS.bend's tree_is_serial: induction on the depth d.
#
# The shape follows demos/pure_par_sum. The goal is {tree == loop}, and every
# rewrite moves the *right* side -- the spec -- into the implementation's
# shape, until both sides are the same term. `%e : P` rewrites with
# e : {a == b}, where P is the goal with `_` marking b, and the goal gets a
# there: a lemma is written with the form you want to eliminate on the RIGHT.
import Base
import ./life_par.bend as Par
import ./LIFE_LAWS.bend as Laws

# Nat.add recurses on its first argument, so Nat.add(k, 0n) is stuck when k is
# a variable. That is the only reason this lemma exists.
def add_zero(a: Nat) -> {Nat.add(a, 0n) == a : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}

# (a + b) + c == a + (b + c). This is the direction the offsets need: the
# right subtree starts at k + 2^p * blk, which has to be seen as (k + 1) + q
# before the induction hypothesis on cells_add applies.
def add_assoc(a: Nat, -b: Nat, -c: Nat) -> {Nat.add(Nat.add(a, b), c) == Nat.add(a, Nat.add(b, c)) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_assoc(p, b, c) : {1n+Nat.add(Nat.add(p, b), c) == 1n+_ : Nat}
      {==}

# Splitting a sequential loop: n cells from k, then m cells from k + n, is the
# same list as n + m cells from k.
def cells_add(
  +g: List<&2, Nat>, +w: Nat, +h: Nat, +n: Nat, +m: Nat, +k: Nat
) -> {Par.app(Par.block(g, w, h, n, k), Par.block(g, w, h, m, Nat.add(k, n))) == Par.block(g, w, h, Nat.add(n, m), k) : List<&2, Nat>}:
  match n:
    case 0n:
      %add_zero(k) : {Par.block(g, w, h, m, Nat.add(k, 0n)) == Par.block(g, w, h, m, _) : List<&2, Nat>}
      {==}
    case 1n+q:
      %add_assoc(k, 1n, q) : {Par.app(Par.block(g, w, h, 1n+q, k), Par.block(g, w, h, m, _)) == Par.block(g, w, h, Nat.add(1n+q, m), k) : List<&2, Nat>}
      %cells_add(g, w, h, q, m, Nat.add(k, 1n)) : {Par.app(Par.block(g, w, h, 1n+q, k), Par.block(g, w, h, m, Nat.add(Nat.add(k, 1n), q))) == Con{Par.cellnext(g, w, h, k), _} : List<&2, Nat>}
      {==}

# The law itself. Depth 0 is one leaf, which is already the loop. At depth
# p + 1 the tree is two depth-p trees concatenated; cells_add splits the
# spec's single loop into those same two loops, and the two induction
# hypotheses turn each half of the spec into the tree that computes it.
def Laws.tree_is_serial(d, g, w, h, blk, k):
  match d:
    case 0n:
      {==}
    case 1n+p:
      %cells_add(g, w, h, Par.cells_in(p, blk), Par.cells_in(p, blk), k) : {Par.tree_cells(1n+p, g, w, h, blk, k) == _ : List<&2, Nat>}
      %Laws.tree_is_serial(p, g, w, h, blk, k) : {Par.tree_cells(1n+p, g, w, h, blk, k) == Par.app(_, Par.block(g, w, h, Par.cells_in(p, blk), Nat.add(k, Par.cells_in(p, blk)))) : List<&2, Nat>}
      %Laws.tree_is_serial(p, g, w, h, blk, Nat.add(k, Par.cells_in(p, blk))) : {Par.tree_cells(1n+p, g, w, h, blk, k) == Par.app(Par.tree_cells(p, g, w, h, blk, k), _) : List<&2, Nat>}
      {==}
