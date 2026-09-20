import Base

# ❌ `Cell`'s field is typed `a`, the header's quantity parameter, instead
# of the element type `A`. A count of uses cannot type a field; the
# chapter takes the compiler's answer apart just below. `exp_chain.bend`
# is this same declaration with the field fixed.

type Chain<a, -A: Kind(a)> is Kind(a):
  End{}
  Cell{head: a, tail: Chain<a, A>}
