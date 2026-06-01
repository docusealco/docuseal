#include <ruby.h>

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#include <time.h>
#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif

#include "SFMT.h"
#include "numo/narray.h"

static u_int64_t random_seed(void) {
  static int n = 0;
  struct timeval tv;

  gettimeofday(&tv, 0);
  return tv.tv_sec ^ tv.tv_usec ^ getpid() ^ n++;
}

static VALUE nary_s_srand(int argc, VALUE* argv, VALUE obj) {
  VALUE vseed;
  u_int64_t seed;

  // rb_secure(4);
  if (rb_scan_args(argc, argv, "01", &vseed) == 0) {
    seed = random_seed();
  } else {
    seed = NUM2UINT64(vseed);
  }
  init_gen_rand((uint32_t)seed);

  return Qnil;
}

void Init_nary_rand(void) {
  /**
   * Sets the seed for random number generator.
   * @overload Numo::NArray.srand(seed)
   *   @param seed [Integer] if seed is not given, a seed is generated from current time,
   *     process id, and a sequence number.
   *   @return [nil]
   */
  rb_define_singleton_method(cNArray, "srand", nary_s_srand, -1);
  init_gen_rand(0);
}
