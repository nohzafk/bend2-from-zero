Term delay_ms_run(Env e, Term* f, IoWork* w) {
  return term_pak(CID_UNIT, 0);
}

static void __attribute__((constructor)) delay_ms_use(void) {
  io_eff(CID_DELAY_MS, delay_ms_run, IO_TIME);
}
