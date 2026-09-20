#!/usr/bin/env python3
"""Check every quoted compiler error and every quoted program output against a
real run.

The book promises that each quoted error is pasted verbatim from a real run, and
that each `$ bend x.bend` block is what the command really printed. Nothing else
enforces that: `run_drift.py` compares substrings, and the line numbers a quote
carries are part of no expectation there. So a probe file can gain a comment
line, the quote can keep the old line number, and every check still passes while
the book points at the wrong line.

How it decides what an error quote came from: it does not guess. It runs files
and asks which of them actually produce those lines. A quote that no real run
produces is the failure.

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

Shell transcripts are checked the same way, one command at a time: the command
is run from the directory its file lives in, and the quoted lines must appear,
in order and with nothing between them, in the command's output -- stdout first,
then stderr. Both streams, because a transcript is what the reader sees in a
terminal: a quoted compiler verdict goes to stderr, and so does Bend's own "All
terms check, ..." line. Quoting a prefix or a subset is fine (the chapters quote
the line they are talking about); quoting lines that were never printed, or
printing them in the wrong order, is not. A command that nothing can reproduce
is listed in DECLARED_TRANSCRIPTS with the reason, and a transcript that is
neither reproducible nor declared is a **failure**, so a new quoted result
cannot slip into the book unchecked.

Code from a long real file is quoted by line number -- `{{#include
../gpu/queens/main.bend:89:100}}` -- so a chapter can show the part it is
discussing without copying it. Ranges are checked to be in bounds and non-empty,
and the file they come from is pinned by digest: a range only means anything
against a known revision, and if the file moves under it the check says so
instead of silently showing other code.

    python3 tools/check-quotes.py            # from the repo root
    python3 tools/check-quotes.py --wide     # search the whole book

Exit 0 when every quote is produced by a real run, 1 otherwise. Sits next to
book-links.py in the Pages workflow.
"""
from __future__ import annotations

import argparse
import hashlib
import os
import pathlib
import re
import shutil
import subprocess
import sys

INCLUDE = re.compile(r"^\{\{#include\s+(\S+?)(?::(\d+):(\d+))?\s*\}\}$")
INCLUDE_ANY = re.compile(r"\{\{#include\s+([^\s:}]+)(?::(\d+):(\d+))?\s*\}\}")
MARKER = re.compile(r"^\s*(\d+)>?\|")
FENCE = re.compile(r"^```")
BLOB = re.compile(r"blob/main/([A-Za-z0-9_./-]+\.bend)")
BARE = re.compile(r"\b([A-Za-z0-9_]+/[A-Za-z0-9_]+\.bend)\b")
CMD = re.compile(r"^\$\s+(\S.*?)\s*$")
TRAILING_COMMENT = re.compile(r"\s+#.*$")
RUNNABLE = re.compile(r"^bend\s+(\S+\.bend)\s*$")

# Directories a probe can never live in: the git metadata, the mdBook output
# (which holds copies of the probes), and the vendored upstream clone.
SKIP_DIRS = {".git", "book", "__pycache__", "node_modules", "bend"}

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

# Transcript commands no run in this repo can reproduce, with the reason. Keyed
# by chapter and by the command line as the book shows it, with runs of
# whitespace collapsed to one space (so re-spacing a comment does not move the
# entry). The key is visible text on purpose: an entry whose command is gone
# from the book is reported as stale.
DECLARED_TRANSCRIPTS = {
    ("src/basics-strings.md", "$ bend esc_bad.bend | xxd"):
        "the quoted bytes are xxd's rendering of the program's output, not bend's; "
        "the byte claim itself is checked as manifest entry basics/esc_bad",
    ("src/effects.md", "$ echo $? # 7"):
        "a shell builtin reporting the previous command's exit status, not output",
    ("src/effects-2.md", "$ bend clock.bend"):
        "the output is a live uptime reading",
    ("src/effects-2.md", "$ bend clock.bend -o clock && ./clock"):
        "compiles and runs a native binary, and the output is a live uptime reading",
    ("src/laws-3.md", "$ bend PROOF.bend # with the import line removed"):
        "PROOF.bend belongs to the gate project the chapter builds, not to this "
        "repo, and the quote comes from a copy with the import line removed",
}

