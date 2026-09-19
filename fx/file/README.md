# file — the File handle

A fallible effect hands back a pair: the handle, and a `Result`. A read gives
`(File & Result<&1, &1, U32 & String, String>)`; a write gives the same shape
with `Unit` inside. The handle has exactly one owner at a time, so every
effect on it gives it back — that is the whole pattern of this directory.

| file | question | result |
|---|---|---|
| `roundtrip.bend` | write, size, close, reopen, read | ✅ `size=11`, `read back: hello, file` |
| `position.bend` | two 5-byte reads, then `read_at` | ✅ `chunk: [hello]`, `chunk: [, fil]` — the position advances; `at-bytes=4` |
| `open_missing.bend` | open a file that is not there | ❌ `No such file or directory`, rc 2 |
| `read_after_close_bad.bend` | use the handle after close | ❌ does not compile — `consumed more than once`; handle misuse is static |

The canonical unwrap, from `roundtrip.bend` — destructure the pair in a
parameter position, then `IO.pass` the Result:

```bend
def r_done(m: File & Result<&1, &1, U32 & String, String>) -> IO(Unit):
  (f, r) = m
  do IO<Unit>:
    s : String <- IO.pass(String, r)
    IO.print("read back: " ++ s)
    File.close(f)
```

Running:

```sh
cd fx/file
bend roundtrip.bend    # ✅ writes out.txt next to the source
bend position.bend     # ✅
```

Book: chapter 19.
