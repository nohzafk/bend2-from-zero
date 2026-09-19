# -*- coding: utf-8 -*-
"""Drift manifest for bend2-from-zero.

Every entry is a file in this repo that the book makes a claim about, plus the
claim.  run_drift.py runs each one with the current `bend` and compares.

Fields
------
name        unique key, used in reports ("group/file" usually)
group       probes-bad | probes-ok | proofs | bench
dir         directory relative to the repo root
file        file name inside dir
mode        "run"     = `bend FILE` (checker; runs main if there is one)
            "compile" = `bend FILE -o SCRATCH/NAME`, then run the binary
            "c_cpu"   = `bend FILE -o SCRATCH/NAME.c`, clang -O2 NAME.c -lm
  args      arguments for the compiled binary (compile/c_cpu modes)
  runs      how many times to run (default 1; bench entries default 3)
  expect_out  substrings that must appear in stdout; None = record only
  expect_err  substrings that must appear in stderr; None = record only
  expect_rc   0 | "nonzero" | "timeout"   (default 0)
  timeout_s   per-run timeout
  book        the book's quoted result, for the report's book-vs-now column
  source      "book" (quoted in the book) | "source" (read from code/docs
              of the current version) | "measured" (first measured now)
  note        annotation printed in the report
"""


def C(name, group, dir, file, mode, **kw):
    d = dict(name=name, group=group, dir=dir, file=file, mode=mode)
    d.setdefault("args", [])
    d.setdefault("runs", None)
    d.setdefault("expect_out", None)
    d.setdefault("expect_err", None)
    d.setdefault("expect_err_exact_empty", False)
    d.setdefault("expect_rc", 0)
    d.setdefault("timeout_s", 120)
    d.setdefault("book", "")
    d.setdefault("source", "book")
    d.setdefault("note", "")
    d.update(kw)
    return d


