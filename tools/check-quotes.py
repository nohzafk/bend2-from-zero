#!/usr/bin/env python3
"""Check every quoted compiler error against a real run.

The book promises that each quoted error is pasted verbatim from a real run.
Nothing else enforces that: `run_drift.py` compares substrings, and the line
numbers a quote carries are part of no expectation there. So a probe file can
gain a comment line, the quote can keep the old line number, and every check
still passes while the book points at the wrong line.

How it decides what a quote came from: it does not guess. It runs the files the
book references, and asks which of them actually produce those lines. A quote
that no real run produces is the failure.

That matters because the naive approach -- "the file in the `{{#include}}`
above the quote" -- is wrong exactly where it is most needed: the two error
quotes in the first chapter are inline examples, not includes.

    python3 tools/check-quotes.py            # from the repo root

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


def candidates(root: pathlib.Path):
    """Every .bend file the book references, in a stable order."""
    src = root / "src"
    found = set()
    for md in src.glob("*.md"):
        text = md.read_text(encoding="utf-8")
        for m in re.finditer(r"\{\{#include\s+(\S+?)\s*\}\}", text):
            found.add(m.group(1).replace("../", ""))
        for m in BLOB.finditer(text):
            found.add(m.group(1))
    out = []
    for rel in sorted(found):
        if not rel.endswith(".bend"):
            continue
        p = (root / rel)
        if p.exists() and "bend/" not in rel:
            out.append(p)
    return out


def run(probe: pathlib.Path, bend: str, root: pathlib.Path, timeout: int):
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
    ap.add_argument("--timeout", type=int, default=180)
    args = ap.parse_args()

    root = pathlib.Path(args.root).resolve()
    src = root / "src"
    if not src.is_dir():
        print(f"no src/ under {root}", file=sys.stderr)
        return 2

    cache: dict[pathlib.Path, list] = {}

    def output_of(probe: pathlib.Path):
        if probe not in cache:
            cache[probe] = run(probe, args.bend, root, args.timeout) or []
        return cache[probe]

    quotes = []
    for chapter in sorted(src.glob("*.md")):
        for line_no, inc, markers in quotes_in(chapter):
            quotes.append((chapter, line_no, inc, markers))

    all_candidates = None
    checked = declared = failed = 0
    problems = []

    for chapter, line_no, inc, markers in quotes:
        rel = str(chapter.relative_to(root))
        if rel in DECLARED:
            declared += 1
            print(f"  decl  {rel}:{line_no}  ({DECLARED[rel]})")
            continue

        # fast path: the file the chapter includes right before the quote
        if inc and (root / inc).exists() and contains(output_of(root / inc), markers):
            checked += 1
            print(f"  ok    {rel}:{line_no}  {inc}")
            continue

        # otherwise: ask every file the book references
        if all_candidates is None:
            all_candidates = candidates(root)
            print(f"  (scanning {len(all_candidates)} referenced files)")
        hits = [p for p in all_candidates if contains(output_of(p), markers)]

        if hits:
            checked += 1
            names = ", ".join(str(h.relative_to(root)) for h in hits)
            note = "" if (inc and str(root / inc) in [str(h) for h in hits]) else "  (not the include above)"
            print(f"  ok    {rel}:{line_no}  {names}{note}")
        else:
            failed += 1
            problems.append(
                f"{rel}:{line_no}: no referenced file produces this quote\n"
                + "".join(f"        {m}\n" for m in markers)
            )

    print()
    for p in problems:
        print("FAIL " + p)
    print(f"{checked} quote(s) verified, {declared} declared, {failed} failing")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
