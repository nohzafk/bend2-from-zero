import Base

# ❌ The `is` clause is not optional decoration. Every type declaration
# carries one, because it is where the type says how often its values
# may be used -- and a checker that never searches needs it stated.

type Tree<a>:
  Leaf{value: a}
  Node{left: Tree<a>, right: Tree<a>}
