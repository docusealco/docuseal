// NTT (Number Theoretic Transform) implementation for BigDecimal multiplication

#define NTT_PRIMITIVE_ROOT 17
#define NTT_PRIME_BASE1 24
#define NTT_PRIME_BASE2 26
#define NTT_PRIME_BASE3 29
#define NTT_PRIME_SHIFT 27
#define NTT_PRIME1 (((uint32_t)NTT_PRIME_BASE1 << NTT_PRIME_SHIFT) | 1)
#define NTT_PRIME2 (((uint32_t)NTT_PRIME_BASE2 << NTT_PRIME_SHIFT) | 1)
#define NTT_PRIME3 (((uint32_t)NTT_PRIME_BASE3 << NTT_PRIME_SHIFT) | 1)
#define MAX_NTT32_BITS 27
#define NTT_DECDIG_BASE 1000000000

// Calculates base**ex % mod
static uint32_t
mod_pow(uint32_t base, uint32_t ex, uint32_t mod) {
    uint32_t res = 1;
    uint32_t bit = 1;
    while (true) {
        if (ex & bit) {
            ex ^= bit;
            res = ((uint64_t)res * base) % mod;
        }
        if (!ex) break;
        base = ((uint64_t)base * base) % mod;
        bit <<= 1;
    }
    return res;
}

// Recursively performs butterfly operations of NTT
static void
ntt_recursive(int size_bits, uint32_t *input, uint32_t *output, uint32_t *tmp, int depth, uint32_t r, uint32_t prime) {
    if (depth > 0) {
        ntt_recursive(size_bits, input, tmp, output, depth - 1, ((uint64_t)r * r) % prime, prime);
    } else {
        tmp = input;
    }
    uint32_t size_half = (uint32_t)1 << (size_bits - 1);
    uint32_t stride = (uint32_t)1 << (size_bits - depth - 1);
    uint32_t n = size_half / stride;
    uint32_t rn = 1, rm = prime - 1;
    for (uint32_t i = 0; i < n; i++) {
        uint32_t *aptr = tmp + i * 2 * stride;
        uint32_t *bptr = aptr + stride;
        uint32_t *out1 = output + stride * i;
        uint32_t *out2 = out1 + size_half;
        for (uint32_t k = 0; k < stride; k++) {
            uint32_t a = aptr[k], b = bptr[k];
            out1[k] = (a + (uint64_t)rn * b) % prime;
            out2[k] = (a + (uint64_t)rm * b) % prime;
        }
        rn = ((uint64_t)rn * r) % prime;
        rm = ((uint64_t)rm * r) % prime;
    }
}

/* Perform NTT on input array.
 * base, shift: Represent the prime number as (base << shift | 1)
 * r_base: Primitive root of unity modulo prime
 * size_bits: log2 of the size of the input array. Should be less or equal to shift
 * input: input array of size (1 << size_bits)
 */
static void
ntt(int size_bits, uint32_t *input, uint32_t *output, uint32_t *tmp, int r_base, int base, int shift, int dir) {
    uint32_t size = (uint32_t)1 << size_bits;
    uint32_t prime = ((uint32_t)base << shift) | 1;

    // rmax**(1 << shift) % prime == 1
    // r**size % prime == 1
    uint32_t rmax = mod_pow(r_base, base, prime);
    uint32_t r = mod_pow(rmax, (uint32_t)1 << (shift - size_bits), prime);

    if (dir < 0) r = mod_pow(r, prime - 2, prime);
    ntt_recursive(size_bits, input, output, tmp, size_bits - 1, r, prime);
    if (dir < 0) {
        uint32_t n_inv = mod_pow((uint32_t)size, prime - 2, prime);
        for (uint32_t i = 0; i < size; i++) {
            output[i] = ((uint64_t)output[i] * n_inv) % prime;
        }
    }
}

/* Calculate c that satisfies: c % PRIME1 == mod1 && c % PRIME2 == mod2 && c % PRIME3 == mod3
 * c = (mod1 * 35002755423056150739595925972 + mod2 * 14584479687667766215746868453 + mod3 * 37919651490985126265126719818) % (PRIME1 * PRIME2 * PRIME3)
 * Assume c <= 999999999**2*(1<<27)
 */
