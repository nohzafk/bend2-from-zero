import Base

# 探针 1：终止检查器是否接受「结构性递归」做取模
# x mod n：对 x 做结构性递归，用 k 累积。每次调用 x 都变小（p 是 x 的真子部分）
def bump(+k: Nat, +n: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_lt(k, Nat.sub(n, 1n)), 1n+k, 0n)

def mod(+x: Nat, +n: Nat, +k: Nat) -> Nat:
  match x:
    case 0n:
      k
    case 1n+p:
      mod(p, n, bump(k, n))

def main() -> Nat:
  mod(9n, 4n, 0n)
