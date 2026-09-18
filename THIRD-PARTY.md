# Third-party notices

This repository redistributes three files from
[HigherOrderCO/bend](https://github.com/bendlang/bend), the Bend 2 compiler.
They are **unmodified copies**, kept here so the book's code can be read and run
without a second checkout.

| File here | Upstream path | State |
|---|---|---|
| `GUIDE.txt` | `guide/GUIDE.md` | byte-identical, extension changed |
| `gpu/mandelbrot/main.bend` | `bench/runtime/mandelbrot/main.bend` | byte-identical |
| `gpu/queens/main.bend` | `bench/runtime/queens/main.bend` | byte-identical |

Taken from upstream commit `e6676b080f25b1bc1bf5b5b7d7a17e22f8022599`
("Bend 2.0.5", 2026-09-17).

Licensed under the Apache License, Version 2.0. The full text is in
[`licenses/Apache-2.0.txt`](licenses/Apache-2.0.txt). Copyright 2026
HigherOrderCO.

Apache-2.0 §4 lists what a redistributor must do. Each item, and how it is met
here:

- **§4(a) — give recipients a copy of the License.** `licenses/Apache-2.0.txt`.
- **§4(b) — mark files you changed.** Does not apply: nothing here is modified.
- **§4(c) — retain existing copyright and attribution notices.** The files carry
  no per-file headers, and the upstream `LICENSE` is reproduced whole and
  unaltered, so nothing was dropped.
- **§4(d) — carry a NOTICE file if the work has one.** Upstream has no `NOTICE`
  file, so there is nothing to carry over.

To refresh these files from a newer upstream:

```sh
cd bend && git pull
cp guide/GUIDE.md                     ../GUIDE.txt
cp bench/runtime/mandelbrot/main.bend ../gpu/mandelbrot/main.bend
cp bench/runtime/queens/main.bend     ../gpu/queens/main.bend
cd ..
cmp GUIDE.txt bend/guide/GUIDE.md                                       # verify
cmp gpu/mandelbrot/main.bend bend/bench/runtime/mandelbrot/main.bend
cmp gpu/queens/main.bend     bend/bench/runtime/queens/main.bend
```

Everything else in this repository — the book under `src/`, and the probes and
experiments under `basics/`, `affinity/`, `arrays/`, `parallel/`, `gpu/`,
`life/` — is not covered by the notice above.