# A line-range include is a promise about one revision of a file: "lines 89-100
# are the case I am describing". If the file changes, that promise has to be
# re-checked by whoever changed it, so the check fails here instead of quietly
# showing different code. Re-read the ranges in src/, then update the digest.
# bend and mdBook are pinned the same way, for the same reason.
RANGE_PINS = {
    "gpu/queens/main.bend":
        "9ba530618a3449470b294a01a7d8670b67ba959d9bd09b67bb748917ade0676f",
    "gpu/mandelbrot/main.bend":
        "400b94705df43c5f6506ecba640db11ae91b24f74d58e39a5e5f7f56dcbabcfa",
    "life/life_row.bend":
        "b4d2c45662b38b2e52fede77ffe662a970dd6331d659b6b71ee9ca300acb01a9",
    "life/life_par.bend":
        "8e6b26f55ccddb398a80714451fbdc58277ee4243ec249c870c8681031d8f32d",
    "life/life_rowpar.bend":
        "2ca7b570d9e3d067c8b8652fafa5512234cc8d6d55be36d514c5ab4805ab948b",
}


def check_ranges(root: pathlib.Path, chapters):
    """Every line-range include: in bounds, non-empty, and pinned.

    This is how a chapter quotes part of a long real file without copying it, so
    the fragment cannot drift from the source. The digest pins are the other
    half: a range is only meaningful against a known revision.
    """
    problems = []
    used = set()
    for chapter in chapters:
        rel_chapter = str(chapter.relative_to(root))
        text = chapter.read_text(encoding="utf-8")
        for m in INCLUDE_ANY.finditer(text):
            if not m.group(2):
                continue
            relpath = m.group(1).replace("../", "")
            a, b = int(m.group(2)), int(m.group(3))
            where = f"{rel_chapter} -> {relpath}:{a}-{b}"
            path = root / relpath
            if not path.exists():
                problems.append(f"{where}: no such file")
                continue
            used.add(relpath)
            lines = path.read_text(encoding="utf-8").split("\n")
            if a < 1 or b < a:
                problems.append(f"{where}: not a range (start {a}, end {b})")
                continue
            if b > len(lines):
                problems.append(
                    f"{where}: past the end of the file ({len(lines)} lines)")
                continue
            if not "\n".join(lines[a - 1:b]).strip():
                problems.append(f"{where}: the range is blank")
                continue
            print(f"  ok    {where}  ({b - a + 1} lines)")
    return problems, used


def check_range_pins(root: pathlib.Path, used):
    """The files quoted by line number must still be the revision the ranges were
    written against -- otherwise the numbers point at other code, silently."""
    problems = []
    for relpath in sorted(used):
        got = hashlib.sha256((root / relpath).read_bytes()).hexdigest()
        pinned = RANGE_PINS.get(relpath)
        if pinned is None:
            problems.append(
                f"{relpath}: quoted by line number but not pinned -- add to RANGE_PINS:\n"
                f'        "{relpath}": "{got}",\n')
        elif got != pinned:
            problems.append(
                f"{relpath}: changed since its ranges were written "
                f"(sha256 {got[:16]}..., pinned {pinned[:16]}...)\n"
                f"        Re-read every range include that quotes it, then update "
                f"RANGE_PINS.\n")
        else:
            print(f"  ok    {relpath} is the pinned revision ({got[:12]}...)")
    return problems


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


def transcripts_in(chapter: pathlib.Path):
    """Yield (line_no, [(command, expected_lines)]) for each block with commands.

    A command is a line starting with `$`; the lines after it, up to the next
    command or the end of the block, are what the book says it printed.
    """
    for line_no, body in fenced_blocks(chapter):
        cmds = []
        for line in body:
            if CMD.match(line):
                cmds.append((line.rstrip(), []))
            elif cmds:
                cmds[-1][1].append(line.rstrip())
        if cmds:
            yield line_no, [(c, [x for x in exp if x.strip()]) for c, exp in cmds]


def referenced_by(text: str):
    """Every .bend path a chapter mentions, in a stable order."""
    found = set()
    for m in INCLUDE_ANY.finditer(text):
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


def find_bend_file(root: pathlib.Path, name: str, chapter_files):
    """The repo file a transcript names, preferring one this chapter references."""
    for p in chapter_files:
        if p.name == name:
            return p
    hits = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if d not in SKIP_DIRS)
        if name in filenames:
            hits.append(pathlib.Path(dirpath) / name)
    return hits[0] if hits else None


