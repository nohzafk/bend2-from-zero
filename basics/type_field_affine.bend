import Base

# ❌ Fields are affine too. This `Shape` is the same as `exp_type.bend`
# minus the `+` on the two fields, and `area` multiplies a field by
# itself -- two uses of one affine value. The fix is not at the call
# site: the field must be marked `+` where the type declares it.

type Shape is Data:
  Circle{r: Nat}
  Square{s: Nat}

def area(x: Shape) -> Nat:
  match x:
    case Circle{r}:  (r * r : Nat)
    case Square{s}:  (s * s : Nat)
