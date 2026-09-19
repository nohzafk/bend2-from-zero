#!/usr/bin/env python3
"""Check every quoted compiler error against a real run.

The book promises that each quoted error is pasted verbatim from a real run.
Nothing else enforces that: `run_drift.py` compares substrings, and the line
numbers a quote carries are part of no expectation there. So a probe file can
gain a comment line, the quote can keep the old line number, and every check
still passes while the book points at the wrong line.

How it decides what a quote came from: it does not guess. It runs files and asks
which of them actually produce those lines. A quote that no real run produces is
the failure.

That matters because the naive approach -- "the file in the `{{#include}}`
above the quote" -- is wrong exactly where it is most needed: the two error
quotes in the first chapter are inline examples, not includes.

What it runs, cheapest first:

  1. the file the chapter includes immediately above the quote;
  2. the other files that chapter references, plus every probe `manifest.py`
     already declares as failing to compile. A quoted error has to come from a
     file that errors, and the manifest is the list of those. Both sets are
     short and fast.
  3. `--wide`: everything the book references. A diagnostic, off by default --
     `gpu/queens` and `gpu/mandelbrot` do not finish inside any sane timeout in
     run mode, so scanning everything costs two full timeouts before it can say
     anything. Step 2 covers the real cases, so this is for when step 2's answer
     is "nothing", which is itself worth knowing.

    python3 tools/check-quotes.py            # from the repo root
    python3 tools/check-quotes.py --wide     # search the whole book

Exit 0 when every quote is produced by a real run, 1 otherwise. Sits next to
book-links.py in the Pages workflow.
"""
from __future__ import annotations

import argparse
import os
import pathlib
import re
import shutil
import subprocess
import sys

INCLUDE = re.compile(r"^\{\{#include\s+(\S+?)\s*\}\}$")
MARKER = re.compile(r"^\s*(\d+)>?\|")
FENCE = re.compile(r"^```")
BLOB = re.compile(r"blob/main/([A-Za-z0-9_./-]+\.bend)")
BARE = re.compile(r"\b([A-Za-z0-9_]+/[A-Za-z0-9_]+\.bend)\b")

# Quotes that cannot come from a file, with the reason. Keep this short and
# specific: every entry is a quote nothing verifies any more.
DECLARED = {
    "src/laws-3.md": "the dangling-def error, produced by deleting a law and "
                     "re-running a proof (tools/drift/gate_matrix.sh), not by a "
                     "file that exists",
    "src/basics-strings.md": "the \\e example is an inline snippet in the chapter; "
                             "no file in this repo produces it. The chapter's real "
                             "escape probe is basics/esc_bad.bend, which is verified",
}


def fenced_blocks(path: pathlib.Path):
    """Yield (line_no, body_lines) for every fenced block."""
    lines = path.read_text(encoding="utf-8").split("\n")
    i = 0
    while i < len(lines):
        if not FENCE.match(lines[i]):
            i += 1
            continue
        j = i + 1
        body = []
        while j < len(lines) and not FENCE.match(lines[j]):
            body.append(lines[j])
            j += 1
        yield i + 1, body
        i = j + 1


def quotes_in(chapter: pathlib.Path):
    """Yield (line_no, include_before, marker_lines) for each quoted error."""
    last_include = None
    for line_no, body in fenced_blocks(chapter):
        stripped = [b for b in body if b.strip()]
        if len(stripped) == 1 and INCLUDE.match(stripped[0].strip()):
            last_include = INCLUDE.match(stripped[0].strip()).group(1).replace("../", "")
            continue
        markers = [b.rstrip() for b in body if MARKER.match(b)]
        if markers:
            yield line_no, last_include, markers
            last_include = None  # a quote only follows its include directly


def referenced_by(text: str):
    """Every .bend path a chapter mentions, in a stable order."""
    found = set()
    for m in re.finditer(r"\{\{#include\s+(\S+?)\s*\}\}", text):
        found.add(m.group(1).replace("../", ""))
    for rx in (BLOB, BARE):
        for m in rx.finditer(text):
            found.add(m.group(1))
    return sorted(found)


def erroring_probes(root: pathlib.Path):
    """The files manifest.py declares as not compiling -- the only ones a quoted
    compiler error can come from."""
    sys.path.insert(0, str(root / "tools" / "drift"))
    try:
        import manifest  # noqa: E402
    except Exception as exc:  # pragma: no cover - manifest is ours
        print(f"note: could not read manifest.py ({exc}); step 2 is chapter-scoped only")
        return []
    out = []
    for c in manifest.CHECKS:
        if c.get("group") != "probes-bad":
            continue
        p = root / c["dir"] / c["file"]
        if p.exists():
            out.append(p)
    return out