def run(probe: pathlib.Path, bend: str, root: pathlib.Path, timeout: int):
    """The marker lines a run of this file produces, or None if it timed out."""
    env = dict(os.environ, BEND_NO_TELEMETRY="1")
    try:
        r = subprocess.run([bend, str(probe)], capture_output=True, text=True,
                           timeout=timeout, env=env, cwd=str(root))
    except subprocess.TimeoutExpired:
        return None
    return [l.rstrip() for l in (r.stdout + r.stderr).split("\n") if MARKER.match(l)]


def run_transcript(probe: pathlib.Path, bend: str, timeout: int):
    """The lines a `bend <file>` run prints, or None if it timed out.

    Run from the file's own directory with the bare file name, which is how the
    book's transcripts are written. stdout first, then stderr, so the order is
    the same on every run; both streams count (see the module docstring).
    """
    env = dict(os.environ, BEND_NO_TELEMETRY="1")
    try:
        r = subprocess.run([bend, probe.name], capture_output=True, text=True,
                           timeout=timeout, env=env, cwd=str(probe.parent))
    except subprocess.TimeoutExpired:
        return None
    both = (r.stdout or "") + (r.stderr or "")
    return [l.rstrip() for l in both.split("\n") if l.strip()]


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
    checked = declared = 0
    t_checked = t_declared = 0
    failed = 0
    problems = []
    seen_transcripts = set()

    chapters = sorted(src.glob("*.md"))

    # ---- the code quoted by line number, and the revision it came from
    range_problems, range_files = check_ranges(root, chapters)
    problems.extend(range_problems)
    failed += len(range_problems)
    pin_problems = check_range_pins(root, range_files)
    problems.extend(pin_problems)
    failed += len(pin_problems)

    for chapter in chapters:
        rel = str(chapter.relative_to(root))
        chapter_files = existing(root, referenced_by(chapter.read_text(encoding="utf-8")))

        # ---- the quoted compiler errors
        if rel in DECLARED:
            for line_no, _, _markers in quotes_in(chapter):
                declared += 1
                print(f"  decl  {rel}:{line_no}  ({DECLARED[rel]})")
        else:
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

        # ---- the shell transcripts
        for line_no, cmds in transcripts_in(chapter):
            for raw, expected in cmds:
                where = f"{rel}:{line_no}"
                key = (rel, " ".join(raw.split()))

                if key in DECLARED_TRANSCRIPTS:
                    t_declared += 1
                    seen_transcripts.add(key)
                    print(f"  decl  {where}  {raw}")
                    print(f"        {DECLARED_TRANSCRIPTS[key]}")
                    continue

                body = TRAILING_COMMENT.sub("", raw).strip()
                body = body[1:].strip() if body.startswith("$") else body
                m = RUNNABLE.match(body)
                probe = find_bend_file(root, m.group(1), chapter_files) if m else None
                if probe is None:
                    failed += 1
                    why = ("is not a bare `bend FILE` command" if not m
                           else f"names {m.group(1)}, which is nowhere in the repo")
                    problems.append(
                        f"{where}: `{body}` {why} -- nothing here can check it.\n"
                        f"        Run something that produces it, or add it to "
                        f"DECLARED_TRANSCRIPTS with the reason.\n"
                    )
                    continue

                got = run_transcript(probe, args.bend, args.timeout)
                if got is None:
                    failed += 1
                    problems.append(f"{where}: `bend {probe.name}` exceeded "
                                    f"{args.timeout}s\n")
                    continue
                if not contains(got, expected):
                    failed += 1
                    problems.append(
                        f"{where}: `bend {probe.name}` prints something else "
                        f"({probe.relative_to(root)})\n"
                        f"        quoted: {' | '.join(expected)}\n"
                        f"        now:    {' | '.join(got)}\n"
                    )
                    continue

                t_checked += 1
                print(f"  ok    {where}  $ bend {probe.relative_to(root)}")

    for key in sorted(set(DECLARED_TRANSCRIPTS) - seen_transcripts):
        print(f"note: declared transcript is no longer in the book: {key[0]}  {key[1]}")

    print()
    for p in problems:
        print("FAIL " + p)
    if timed_out:
        print(f"note: {len(timed_out)} file(s) exceeded {args.timeout}s and were treated as "
              f"producing nothing: {', '.join(sorted(str(p.relative_to(root)) for p in timed_out))}")
        print()
    print(f"{checked} quote(s) verified, {declared} declared")
    print(f"{t_checked} transcript(s) verified, {t_declared} declared")
    print(f"{failed} failing")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