CHECKS = [
    # ---------------------------------------------------------------- probes
    # Files that do NOT compile, on purpose.  Book: appendix-probes.md.
    C("basics/hello_bad", "probes-bad", "basics", "hello_bad.bend", "run",
      expect_err=["a declared datatype (unknown: IO)"], expect_rc="nonzero",
      book="a declared datatype (unknown: IO)"),
    C("basics/hello_arg", "probes-bad", "basics", "hello_arg.bend", "run",
      expect_err=["expected : String", "observed : U32"], expect_rc="nonzero",
      book="expected : String / observed : U32"),
    C("basics/term_bad", "probes-bad", "basics", "term_bad.bend", "run",
      expect_err=["decreasing self-call", "observed : loop"], expect_rc="nonzero",
      book="expected : a decreasing self-call / observed : loop"),
    C("basics/term_order", "probes-bad", "basics", "term_order.bend", "run",
      expect_err=["decreasing self-call", "observed : evolve"], expect_rc="nonzero",
      book="expected : a decreasing self-call / observed : evolve"),
    C("affinity/affine_bad", "probes-bad", "affinity", "affine_bad.bend", "run",
      expect_err=["consumed more than once"], expect_rc="nonzero",
      book="expected : x / observed : x (consumed more than once)"),
    C("affinity/t9_listonly", "probes-bad", "affinity", "t9_listonly.bend", "run",
      expect_err=["consumed more than once"], expect_rc="nonzero",
      book="expected : xs / observed : xs (consumed more than once)"),
    C("affinity/t4_arrplus", "probes-bad", "affinity", "t4_arrplus.bend", "run",
      expect_err=["expected : Data", "observed : Type"], expect_rc="nonzero",
      book="expected : Data / observed : Type"),
    C("affinity/t5_closure", "probes-bad", "affinity", "t5_closure.bend", "run",
      expect_err=["consumed more than once"], expect_rc="nonzero",
      book="expected : f / observed : f (consumed more than once)"),
    C("affinity/t6_closureplus", "probes-bad", "affinity", "t6_closureplus.bend", "run",
      expect_err=["expected : Data", "observed : Type"], expect_rc="nonzero",
      book="expected : Data / observed : Type (same error as the array)"),
    C("affinity/t11_templatemiss", "probes-bad", "affinity", "t11_templatemiss.bend", "run",
      expect_err=["consumed more than once"], expect_rc="nonzero",
      book="expected : -f / observed : f (consumed more than once)"),
    C("affinity/t3_arr", "probes-bad", "affinity", "t3_arr.bend", "run",
      expect_err=["cannot scrutinize a local binder"], expect_rc="nonzero",
      book="fails on purpose (error not quoted in the affinity README)",
      source="source", note="error wrapper: 'a parameter or field scrutinee (...)';"
                            " message core matches arrays/a_fail"),
    C("arrays/exp_arr", "probes-bad", "arrays", "exp_arr.bend", "run",
      expect_err=["expected : a term"], expect_rc="nonzero",
      book="expected : a term / observed : ':'"),
    C("arrays/exp_arr2", "probes-bad", "arrays", "exp_arr2.bend", "run",
      expect_err=["cannot scrutinize a computed value"], expect_rc="nonzero",
      book="a match cannot scrutinize a computed value: give it its own def"),
    C("arrays/a_fail", "probes-bad", "arrays", "a_fail.bend", "run",
      expect_err=["cannot scrutinize a local binder"], expect_rc="nonzero",
      book="a match cannot scrutinize a local binder: give it its own def"),
    C("arrays/d_write", "probes-bad", "arrays", "d_write.bend", "run",
      expect_err=["Sigma<&1, &1, Array<U32>", "observed : Array<U32>"], expect_rc="nonzero",
      book="expected : Sigma<&1, &1, Array<U32>, _ => U32> / observed : Array<U32>"),

    # Files that compile and run.  Book: the topic READMEs + chapters.
    C("basics/hello", "probes-ok", "basics", "hello.bend", "run",
      expect_out=["hello, bend 2"], book="hello, bend 2"),
    C("basics/exp_str", "probes-ok", "basics", "exp_str.bend", "run",
      expect_out=["a\nb\ttab"], book="a <newline> b<TAB>tab"),
    C("basics/exp_mod", "probes-ok", "basics", "exp_mod.bend", "run",
      expect_out=["1n"], book="1n (9 mod 4)"),
    C("basics/exp_list", "probes-ok", "basics", "exp_list.bend", "run",
      expect_out=["2"], book="2"),
    C("basics/pat_bad", "probes-ok", "basics", "pat_bad.bend", "run",
      expect_out=["1"], book="prints 1 -- it does not (deceptive on purpose)",
      note="WARNING-probe: compiles and lies by design.  f(2n) should be 2, prints 1."),
    C("basics/esc_bad", "probes-ok", "basics", "esc_bad.bend", "run",
      expect_out=["\x00" "33"],
      book="bytes 00 33 33 (NUL + literal '33') -- not ESC",
      note="WARNING-probe: emits wrong bytes by design.  \\033 is \\0 then '33'."),
    C("affinity/t1_drop", "probes-ok", "affinity", "t1_drop.bend", "run",
      expect_out=["7"], book="7 -- unused is fine, affine != linear"),
    C("affinity/t2_plus", "probes-ok", "affinity", "t2_plus.bend", "run",
      expect_out=["6"], book="6"),
    C("affinity/t7_paths", "probes-ok", "affinity", "t7_paths.bend", "run",
      expect_out=["11"], book="11 -- counted per path, not per occurrence"),
    C("affinity/t8_listplus", "probes-ok", "affinity", "t8_listplus.bend", "run",
      expect_out=["6n"], book="6n"),
    C("affinity/t10_template", "probes-ok", "affinity", "t10_template.bend", "run",
      expect_out=["42"], expect_err=["All terms check, with 1 unsafe annotation."],
      book="42",
      source="source",
      note="A def that is a template instance counts as unsafe (intended,"
           " per the CHANGELOG), so a file with a template prints 'All terms"
           " check, with N unsafe annotations.' on stderr 'until the checker"
           " verifies template expansion itself'.  The template does NOT skip"
           " any check; this is a disclosure, not a soundness hole."),
    C("arrays/b_ok", "probes-ok", "arrays", "b_ok.bend", "run",
      expect_out=["43"], book="43"),
    C("arrays/c_base", "probes-ok", "arrays", "c_base.bend", "run",
      expect_out=["42"], book="42"),
    C("arrays/e_post1", "probes-ok", "arrays", "e_post1.bend", "run",
      expect_out=["([0, 0, 0, 0, 0, 42, 0, 0], 42)"],
      book="([0,0,0,0,0,42,0,0], 42)",
      source="measured",
      note="book README prints it without spaces; the actual normalizer output"
           " has spaces after commas.  Formatting only."),
    C("arrays/f_post3", "probes-ok", "arrays", "f_post3.bend", "run",
      expect_out=["42"], book="42"),
    C("parallel/pow2", "probes-ok", "parallel", "pow2.bend", "run",
      expect_out=["4194304"], book="2^22 (README only)"),
    C("life/life", "probes-ok", "life", "life.bend", "run",
      expect_out=["generation 0"],
      book="8x8 teaching version, prints the pattern every generation",
      source="measured", timeout_s=60),

    # ------------------------------------------------------------- proofs
    C("life/LIFE_PAR_PROOF", "proofs", "life", "LIFE_PAR_PROOF.bend", "run",
      expect_out=["All terms check."], runs=3, timeout_s=60,
      book="All terms check. (0.10 s)"),
    C("life/LIFE_ANIM_PROOF", "proofs", "life", "LIFE_ANIM_PROOF.bend", "run",
      expect_out=["All terms check."], runs=3, timeout_s=60,
      book="All terms check. (0.09 s)"),
    C("life/LIFE_PAR_LAWS", "proofs", "life", "LIFE_PAR_LAWS.bend", "run",
      expect_err=["TODO found"], expect_rc="nonzero", timeout_s=60,
      book="open claim; running it alone is '1 TODO found'"),
    C("life/LIFE_ANIM_LAWS", "proofs", "life", "LIFE_ANIM_LAWS.bend", "run",
      expect_err=["TODO found"], expect_rc="nonzero", timeout_s=60,
      book="open claim; running it alone is '1 TODO found'"),

    # -------------------------------------------------------------- bench
    # Book: appendix-measurements.md and the topic READMEs.  Compiled builds only; first run of a fresh binary
    # is discarded (it is ~0.35 s slower for cold-start reasons, see README).
    C("parallel/pow2_26 @1t", "bench", "parallel", "pow2_26.bend", "compile",
      args=["--threads", "1"], runs=3, expect_out=["67108864"], timeout_s=120,
      book="0.22-0.23 s"),
    C("parallel/pow2_26 @2t", "bench", "parallel", "pow2_26.bend", "compile",
      args=["--threads", "2"], runs=3, expect_out=["67108864"], timeout_s=120,
      book="0.12-0.13 s"),
    C("parallel/pow2_26 @4t", "bench", "parallel", "pow2_26.bend", "compile",
      args=["--threads", "4"], runs=3, expect_out=["67108864"], timeout_s=120,
      book="0.07 s"),
    C("parallel/pow2_26 @8t", "bench", "parallel", "pow2_26.bend", "compile",
      args=["--threads", "8"], runs=3, expect_out=["67108864"], timeout_s=120,
      book="0.04 s"),
    C("parallel/pow2_26 @14t", "bench", "parallel", "pow2_26.bend", "compile",
      args=["--threads", "14"], runs=3, expect_out=["67108864"], timeout_s=120,
      book="0.04-0.05 s"),
    C("gpu/gpu_floor", "bench", "gpu", "gpu_floor.bend", "compile",
      runs=3, expect_out=["4"], expect_err_exact_empty=True, timeout_s=120,
      book="0.08-0.09 s",
      source="source",
      note=".gpu semantics:"
           " `bend -o X` writes X.gpu beside X; a launch LOADS it when present"
           " (silent), and prints 'compiling the GPU program (missing or stale)'"
           " and recompiles only when the file is absent or empty.  A run never"
           " writes the kernel back on Metal -- with X.gpu absent, every run"
           " notes and recompiles (~0.08 s either way; Metal's OS cache feeds"
           " the recompile).  A .gpu from a different program loaded silently"
           " and still computed correctly (the kernel source is embedded in the"
           " host binary).  The papercut of 2026-09-18 described an X.gpu-less"
           " binary, so its 'prints every run' is correct for that setup only."),
    C("gpu/pow2_gpu", "bench", "gpu", "pow2_gpu.bend", "compile",
      runs=3, expect_out=["67108864"], timeout_s=120, book="0.09-0.10 s"),
    C("gpu/gpu_twice", "bench", "gpu", "gpu_twice.bend", "compile",
      runs=3, expect_out=["33554432", "67108864"], timeout_s=120, book="0.09 s"),
    C("gpu/mandelbrot cpu @1t", "bench", "gpu/mandelbrot", "main.bend", "c_cpu",
      args=["--threads", "1"], runs=3, expect_out=["3101455856"], timeout_s=300,
      book="5.10-5.12 s"),
    C("gpu/mandelbrot cpu @10t", "bench", "gpu/mandelbrot", "main.bend", "c_cpu",
      args=["--threads", "10"], runs=3, expect_out=["3101455856"], timeout_s=300,
      book="0.72 s"),
    C("gpu/mandelbrot gpu", "bench", "gpu/mandelbrot", "main.bend", "compile",
      runs=3, expect_out=["3101455856"], timeout_s=300, book="0.10-0.12 s"),
    C("gpu/queens cpu @1t", "bench", "gpu/queens", "main.bend", "c_cpu",
      args=["--threads", "1"], runs=3, expect_out=["2063750025"], timeout_s=300,
      book="6.02-6.19 s"),
    C("gpu/queens cpu @10t", "bench", "gpu/queens", "main.bend", "c_cpu",
      args=["--threads", "10"], runs=3, expect_out=["2063750025"], timeout_s=300,
      book="0.85 s"),
    C("gpu/queens gpu", "bench", "gpu/queens", "main.bend", "compile",
      runs=3, expect_out=["2063750025"], timeout_s=300, book="1.34-1.41 s",
      source="source",
      note="Measured 2026-09-19: ~1.7 s (median) here, above the book's"
           " 1.34-1.41 s.  queens-gpu is the only workload whose GPU compute is"
           " not hidden"
           " under the ~85 ms entry fee (mandelbrot's real work is ~30 ms), so"
           " it is the only one that can show a GPU-state difference; the"
           " difference is environment (GUI/GPU contention), per the book's own"
           " warning to record a parallel number with the machine's state."
           "  See reports/drift-2.0.16-quiet.md."),
    C("life/life_row @1t", "bench", "life", "life_row.bend", "compile",
      args=["--threads", "1"], runs=2, timeout_s=300,
      expect_out=["32x32", "64x64", "128x128", "256x256"],
      book="4 / 17 / 70 / 308 ms (64 generations, ns/cell flat)"),
    C("life/life_par @1t", "bench", "life", "life_par.bend", "compile",
      args=["--threads", "1"], runs=2, timeout_s=300,
      expect_out=["blk=1", "blk=16", "blk=64", "naive, no fork"],
      book="1t: 1795 / 2065 / 2025 ms"),
    C("life/life_par @10t", "bench", "life", "life_par.bend", "compile",
      args=["--threads", "10"], runs=2, timeout_s=300,
      expect_out=["blk=1", "blk=16", "blk=64", "naive, no fork"],
      book="10t: 690 / 684 / 1045 ms"),

    # --------------------------------------------------------------- hub
    # The sources of the packages we publish to the Bend hub (see ../hub).
    # An update that breaks them should be seen here, not by a consumer.
    C("hub/nat.bend", "hub", "hub", "nat.bend", "run",
      expect_out=["All terms check."], timeout_s=60,
      source="measured",
      note="published as 0x1ee1b5d0c2a66817bf368b849f3117fc"),
    C("hub/string.bend", "hub", "hub", "string.bend", "run",
      expect_out=["All terms check."], timeout_s=60,
      source="measured",
      note="published as 0x89df026edd2acf2673b5e469e037eaf1"),
    C("hub/list.bend", "hub", "hub", "list.bend", "run",
      expect_out=["All terms check."], timeout_s=60,
      source="measured",
      note="published as 0x085d89db9ee8a21865e959816bb20e5b"),
    C("hub/example.bend", "hub", "hub", "example.bend", "run",
      expect_out=["All terms check."], timeout_s=60,
      source="measured",
      note="the consumer example; fetches all three packages by hash"),

    # --------------------------------------------------------------- gate
    # The PROOF gate's adversarial matrix (tools/drift/gate_matrix.sh).
    C("gate/matrix", "gate", "tools/drift", "gate_matrix.sh", "script",
      expect_out=[
        "t1_ok rc=0 out=All terms check.",
        "t2_unsafe rc=0 out=All terms check, with 1 unsafe annotation.",
        "t3_todo rc=1 out= err=Error: 1 TODO found.",
        "t4_noimport rc=1 out= err=bend: PROOF.bend must import ./LAWS.bend (see bend --help)",
        "t5_vacuous rc=0 out=All terms check.",
        "t6_nearby_unsafe rc=0 out=All terms check, with 1 unsafe annotation.",
        "t7_straydef rc=1 out= err=Error:",
      ],
      timeout_s=300, source="measured",
      note="T6 phase 0.  t2 pins the effective gate semantics: a FALSE law"
           " 'proven' by @unsafe non-termination passes with rc=0; the only"
           " signal is the degraded stdout line -- deliberate per upstream"
           " #776/#805 (disclosure shipped in 2.0.8, exit code unchanged), so"
           " CI must match `All terms check.` exactly, or forbid @unsafe."
           "  t5: an emptied law set passes.  t6: the unsafe count is"
           " book-wide, not proof-scoped.  t7: a stray proof def after the law"
           " is deleted is a parse error ('expected : ->') -- filed upstream as"
           " a diagnostic-er quality issue."),

    # -------------------------------------------------------------- laws
    # The laws part's smallest examples (src/laws-1.md).
    C("laws/two_plus_two", "probes-ok", "laws", "two_plus_two.bend", "run",
      expect_out=["All terms check."], timeout_s=60, source="measured",
      note="a law with no variables; {==} closes it because both sides"
           " compute"),
    C("laws/add_zero", "probes-ok", "laws", "add_zero.bend", "run",
      expect_out=["All terms check."], timeout_s=60, source="measured",
      note="the first proof with a variable: match + the self-quote + {==}"),
    C("laws/fill_rettype_bad", "probes-bad", "laws", "fill_rettype_bad.bend",
      "run", expect_err=["expected : ':'"], expect_rc="nonzero",
      timeout_s=60, source="measured",
      note="a law's fill may not carry a return type"),
    C("laws/add_zero_bad", "probes-bad", "laws", "add_zero_bad.bend", "run",
      expect_err=["expected : Nat.add(x, 0n)"], expect_rc="nonzero",
      timeout_s=60, source="measured",
      note="the stuck-term refusal: {==} cannot close x + 0 == x"),

    C("laws/use_twice", "probes-ok", "laws", "use_twice.bend", "run",
      expect_out=["All terms check."], timeout_s=60, source="measured",
      note="the quantity marks on the smallest case: +x because the proof"
           " consumes the variable twice"),

    # ---------------------------------------------------------------- fx
    # The effects probes (the fx/ topic directory).  Run mode = the JS lane;
    # entries that need the native lane use compile mode.  Exit codes are
    # exact where certain: deadlock=1, die=7, try/errno=2, refused=61.
    C("fx/io/deadlock", "fx", "fx/io", "deadlock.bend", "run",
      expect_err=["deadlock: every computation waits on a channel"],
      expect_rc=1, timeout_s=60, source="measured",
      note="one computation waits on a channel nobody sends to"),
    C("fx/io/sleep_par", "fx", "fx/io", "sleep_par.bend", "run",
      expect_out=["total ms="], timeout_s=60, source="measured",
      note="two forked 700 ms sleeps finish in ~709 ms (one sleep's time)"),
    C("fx/io/join_reuse_bad", "fx", "fx/io", "join_reuse_bad.bend", "run",
      expect_err=["consumed more than once"], expect_rc=1, timeout_s=60,
      source="measured",
      note="join consumes the channel; a second join does not compile"),
    C("fx/io/join_twice", "fx", "fx/io", "join_twice.bend", "run",
      expect_out=["first join=41"],
      expect_err=["IO.join: the channel was closed"], expect_rc=1,
      timeout_s=60, source="measured",
      note="with +ch it compiles; the second join dies at runtime"),
    C("fx/io/match_in_do_bad", "fx", "fx/io", "match_in_do_bad.bend", "run",
      expect_err=["a match heads a def body"], expect_rc=1, timeout_s=60,
      source="measured",
      note="match cannot live inside a do block; extract it into a def"),
    C("fx/io/close_recv", "fx", "fx/io", "close_recv.bend", "run",
      expect_out=["send=true", "recv=7", "recv=none"], timeout_s=60,
      source="measured",
      note="close then recv answers None"),
    C("fx/io/send_after_close", "fx", "fx/io", "send_after_close.bend", "run",
      expect_out=["send-after-close=false"], timeout_s=60, source="measured",
      note="send on a closed channel answers false, not an error"),
    C("fx/io/orphan_deadlock", "fx", "fx/io", "orphan_deadlock.bend", "run",
      expect_out=["main done"], expect_err=["deadlock"], expect_rc=1,
      timeout_s=60, source="measured",
      note="main returning is not the program ending: a leftover waiting"
           " task turns the whole exit into a deadlock report"),
    C("fx/io/die", "fx", "fx/io", "die.bend", "run",
      expect_out=["before die"], expect_err=["custom failure message"],
      expect_rc=7, timeout_s=60, source="measured",
      note="IO.die: the process exits with your code (7), message on stderr,"
           " later statements do not run"),
    C("fx/io/try_fail", "fx", "fx/io", "try_fail.bend", "run",
      expect_err=["No such file or directory"], expect_rc=2, timeout_s=60,
      source="measured",
      note="IO.try on a failed Result: exit code is the errno (ENOENT=2)"),
    C("fx/io/room_full", "fx", "fx/io", "room_full.bend", "run",
      expect_out=["send=true"], expect_err=["deadlock"], expect_rc=1,
      timeout_s=60, source="measured",
      note="a full room makes send wait (it does not return false); with"
           " nobody receiving, the program reports deadlock"),
    C("fx/io/chan_fifo", "fx", "fx/io", "chan_fifo.bend", "run",
      expect_out=["recv=10", "recv=20", "recv=30", "recv=40"], timeout_s=60,
      source="measured",
      note="room 4: four sends do not block, receives come FIFO"),
    C("fx/io/spawn", "fx", "fx/io", "spawn.bend", "run",
      expect_out=["main done", "spawned ran after 300ms"], timeout_s=60,
      source="measured",
      note="IO.spawn: the program waits for the spawned task (no deadlock)"),
    C("fx/io/args", "fx", "fx/io", "args.bend", "run",
      args=["alpha", "beta", "--", "gamma"],
      expect_out=["argc=3"], timeout_s=60, source="measured",
      note="-- stops bend's own parsing and is not passed to the program"),
    C("fx/custom/clock", "fx", "fx/custom", "clock.bend", "run",
      expect_out=["ms since boot: "], timeout_s=60, source="measured",
      note="the two lanes measure different quantities: native=since boot,"
           " JS=since process start (book material)"),
    C("fx/custom/shout_repeat", "fx", "fx/custom", "shout_repeat.bend", "run",
      expect_out=["HELLO, BEND", "ababababab", "XXX"], timeout_s=60,
      source="measured",
      note="two effects that are not in Base; green in run and native lanes"
           " (and -o x.js + bun, checked by hand)"),
    C("fx/custom/utf8", "fx", "fx/custom", "utf8.bend", "run",
      expect_out=["héllo·世界héllo·世界", "HéLLO, WöRLD"], timeout_s=60,
      source="measured",
      note="UTF-8 through a custom effect: byte-identical in both lanes"),
    C("fx/custom/delay", "fx", "fx/custom", "delay.bend", "run",
      expect_out=["d_builtin=", "d_custom="], timeout_s=60, source="measured",
      note="a custom need (IO_TIME) parks the loop like IO.sleep"),
    C("fx/custom/busy", "fx", "fx/custom", "busy.bend", "compile",
      expect_out=["tick 300", "tick 600", "tick 900", "busy done after"],
      timeout_s=120, source="measured",
      note="io_work runs the blocking call on a helper thread; the loop stays"
           " live (the ticker fires during the 1000 ms of work)"),
    C("fx/custom/misnamed_host", "fx", "fx/custom", "misnamed_host.bend", "run",
      expect_err=["op.run is not a function"], expect_rc=1, timeout_s=60,
      source="measured",
      note="JS host function name wrong: a raw runtime TypeError; the"
           " compiled lane is unaffected (its C file is fine)"),
    C("fx/custom/missing_registration", "fx", "fx/custom",
      "missing_registration.bend", "compile",
      expect_err=["alien request"], expect_rc=1, timeout_s=120,
      source="measured",
      note="C file without its io_eff registration: compiles; native run"
           " dies at first use; the JS lane is unaffected"),
    C("fx/file/roundtrip", "fx", "fx/file", "roundtrip.bend", "run",
      expect_out=["size=11", "read back: hello, file"], timeout_s=60,
      source="measured"),
    C("fx/file/position", "fx", "fx/file", "position.bend", "run",
      expect_out=["chunk: [hello]", "chunk: [, fil]", "at-bytes=4"],
      timeout_s=60, source="measured",
      note="sequential reads advance the position; read_at does not"),
    C("fx/file/open_missing", "fx", "fx/file", "open_missing.bend", "run",
      expect_err=["No such file or directory"], expect_rc=2, timeout_s=60,
      source="measured"),
    C("fx/file/read_after_close_bad", "fx", "fx/file",
      "read_after_close_bad.bend", "run",
      expect_err=["consumed more than once"], expect_rc=1, timeout_s=60,
      source="measured",
      note="handle misuse after close is a compile error (affine)"),
    C("fx/tcp/roundtrip", "fx", "fx/tcp", "roundtrip.bend", "run",
      expect_out=["server got: ping", "client got: pong", "done"],
      timeout_s=90, source="measured"),
    C("fx/tcp/refused", "fx", "fx/tcp", "refused.bend", "run",
      expect_err=["Connection refused"], expect_rc=61, timeout_s=60,
      source="measured",
      note="ECONNREFUSED=61, same in both lanes"),
    C("fx/lane/lazy_checker", "fx", "fx/lane", "lazy_checker.bend", "run",
      expect_out=["7n"], timeout_s=90, source="measured",
      note="WONTFIX #775: run mode skips the dead 200M-step argument"
           " (0.057 s) while the compiled lane pays it (0.18 s)"),
    C("fx/lane/lazy_checker_baseline", "fx", "fx/lane",
      "lazy_checker_baseline.bend", "run",
      expect_out=["7n"], timeout_s=90, source="measured",
      note="same call with spin(0n): the cost reference"),
]