def existing(root: pathlib.Path, rels):
    out = []
    for rel in rels:
        if not rel.endswith(".bend") or rel.startswith("bend/"):
            continue
        p = root / rel
        if p.exists():
            out.append(p)
    return out


def run(probe: pathlib.Path, bend: str, root: pathlib.Path, timeout: int):
    """The marker lines a run of this file produces, or None if it timed out."""
    env = dict(os.environ, BEND_NO_TELEMETRY="1")
    try:
        r = subprocess.run([bend, str(probe)], capture_output=True, text=True,
                           timeout=timeout, env=env, cwd=str(root))
    except subprocess.TimeoutExpired:
        return None
    return [l.rstrip() for l in (r.stdout + r.stderr).split("\n") if MARKER.match(l)]


def contains(haystack, needle):
    n = len(needle)
    for i in range(len(haystack) - n + 1):
        if haystack[i:i + n] == needle:
            return True
    return False


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".")
    ap.add_argument("--bend", default=shutil.which("bend") or os.path.expanduser("~/.bend/bin/bend"))
    ap.add_argument("--timeout", type=int, default=120)
    ap.add_argument("--wide", action="store_true",
                    help="also search every file the book references (slow)")
    args = ap.parse_args()

    root = pathlib.Path(args.root).resolve()
    src = root / "src"
    if not src.is_dir():
        print(f"no src/ under {root}", file=sys.stderr)
        return 2

    declared_files = erroring_probes(root)
    cache: dict[pathlib.Path, list] = {}
    timed_out: set = set()

    def output_of(probe: pathlib.Path):
        if probe not in cache:
            got = run(probe, args.bend, root, args.timeout)
            if got is None:
                timed_out.add(probe)
                cache[probe] = []
            else:
                cache[probe] = got
        return cache[probe]

    wide = None
    checked = declared = failed = 0
    problems = []

    for chapter in sorted(src.glob("*.md")):
        rel = str(chapter.relative_to(root))
        if rel in DECLARED:
            for line_no, _, _markers in quotes_in(chapter):
                declared += 1
                print(f"  decl  {rel}:{line_no}  ({DECLARED[rel]})")
            continue

        chapter_files = existing(root, referenced_by(chapter.read_text(encoding="utf-8")))

        for line_no, inc, markers in quotes_in(chapter):
            where = f"{rel}:{line_no}"

            # step 1: the include directly above the quote
            if inc and (root / inc).exists():
                probe = root / inc
                if contains(output_of(probe), markers):
                    checked += 1
                    print(f"  ok    {where}  {inc}")
                    continue

            # step 2: this chapter's files, plus the probes that error at all
            pool = chapter_files + [p for p in declared_files if p not in chapter_files]
            hits = [p for p in pool if contains(output_of(p), markers)]
            if hits:
                checked += 1
                names = ", ".join(str(h.relative_to(root)) for h in hits)
                print(f"  ok    {where}  {names}")
                continue

            # step 3: everything, only on request
            if args.wide:
                if wide is None:
                    all_rels = set()
                    for md in src.glob("*.md"):
                        all_rels.update(referenced_by(md.read_text(encoding="utf-8")))
                    wide = existing(root, sorted(all_rels))
                    print(f"  (widening to all {len(wide)} referenced files)")
                hits = [p for p in wide if contains(output_of(p), markers)]
            if hits:
                checked += 1
                names = ", ".join(str(h.relative_to(root)) for h in hits)
                print(f"  ok    {where}  {names}  (not referenced by this chapter)")
            else:
                failed += 1
                hint = "" if args.wide else "  (re-run with --wide to search the whole book)"
                problems.append(
                    f"{where}: no file this chapter references produces this quote{hint}\n"
                    + "".join(f"        {m}\n" for m in markers)
                )

    print()
    for p in problems:
        print("FAIL " + p)
    if timed_out:
        print(f"note: {len(timed_out)} file(s) exceeded {args.timeout}s and were treated as "
              f"producing nothing: {', '.join(sorted(str(p.relative_to(root)) for p in timed_out))}")
        print()
    print(f"{checked} quote(s) verified, {declared} declared, {failed} failing")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