static inline void
mod_restore_prime_24_26_29_shift_27(uint32_t mod1, uint32_t mod2, uint32_t mod3, uint32_t *digits) {
    // Use mixed radix notation to eliminate modulo by PRIME1 * PRIME2 * PRIME3
    // [DIG0, DIG1, DIG2] = DIG0 + DIG1 * PRIME1 + DIG2 * PRIME1 * PRIME2
    // DIG0: 0...PRIME1, DIG1: 0...PRIME2, DIG2: 0...PRIME3
    // 35002755423056150739595925972 = [1, 3489660916, 3113851359]
    // 14584479687667766215746868453 = [0, 13, 1297437912]
    // 37919651490985126265126719818 = [0, 0, 3373338954]
    uint64_t c0 = mod1;
    uint64_t c1 = (uint64_t)mod2 * 13 + (uint64_t)mod1 * 3489660916;
    uint64_t c2 = (uint64_t)mod3 * 3373338954 % NTT_PRIME3 + (uint64_t)mod2 * 1297437912 % NTT_PRIME3 + (uint64_t)mod1 * 3113851359 % NTT_PRIME3;
    c2 += c1 / NTT_PRIME2;
    c1 %= NTT_PRIME2;
    c2 %= NTT_PRIME3;
    // Base conversion. c fits in 3 digits.
    c1 += c2 % NTT_DECDIG_BASE * NTT_PRIME2;
    c0 += c1 % NTT_DECDIG_BASE * NTT_PRIME1;
    c1 /= NTT_DECDIG_BASE;
    digits[0] = c0 % NTT_DECDIG_BASE;
    c0 /= NTT_DECDIG_BASE;
    c1 += c2 / NTT_DECDIG_BASE % NTT_DECDIG_BASE * NTT_PRIME2;
    c0 += c1 % NTT_DECDIG_BASE * NTT_PRIME1;
    c1 /= NTT_DECDIG_BASE;
    digits[1] = c0 % NTT_DECDIG_BASE;
    digits[2] = (uint32_t)(c0 / NTT_DECDIG_BASE + c1 % NTT_DECDIG_BASE * NTT_PRIME1);
}

/*
 * NTT multiplication
 * Uses three NTTs with mod (24 << 27 | 1), (26 << 27 | 1), and (29 << 27 | 1)
 */
