Term str_repeat2_run(Env e, Term* f, IoWork* w) {
  uint64_t n = 0;
  char* s = io_cstr(e, f[0], &n);
  uint32_t k = (uint32_t)f[1];
  uint64_t total = n * (uint64_t)k;
  char* r = malloc(total + 1);
  for (uint32_t i = 0; i < k; i++) {
    memcpy(r + (uint64_t)i * n, s, n);
  }
  r[total] = 0;
  Term t = io_str(e, r, total);
  free(r);
  free(s);
  return t;
}

static void __attribute__((constructor)) str_repeat2_use(void) {
  io_eff(CID_STR_REPEAT2, str_repeat2_run, 0);
}
