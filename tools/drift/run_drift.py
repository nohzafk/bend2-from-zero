#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""run_drift.py — run every claim in manifest.py and report drift.

Usage (on the Mac, from the repo root or anywhere):

    python3 tools/drift/run_drift.py                 # everything
    python3 tools/drift/run_drift.py --only bench    # one group
    python3 tools/drift/run_drift.py --quick         # 1 run per bench check
    python3 tools/drift/run_drift.py --bend ~/.bend/bin/bend --label 2.0.16

Writes drift-<label>.json (machine-readable, full outputs) and
drift-<label>.md (human report) into tools/drift/reports/.

Discipline encoded here (see the book's appendix-measurements.md):
  * compiled builds only for anything timed; `bend file.bend` is a
    different (slower) execution path and is used for correctness only;
  * the first run of a fresh binary is discarded as cold (it pays ~0.35 s
    that later runs do not);
  * every run is recorded, not just the summary — a drift report is only
    useful if the raw output is in it.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from manifest import CHECKS  # noqa: E402


# --------------------------------------------------------------------------
# small helpers

def sh(cmd, cwd, env, timeout):
    """Run a command; return dict with rc/out/err/secs/timeout."""
    t0 = time.monotonic()
    try:
        p = subprocess.run(cmd, cwd=cwd, env=env, capture_output=True,
                           timeout=timeout)
        return dict(rc=p.returncode,
                    out=p.stdout.decode("utf-8", "replace"),
                    err=p.stderr.decode("utf-8", "replace"),
                    secs=round(time.monotonic() - t0, 3), timeout=False)
    except subprocess.TimeoutExpired as e:
        out = e.stdout or b""
        err = e.stderr or b""
        if isinstance(out, str):
            out = out.encode()
        if isinstance(err, str):
            err = err.encode()
        return dict(rc=None, out=out.decode("utf-8", "replace"),
                    err=err.decode("utf-8", "replace"),
                    secs=round(time.monotonic() - t0, 3), timeout=True)


def sysctl(key):
    try:
        return subprocess.run(["sysctl", "-n", key], capture_output=True,
                              text=True, timeout=10).stdout.strip()
    except Exception:
        return "?"


def git(repo, *args):
    try:
        p = subprocess.run(["git", "-C", str(repo), *args],
                           capture_output=True, text=True, timeout=20)
        return p.stdout.strip()
    except Exception:
        return ""


def loadavg():
    try:
        a = os.getloadavg()
        return "/".join(f"{x:.2f}" for x in a)
    except Exception:
        return "?"


# --------------------------------------------------------------------------
# one check

def build_base(check):
    """Stable per-(dir,file) name for build artifacts (no thread suffix:
    one build serves every thread configuration, as in the book)."""
    return (check["dir"] + "_" + check["file"]).replace("/", "_").replace(".bend", "")


def run_check(check, bend, repo, scratch, env, cache):
    """Execute one manifest entry.  Builds are cached by (mode, dir, file)."""
    mode = check["mode"]
    timeout = check.get("timeout_s", 120)
    runs = check.get("runs") or (3 if check["group"] == "bench" else 1)
    cwd = Path(repo) / check["dir"]
    result = dict(check=check, runs=[], compile=None, problems=[])

    if mode == "run":
        for _ in range(runs):
            result["runs"].append(
                sh([str(bend), check["file"]] + check["args"], cwd, env, timeout))
        return result

    if mode == "script":
        scr = Path(repo) / check["dir"] / check["file"]
        for _ in range(runs):
            result["runs"].append(sh(["sh", str(scr)], Path(repo), env, timeout))
        return result

    sdir = Path(scratch)
    sdir.mkdir(parents=True, exist_ok=True)
    key = (mode, check["dir"], check["file"])
    base = build_base(check)
    got = cache.get(key)
    if got is None:
        if mode == "compile":
            target = str(sdir / base)
            comp = sh([str(bend), check["file"], "-o", target], cwd, env, 600)
            result["compile"] = comp
            if comp["rc"] != 0 or comp["timeout"]:
                result["problems"].append("compile failed")
                cache[key] = False
                return result
            got = target
        elif mode == "c_cpu":
            csrc = str(sdir / (base + ".c"))
            comp = sh([str(bend), check["file"], "-o", csrc], cwd, env, 600)
            result["compile"] = comp
            if comp["rc"] != 0 or comp["timeout"]:
                result["problems"].append("emit-c failed")
                cache[key] = False
                return result
            binary = str(sdir / (base + "_cpu"))
            cc = sh(["clang", "-O2", csrc, "-o", binary, "-lm"], sdir, env, 600)
            result["clang"] = cc
            if cc["rc"] != 0:
                result["problems"].append("clang failed")
                cache[key] = False
                return result
            got = binary
        else:
            raise ValueError(f"unknown mode {mode!r}")
        cache[key] = got
    if got is False:
        result["problems"].append("build previously failed")
        return result
    cmd = [got] + check["args"]
    for _ in range(runs):
        result["runs"].append(sh(cmd, sdir, env, timeout))
    return result


def verdict(check, result):
    """Check the recorded runs against the manifest claims.  Mutates nothing."""
    problems = list(result["problems"])
    runs = result["runs"]
    if not runs:
        return problems or ["no runs recorded"]
    # correctness checks use the LAST run (earlier ones may be cold)
    last = runs[-1]
    rc_want = check.get("expect_rc", 0)
    if rc_want == "timeout":
        if not last["timeout"]:
            problems.append("expected still running at timeout, but exited")
    elif rc_want == "nonzero":
        if last["timeout"]:
            problems.append("timed out; expected a normal failure")
        elif last["rc"] == 0:
            problems.append("expected nonzero rc, got 0")
    else:
        if last["timeout"]:
            problems.append("timed out")
        elif last["rc"] != rc_want:
            problems.append(f"rc={last['rc']} (want {rc_want})")
    for s in check.get("expect_out") or []:
        if s not in last["out"]:
            problems.append(f"stdout missing {s!r}")
    for s in check.get("expect_err") or []:
        if s not in last["err"]:
            problems.append(f"stderr missing {s!r}")
    if check.get("expect_err_exact_empty") and last["err"].strip():
        problems.append(f"stderr not empty: {last['err'].strip()[:120]!r}")
    return problems


# --------------------------------------------------------------------------
# report

def fmt_secs(x):
    return f"{x:.2f}s" if x is not None else "?"


def summarize_runs(check, result):
    runs = result["runs"]
    if not runs:
        return "", ""
    secs = [r["secs"] for r in runs]
    if check["group"] == "bench" and len(secs) > 1:
        cold = secs[0]
        settled = min(secs[1:])
        warm = [f"{s:.2f}" for s in secs[1:]]
        text = f"settled {settled:.2f}s (runs after first: {' / '.join(warm)})"
        if cold > settled * 1.3:
            text += f"; first run {cold:.2f}s (cold) "
        return text, f"{settled:.3f}"
    return " / ".join(f"{s:.2f}s" for s in secs), f"{min(secs):.3f}"


def write_reports(meta, results, outdir, label):
    outdir = Path(outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    # ---- JSON: everything, verbatim
    jdoc = dict(meta=meta, results=[])
    for r in results:
        jdoc["results"].append(dict(
            name=r["check"]["name"],
            group=r["check"]["group"],
            mode=r["check"]["mode"],
            dir=r["check"]["dir"],
            file=r["check"]["file"],
            problems=r["problems"],
            compile=r["compile"],
            runs=r["runs"],
        ))
    jpath = outdir / f"drift-{label}.json"
    jpath.write_text(json.dumps(jdoc, indent=1, ensure_ascii=False) + "\n")

    # ---- Markdown
    L = []
    L.append(f"# Drift report — bend {meta['bend_version']} ({label})\n")
    L.append(f"- date: {meta['date']}")
    L.append(f"- machine: {meta['cpu']}, {meta['cores']} cores "
             f"({meta['perf_cores']} performance), macOS {meta['macos']}")
    L.append(f"- bend binary: `{meta['bend_path']}` sha256 `{meta['bend_sha'][:16]}…`")
    L.append(f"- repo: `{meta['repo']}` at `{meta['commit']}`"
             + (f" (dirty: {meta['dirty']} files)" if meta['dirty'] else " (clean)"))
    L.append(f"- load average at start/end: {meta['load_start']} / {meta['load_end']}")
    L.append(f"- caffeinate running: {meta['caffeinate']}")
    L.append("")
    L.append("Verdict is against **manifest.py** (the recorded claim); the "
             "`book` column is what the 2.0.5-written book says, for context.\n")

    for group in ["probes-bad", "probes-ok", "proofs", "hub", "gate", "fx", "bench"]:
        rows = [r for r in results if r["check"]["group"] == group]
        if not rows:
            continue
        L.append(f"## {group}\n")
        if group == "bench":
            L.append("| check | book (2.0.5) | now | verdict |")
            L.append("|---|---|---|---|")
            for r in rows:
                c = r["check"]
                timing, _ = summarize_runs(c, r)
                v = "OK" if not r["problems"] else "**FAIL**: " + "; ".join(r["problems"])
                L.append(f"| {c['name']} | {c['book']} | {timing} | {v} |")
        else:
            L.append("| check | book (2.0.5) | now | verdict |")
            L.append("|---|---|---|---|")
            for r in rows:
                c = r["check"]
                last = r["runs"][-1] if r["runs"] else None
                if last is None:
                    now = "(compile problem)"
                elif last["timeout"]:
                    now = f"still running at {c.get('timeout_s')}s"
                else:
                    first = (last["out"].strip().splitlines() or [""])[0][:90]
                    first = first or (last["err"].strip().splitlines() or [""])[0][:90]
                    now = f"`{first}`"
                v = "OK" if not r["problems"] else "**FAIL**: " + "; ".join(r["problems"])
                L.append(f"| {c['name']} | {c['book']} | {now} | {v} |")
        L.append("")

    # raw numbers: bench stdout, so the report carries the actual lines the
    # book's tables quote (ms per configuration, checksums).
    bench_rows = [r for r in results if r["check"]["group"] == "bench"]
    have_out = [r for r in bench_rows if r["runs"] and r["runs"][-1]["out"].strip()]
    if have_out:
        L.append("## bench raw stdout (last run of each)\n")
        L.append("```")
        for r in have_out:
            L.append(f"-- {r['check']['name']} --")
            L.append(r["runs"][-1]["out"].strip())
        L.append("```")
        L.append("")

    # notes / drift annotations
    notes = [(r["check"]["name"], r["check"]["note"])
             for r in results if r["check"]["note"]]
    if notes:
        L.append("## Annotations\n")
        for name, note in notes:
            L.append(f"- **{name}** — {note}")
        L.append("")

    # raw samples: failures in full (the honest part)
    fails = [r for r in results if r["problems"]]
    if fails:
        L.append("## Raw output of failing checks\n")
        for r in fails:
            c = r["check"]
            L.append(f"### {c['name']}\n")
            L.append("```")
            last = r["runs"][-1] if r["runs"] else {}
            L.append("cmd: " + " ".join([c["mode"], c["dir"] + "/" + c["file"]]
                                        + list(c["args"])))
            L.append(f"rc={last.get('rc')} timeout={last.get('timeout')}")
            L.append("--- stdout ---")
            L.append((last.get("out") or "")[:4000])
            L.append("--- stderr ---")
            L.append((last.get("err") or "")[:4000])
            L.append("```")
            L.append("")

    mpath = outdir / f"drift-{label}.md"
    text = "\n".join(L) + "\n"
    # esc_bad's stdout contains a real NUL byte; written raw, git calls the
    # report binary.  Escape NULs before writing.
    mpath.write_text(text.replace("\x00", "\\0"))
    return jpath, mpath


# --------------------------------------------------------------------------
# main

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bend", default=str(Path.home() / ".bend/bin/bend"))
    ap.add_argument("--repo", default=str(HERE.parent.parent))
    ap.add_argument("--out", default=str(HERE / "reports"))
    ap.add_argument("--scratch", default=str(Path.home() / "drift-bend2/build"))
    ap.add_argument("--only", default=None, help="comma-separated groups")
    ap.add_argument("--skip", default=None, help="comma-separated groups")
    ap.add_argument("--quick", action="store_true", help="1 run per check")
    ap.add_argument("--label", default=None)
    args = ap.parse_args()

    bend = Path(args.bend).expanduser().resolve()
    repo = Path(args.repo).resolve()
    if not bend.exists():
        sys.exit(f"no bend binary at {bend}")

    env = dict(os.environ, BEND_NO_TELEMETRY="1")
    env["BEND"] = str(bend)
    ver_out = sh([str(bend), "--version"], repo, env, 30)
    m = re.search(r"bend (\S+)", ver_out["out"] + ver_out["err"])
    version = m.group(1) if m else "unknown"
    label = args.label or version

    import hashlib
    sha = hashlib.sha256(bend.read_bytes()).hexdigest()

    meta = dict(
        date=datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
        bend_version=version,
        bend_path=str(bend),
        bend_sha=sha,
        machine=socket_hostname(),
        cpu=sysctl("machdep.cpu.brand_string"),
        cores=sysctl("hw.ncpu"),
        perf_cores=sysctl("hw.perflevel0.logicalcpu"),
        macos=subprocess.run(["sw_vers", "-productVersion"], capture_output=True,
                             text=True).stdout.strip(),
        repo=str(repo),
        commit=git(repo, "rev-parse", "--short", "HEAD"),
        dirty=len([x for x in git(repo, "status", "--porcelain").splitlines() if x]),
        load_start=loadavg(),
        caffeinate="yes" if subprocess.run(
            ["pgrep", "caffeinate"], capture_output=True).returncode == 0 else "no",
    )

    checks = CHECKS
    if args.only:
        keep = set(args.only.split(","))
        checks = [c for c in checks if c["group"] in keep]
    if args.skip:
        drop = set(args.skip.split(","))
        checks = [c for c in checks if c["group"] not in drop]
    if args.quick:
        for c in checks:
            if c["group"] == "bench":
                c["runs"] = 1

    print(f"bend {version} @ {bend}")
    print(f"repo {repo} at {meta['commit']}")
    print(f"{len(checks)} checks; scratch {args.scratch}")
    t0 = time.monotonic()
    results = []
    cache = {}
    for i, c in enumerate(checks, 1):
        t = time.monotonic()
        r = run_check(c, bend, repo, args.scratch, env, cache)
        r["problems"] = verdict(c, r)
        results.append(r)
        status = "ok" if not r["problems"] else "FAIL"
        print(f"[{i:2}/{len(checks)}] {c['name']:<28} {status:>4}  "
              f"({time.monotonic()-t:.1f}s)", flush=True)
        if r["problems"]:
            for p in r["problems"]:
                print(f"        - {p}")
    meta["load_end"] = loadavg()
    meta["elapsed_s"] = round(time.monotonic() - t0, 1)

    jpath, mpath = write_reports(meta, results, args.out, label)
    nfail = sum(1 for r in results if r["problems"])
    print(f"\n{nfail}/{len(results)} failing; wrote {jpath} and {mpath}")
    return 0


def socket_hostname():
    import socket
    try:
        return socket.gethostname()
    except Exception:
        return "?"


if __name__ == "__main__":
    sys.exit(main())
