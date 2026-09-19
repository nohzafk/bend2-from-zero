# drift — re-run every claim in this repo

The book is written against **Bend 2.0.5**; the machine runs whatever
`bend update` last installed. This directory answers "what moved?": it runs
every probe and measurement the book makes a claim about, with the current
bend, and writes a report.

- `manifest.py` — the checks: one entry per probe / measurement, plus the
  claim (the book's text, or the current source's behaviour).
- `run_drift.py` — executes them, compares, writes
  `reports/drift-<version>.{md,json}`.

```sh
python3 tools/drift/run_drift.py                 # everything (~5 min)
python3 tools/drift/run_drift.py --only probes-bad,probes-ok,proofs
python3 tools/drift/run_drift.py --only bench --quick
python3 tools/drift/run_drift.py --label 2.0.17  # name the report yourself
```

The `.json` keeps every run's raw stdout/stderr/rc/timing (first runs
included); the `.md` is the human report: verdict per check, the book-vs-now
column, and the full output of anything failing.

Discipline, from the book's own appendix — the harness encodes it so no one
has to remember it:

- **compiled builds for anything timed.** `bend file.bend` is a different,
  slower execution path (the JS interpreter); run mode is for correctness
  only.
- **the first run of a fresh binary is discarded** as cold — it pays ~0.35 s
  that later runs do not.
- **load average and machine state are recorded with the numbers** — a
  parallel speedup varies with the machine's state.
