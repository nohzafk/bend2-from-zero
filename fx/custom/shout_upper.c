Term shout_upper_run(Env e, Term* f, IoWork* w) {
  uint64_t n = 0;
  char* s = io_cstr(e, f[0], &n);
  for (uint64_t i = 0; i < n; i++) {
    if (s[i] >= 'a' && s[i] <= 'z') { s[i] = s[i] - 32; }
  }
  Term t = io_str(e, s, n);
  free(s);
  return t;
}

static void __attribute__((constructor)) shout_upper_use(void) {
  io_eff(CID_SHOUT_UPPER, shout_upper_run, 0);
}
