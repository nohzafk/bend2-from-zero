# tcp — sockets

| file | question | result |
|---|---|---|
| `roundtrip.bend` | listen, connect, send, recv — server and client forked in one program | ✅ `server got: ping`, `client got: pong`, both lanes |
| `refused.bend` | connect where nobody listens | ❌ `Connection refused`, rc **61** (`ECONNREFUSED`) |

`roundtrip.bend` is the unwrap pattern at its fullest: `TCP.accept` hands back
`(Listener & Result<..., Socket>)`, and both halves are used — the listener
stays whole for the next accept, the socket goes to a spawned task.

Running:

```sh
cd fx/tcp
bend roundtrip.bend
bend refused.bend      # ❌ rc 61
```

Book: chapter 19.