static void
ntt_multiply(size_t a_size, size_t b_size, uint32_t *a, uint32_t *b, uint32_t *c) {
    if (a_size < b_size) {
      ntt_multiply(b_size, a_size, b, a, c);
      return;
    }

    int ntt_size_bits = bit_length(b_size - 1) + 1;
    if (ntt_size_bits > MAX_NTT32_BITS) {
      rb_raise(rb_eArgError, "Multiply size too large");
    }

    // To calculate large_a * small_b faster, split into several batches.
    uint32_t ntt_size = (uint32_t)1 << ntt_size_bits;
    uint32_t batch_size = ntt_size - (uint32_t)b_size;
    uint32_t batch_count = (uint32_t)((a_size + batch_size - 1) / batch_size);

    uint32_t *mem = ruby_xcalloc(sizeof(uint32_t), ntt_size * 9);
    uint32_t *ntt1 = mem;
    uint32_t *ntt2 = mem + ntt_size;
    uint32_t *ntt3 = mem + ntt_size * 2;
    uint32_t *tmp1 = mem + ntt_size * 3;
    uint32_t *tmp2 = mem + ntt_size * 4;
    uint32_t *tmp3 = mem + ntt_size * 5;
    uint32_t *conv1 = mem + ntt_size * 6;
    uint32_t *conv2 = mem + ntt_size * 7;
    uint32_t *conv3 = mem + ntt_size * 8;

    // Calculate NTT for b in three primes. Result is reused for each batch of a.
    memcpy(tmp1, b, b_size * sizeof(uint32_t));
    memset(tmp1 + b_size, 0, (ntt_size - b_size) * sizeof(uint32_t));
    ntt(ntt_size_bits, tmp1, ntt1, tmp2, NTT_PRIMITIVE_ROOT, NTT_PRIME_BASE1, NTT_PRIME_SHIFT, +1);
    ntt(ntt_size_bits, tmp1, ntt2, tmp2, NTT_PRIMITIVE_ROOT, NTT_PRIME_BASE2, NTT_PRIME_SHIFT, +1);
    ntt(ntt_size_bits, tmp1, ntt3, tmp2, NTT_PRIMITIVE_ROOT, NTT_PRIME_BASE3, NTT_PRIME_SHIFT, +1);

    memset(c, 0, (a_size + b_size) * sizeof(uint32_t));
    for (uint32_t idx = 0; idx < batch_count; idx++) {
        uint32_t len = idx == batch_count - 1 ? (uint32_t)a_size - idx * batch_size : batch_size;
        memcpy(tmp1, a + idx * batch_size, len * sizeof(uint32_t));
        memset(tmp1 + len, 0, (ntt_size - len) * sizeof(uint32_t));
        // Calculate convolution for this batch in three primes
        ntt(ntt_size_bits, tmp1, tmp2, tmp3, NTT_PRIMITIVE_ROOT, NTT_PRIME_BASE1, NTT_PRIME_SHIFT, +1);
        for (uint32_t i = 0; i < ntt_size; i++) tmp2[i] = ((uint64_t)tmp2[i] * ntt1[i]) % NTT_PRIME1;
        ntt(ntt_size_bits, tmp2, conv1, tmp3, NTT_PRIMITIVE_ROOT, NTT_PRIME_BASE1, NTT_PRIME_SHIFT, -1);
        ntt(ntt_size_bits, tmp1, tmp2, tmp3, NTT_PRIMITIVE_ROOT, NTT_PRIME_BASE2, NTT_PRIME_SHIFT, +1);
        for (uint32_t i = 0; i < ntt_size; i++) tmp2[i] = ((uint64_t)tmp2[i] * ntt2[i]) % NTT_PRIME2;
        ntt(ntt_size_bits, tmp2, conv2, tmp3, NTT_PRIMITIVE_ROOT, NTT_PRIME_BASE2, NTT_PRIME_SHIFT, -1);
        ntt(ntt_size_bits, tmp1, tmp2, tmp3, NTT_PRIMITIVE_ROOT, NTT_PRIME_BASE3, NTT_PRIME_SHIFT, +1);
        for (uint32_t i = 0; i < ntt_size; i++) tmp2[i] = ((uint64_t)tmp2[i] * ntt3[i]) % NTT_PRIME3;
        ntt(ntt_size_bits, tmp2, conv3, tmp3, NTT_PRIMITIVE_ROOT, NTT_PRIME_BASE3, NTT_PRIME_SHIFT, -1);

        // Restore the original convolution value from three convolutions calculated in three primes.
        // Each convolution value is maximum 999999999**2*(1<<27)/2
        for (uint32_t i = 0; i < ntt_size; i++) {
            uint32_t dig[3];
            mod_restore_prime_24_26_29_shift_27(conv1[i], conv2[i], conv3[i], dig);
            // Maximum values of dig[0], dig[1], and dig[2] are 999999999, 999999999 and 67108863 respectively
            // Maximum overlapped sum (considering overlaps between 2 batches) is less than 4134217722
            // so this sum doesn't overflow uint32_t.
            for (int j = 0; j < 3; j++) {
                // Index check: if dig[j] is non-zero, assign index is within valid range.
                if (dig[j]) c[idx * batch_size + i + 1 - j] += dig[j];
            }
        }
    }
    uint32_t carry = 0;
    for (int32_t i = (uint32_t)(a_size + b_size - 1); i >= 0; i--) {
        uint32_t v = c[i] + carry;
        c[i] = v % NTT_DECDIG_BASE;
        carry = v / NTT_DECDIG_BASE;
    }
    ruby_xfree(mem);
}
