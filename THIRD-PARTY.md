# Third-party notices

This repository redistributes two files from
[HigherOrderCO/bend](https://github.com/bendlang/bend), the Bend 2 compiler.
They are **unmodified copies**, pinned here because the book *measures* them and
a measurement needs a fixed input.

| File here | Upstream path | State |
|---|---|---|
| `gpu/mandelbrot/main.bend` | `bench/runtime/mandelbrot/main.bend` | byte-identical |
| `gpu/queens/main.bend` | `bench/runtime/queens/main.bend` | byte-identical |

Taken from upstream commit `e80e6922b632436ba1f2051441dd41a2a5e7c0a6`
("Bend 2.0.16: term_key is the identity of a term"); verified byte-identical at
that commit and at 2.0.5's `e6676b080f25b1bc1bf5b5b7d7a17e22f8022599`, which is
when the numbers in this book were first taken.

**The guide is deliberately not here.** The book quotes `bend guide`, but a copy
in this repository would be stale within days — Bend released six versions in
under three hours on 2026-09-19. Every install already carries a copy that
matches the compiler it came with (`bend guide`, or `~/.bend/guide/GUIDE.md`),
so the quotes cite it by section name instead. See the introduction.

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

To refresh these files from a newer upstream — and note that doing so
invalidates the numbers the book quotes, so the drift harness has to be re-run:

```sh
cd bend && git fetch --depth=200 origin main && git checkout origin/main
cp bench/runtime/mandelbrot/main.bend ../gpu/mandelbrot/main.bend
cp bench/runtime/queens/main.bend     ../gpu/queens/main.bend
cd ..
cmp gpu/mandelbrot/main.bend bend/bench/runtime/mandelbrot/main.bend
cmp gpu/queens/main.bend     bend/bench/runtime/queens/main.bend
python3 tools/drift/run_drift.py
```

Everything else in this repository — the book under `src/`, and the probes and
experiments under `basics/`, `affinity/`, `arrays/`, `parallel/`, `gpu/`,
`life/` — is not covered by the notice above.
