import Base

# ❌ A bare parameter is a quantity, not a type. `a` stands for
# `-a: Quant` -- a number like &2 that travels with the value and is
# erased at runtime. A field must be typed with a real type, which is
# why the element type gets its own parameter, `A`.

type Chain<a, -A: Kind(a)> is Kind(a):
  End{}
  Cell{head: a, tail: Chain<a, A>}
