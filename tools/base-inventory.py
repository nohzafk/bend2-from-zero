#!/usr/bin/env python3
"""Measure Base -- and check this repo's inventory tables against it.

`src/appendix-base-gaps.md` opens with a measurement of `base.bend`: its size,
its `law` declarations, its namespaces.  Bend moves, and Base moves with it, so
those numbers can go stale without anything else noticing -- they are prose, and
`tools/drift/run_drift.py` measures probes, not text.

This tool takes the same measurement and, with `--check`, compares it against
the numbers written in the appendix.  Exit code 1 means the book and the
installed Base disagree.

    python3 tools/base-inventory.py                       # print the measurement
    python3 tools/base-inventory.py --check               # compare with the book
    python3 tools/base-inventory.py --base /path/base.bend

The count that matters most is `law, propositions`:  a `law` is a proposition
when the claim it declares is an equation, and a type family when the claim is a
type.  Counting the former is how this tool found that the appendix's "Base has
zero lemmas" was measuring the wrong thing -- it greps for proofs written
`def x(a) -> {..}:`, and Base writes its own as `def x(a):`, with no return type,
because the law supplies it.
"""

import argparse
import os
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
APPENDIX = REPO / "src" / "appendix-base-gaps.md"

# The rows of the appendix's inventory table, in the order it prints them, then
# the type-kind rows it states in prose.  --check insists on every one: a row
# that got renamed must be a failure, not a silently skipped comparison.
PRINT_KEYS = (
    "lines",
    "def",
    "def, terms",
    "type",
    "law",
    "law, propositions",
    "law, propositions proven",
    "namespaces",
)
ROW_KEYS = PRINT_KEYS + ("type, is Data", "type, is Type", "type, is Kind")


def find_base(explicit):
    if explicit:
        return Path(explicit)
    for root in (os.environ.get("BEND_HOME"), Path.home() / ".bend"):
        if root:
            cand = Path(root) / "bend2" / "base.bend"
            if cand.exists():
                return cand
    return None


def law_bodies(lines):
    """Yield (name, body) for every `law name:` declaration."""
    for i, line in enumerate(lines):
        m = re.match(r"^law ([A-Za-z0-9_.]+):$", line)
        if not m:
            continue
        body = []
        for nxt in lines[i + 1 :]:
            if nxt.startswith("law ") or nxt.startswith("def "):
                break
            body.append(nxt)
        yield m.group(1), body


def measure(text):
    lines = text.splitlines()
    laws = list(law_bodies(lines))
    props = [n for n, b in laws if any("{" in x and "==" in x for x in b)]
    proven = [n for n in props if re.search(r"^def %s\(" % re.escape(n), text, re.M)]

    ns = {}
    for line in lines:
        m = re.match(r"^def ([A-Za-z0-9_]+)\.", line)
        if m:
            ns[m.group(1)] = ns.get(m.group(1), 0) + 1

    defs = sum(1 for x in lines if x.startswith("def "))
    kinds = {
        k: sum(1 for x in lines if re.match(r"^type .* is %s" % k, x))
        for k in ("Data", "Type", "Kind")
    }
    return {
        "lines": len(lines),
        "def": defs,
        "def, terms": sum(1 for x in lines if re.match(r"^def [A-Za-z0-9_]+\.", x)),
        "type": sum(1 for x in lines if x.startswith("type ")),
        "law": len(laws),
        "law, propositions": len(props),
        "law, propositions proven": len(proven),
        "namespaces": len(ns),
        "type, is Data": kinds["Data"],
        "type, is Type": kinds["Type"],
        "type, is Kind": kinds["Kind"],
        "propositions": props,
        "namespaces by size": sorted(ns.items(), key=lambda kv: (-kv[1], kv[0])),
    }


ROW_KEYS = (
    "lines",
    "def",
    "def, terms",
    "type",
    "law",
    "law, propositions",
    "namespaces",
    "type, is Data",
    "type, is Type",
    "type, is Kind",
)


def _cell(text):
    return text.replace("`", "").replace("*", "").strip()


def parse_book(text):
    """The appendix's numbers, read back out of its two tables."""
    rows, grid = {}, {}
    for line in text.splitlines():
        if not line.startswith("|"):
            continue
        cells = [_cell(c) for c in line.strip().strip("|").split("|")]
        if len(cells) == 2 and re.fullmatch(r"[\d,]+", cells[1]):
            rows[cells[0]] = int(cells[1].replace(",", ""))
        for name, value in re.findall(r"`([A-Za-z0-9_]+)`\s+([\d,]+)", line):
            grid[name] = int(value.replace(",", ""))
    # The kind breakdown is stated in prose, not in a table:
    # "The 22 types break down as **13 `is Data`**, **3 `is Type`** ..."
    for kind in ("Data", "Type", "Kind"):
        found = re.search(r"\*\*(\d+) `is %s`\*\*" % kind, text)
        if found:
            rows["type, is %s" % kind] = int(found.group(1))
    return rows, grid


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--base", help="path to base.bend (default: $BEND_HOME, ~/.bend)")
    ap.add_argument("--check", action="store_true", help="compare with the appendix")
    ap.add_argument("--appendix", default=str(APPENDIX))
    args = ap.parse_args()

    base = find_base(args.base)
    if not base or not base.exists():
        sys.exit("no base.bend at %s -- pass --base, or set BEND_HOME" % (base or "-"))
    m = measure(base.read_text())

    print("%s\n" % base)
    for key in PRINT_KEYS:
        print("  %-28s %6d" % (key, m[key]))
    print(
        "  %-28s %s"
        % (
            "type kinds",
            " ".join(
                "%s %d" % (k, m["type, is %s" % k]) for k in ("Data", "Type", "Kind")
            ),
        )
    )
    print(
        "\n  namespaces, by size: %s"
        % ", ".join("%s %d" % kv for kv in m["namespaces by size"])
    )
    print(
        "\n  the %d proposition laws, %d with a proof:"
        % (len(m["propositions"]), m["law, propositions proven"])
    )
    for name in m["propositions"]:
        print("    %s" % name)

    if not args.check:
        return

    book_rows, book_grid = parse_book(Path(args.appendix).read_text())
    bad = []
    for key in ROW_KEYS:
        if key not in book_rows:
            bad.append("row %r is missing from the appendix" % key)
        elif book_rows[key] != m[key]:
            bad.append(
                "%s: book says %d, base.bend has %d" % (key, book_rows[key], m[key])
            )
    for name, value in book_grid.items():
        if (
            name in dict(m["namespaces by size"])
            and dict(m["namespaces by size"])[name] != value
        ):
            bad.append(
                "namespace %s: book says %d, base.bend has %d"
                % (name, value, dict(m["namespaces by size"])[name])
            )
    shown = set(book_grid)
    smallest = min(book_grid.values()) if book_grid else 0
    for name, value in m["namespaces by size"]:
        if value > smallest and name not in shown:
            bad.append(
                "namespace %s (%d defs) is larger than one in the table but absent"
                % (name, value)
            )

    print(
        "\n%s"
        % (
            "the appendix disagrees with base.bend:"
            if bad
            else "the appendix's tables match base.bend"
        )
    )
    for line in bad:
        print("  - %s" % line)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
