#!/usr/bin/env python3
"""book-links.py — report links in the built book that will not work for a reader.

    mdbook build && python3 tools/book-links.py [book]

Two kinds are checked, because the book has two kinds:

* every relative link (chapter to chapter, and anything else) must resolve
  against the files under `book/`, and must not climb above it — the published
  site serves `book/` as its root, so a leading `../` leaves the site;
* every `github.com/nohzafk/bend2-from-zero/blob/<ref>/<path>` link must name
  a file that exists in this repository and is tracked by git — the published
  site serves what the repository holds, and an untracked file is as good as
  missing;
* a paragraph announcing what comes next (`Next:`) carries no markdown links —
  the built pages already have prev/next arrows driven by the table of
  contents, and a hand-written link there is a second source of chapter order
  that drifts (it drifted three times before this rule existed).
"""
import html
import re
import subprocess
import sys
import urllib.parse
from pathlib import Path

GH_BLOB = "https://github.com/nohzafk/bend2-from-zero/blob/"


def check_next_paragraphs(src: Path, bad: list):
    """A `Next:` paragraph announces the next chapter in prose; no links."""
    link = re.compile(r"\[[^\]]*\]\([^)]+\)")
    for page in sorted(src.glob("*.md")):
        text = page.read_text()
        for m in re.finditer(r"^(?!#).*\bNext:", text, re.M):
            end = text.find("\n\n", m.start())
            para = text[m.start():end if end != -1 else len(text)]
            hit = link.search(para)
            if hit:
                line = text[:m.start()].count("\n") + 1
                bad.append((f"src/{page.name}:{line}", hit.group(0),
                            "the next-chapter announcement is prose, not a link"))


def main():
    book = Path(sys.argv[1] if len(sys.argv) > 1 else "book").resolve()
    if not book.is_dir():
        sys.exit("no book/ directory — run `mdbook build` first")

    repo = book.parent
    tracked = set()
    try:
        out = subprocess.run(["git", "-C", str(repo), "ls-files", "-z"],
                             capture_output=True, text=True, check=True).stdout
        tracked = {p for p in out.split("\0") if p}
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("warning: not a git checkout; the GitHub-target checks are skipped")

    bad = []
    pages = 0
    for page in sorted(book.rglob("*.html")):
        pages += 1
        text = page.read_text(errors="replace")
        for m in re.finditer(r'(?:href|src)="([^"]+)"', text):
            href = html.unescape(m.group(1))
            if href.startswith(GH_BLOB):
                rest = href[len(GH_BLOB):].split("#")[0].split("?")[0]
                _, _, path = rest.partition("/")
                path = urllib.parse.unquote(path)
                page_name = page.relative_to(book).as_posix()
                if not path:
                    bad.append((page_name, href, "no path after the ref"))
                elif not (repo / path).exists():
                    bad.append((page_name, href,
                                f"not in the repository: {path}"))
                elif tracked and path not in tracked:
                    bad.append((page_name, href,
                                f"not tracked by git: {path}"))
                continue
            if href.startswith(("http://", "https://", "mailto:", "#",
                                "data:", "javascript:", "/")):
                continue
            path_part = urllib.parse.unquote(href.split("#")[0].split("?")[0])
            if not path_part:
                continue
            target = (page.parent / path_part).resolve()
            try:
                rel = target.relative_to(book)
            except ValueError:
                bad.append((page.relative_to(book).as_posix(), href,
                            "climbs above book/ (the published site 404s)"))
                continue
            if not target.exists():
                bad.append((page.relative_to(book).as_posix(), href,
                            f"no such file: {rel}"))

    check_next_paragraphs(repo / "src", bad)

    for page, href, why in bad:
        print(f"{page}: {href}  -- {why}")
    if bad:
        print(f"\n{len(bad)} link(s) will not work")
        return 1
    print(f"all links resolve ({pages} pages checked)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
