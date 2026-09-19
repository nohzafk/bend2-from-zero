# hub — what this repo publishes to the Bend hub

[hub.bend-lang.com](https://hub.bend-lang.com) has no names, no versions and
no accounts. A package **is** its content hash: publish the same bytes twice
and nothing happens, change anything and the hash changes — that is a new
package. There is no in-place update and no delete; a package is fetched once
(checked against its hash at that moment) and read from `~/.bend/lib/<hash>/`
after that. The one thing the hub therefore cannot keep is the record of
*which hash is current*. That record is this directory.

The packages so far are the reasoning gaps of `Base`: it ships a rich *term*
library and no *reasoning* library — not one fact about `Nat.add`, not one
about `String.append`, none about `List.append`. Each `.bend` file here is the
source of the version currently published; the log says which hash that is.

| published | package | hash | status |
|---|---|---|---|
| 2026-09-19 | `nat.bend` — add_zero, add_assoc (first cut; description empty) | `0xfa577b9cd7c0487dc8d5d772f4bba913` | superseded |
| 2026-09-19 | `nat.bend` — same two lemmas, header comment first | `0xcea4c3f899099eb5eb7e6595eaa9971a` | superseded |
| 2026-09-19 | `nat.bend` — the laws: zero, succ, assoc, comm | `0x1ee1b5d0c2a66817bf368b849f3117fc` | **current** |
| 2026-09-19 | `string.bend` — append / reverse lemmas, incl. reverse_reverse | `0x89df026edd2acf2673b5e469e037eaf1` | **current** |
| 2026-09-19 | `list.bend` — append / reverse / length lemmas (six) | `0x085d89db9ee8a21865e959816bb20e5b` | **current** |

"Superseded" is a social fact, not a hub fact: old hashes stay loadable, and a
consumer that pinned one keeps working unchanged. `example.bend` pins the
current set. The first comment line of each file is the description the hub
shows — keep it a one-line summary.

## Publishing a new version

```sh
cd hub
bend nat.bend            # check it first
bend nat.bend --publish  # mines a proof of work, prints the new import line
```

Publishing uploads the file and everything it imports (`Base` stays out) and
prints `import 0x<new hash>/nat.bend as Nat`. Then: add a row to the table,
update `example.bend`, commit. The older hashes are left alone — they cannot
be deleted, and there is no reason to want to.

## Why publish at all

Because a content hash is the only way to import a *pinned* fact, and because
these lemmas are work every proof repeats — `../life` wrote four of the String
ones by hand before `string.bend` existed. A published lemma set is also a
claim anyone can re-check: `bend string.bend` either prints
`All terms check.` or it does not.
