#include <time.h>

static void busy_ms_call(IoWork* w) {
  struct timespec ts;
  ts.tv_sec = (time_t)(w->word / 1000u);
  ts.tv_nsec = (long)((w->word % 1000u) * 1000000u);
  nanosleep(&ts, NULL);
}

static Term busy_ms_pack(Env e, IoWork* w) {
  return term_pak(CID_UNIT, 0);
}

Term busy_ms_run(Env e, Term* f, IoWork* w) {
  w->word = f[0];
  return io_work(w, busy_ms_call, busy_ms_pack);
}

static void __attribute__((constructor)) busy_ms_use(void) {
  io_eff(CID_BUSY_MS, busy_ms_run, 0);
}
