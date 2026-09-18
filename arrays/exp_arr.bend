import Base

# 探针 2：数组读的手感。a[i] 返回 Array<U32> & U32（一个 Sigma）
def main() -> IO(Unit):
  do IO<Unit>:
    a = [0 : U32*8n]
    a[5] <- 42
    IO.print(U32.show(a[5] : U32))
