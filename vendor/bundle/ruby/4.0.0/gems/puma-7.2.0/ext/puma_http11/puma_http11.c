/**
 * Copyright (c) 2005 Zed A. Shaw
 * You can redistribute it and/or modify it under the same terms as Ruby.
 * License 3-clause BSD
 */

#define RSTRING_NOT_MODIFIED 1

#include "ruby.h"
#include "ruby/encoding.h"
#include <assert.h>
#include <string.h>
#include <ctype.h>
#include "http11_parser.h"

#define ARRAY_SIZE(x) (sizeof(x)/sizeof(x[0]))

static VALUE eHttpParserError;

#define HTTP_PREFIX "HTTP_"
#define HTTP_PREFIX_LEN (sizeof(HTTP_PREFIX) - 1)

static VALUE global_request_method;
static VALUE global_request_uri;
static VALUE global_fragment;
static VALUE global_query_string;
static VALUE global_server_protocol;
static VALUE global_request_path;

/** Defines common length and error messages for input length validation. */
#define QUOTE(s) #s
#define EXPAND_MAX_LENGTH_VALUE(s) QUOTE(s)
#define DEF_MAX_LENGTH(N,length) const size_t MAX_##N##_LENGTH = length; const char *MAX_##N##_LENGTH_ERR = "HTTP element " # N  " is longer than the " EXPAND_MAX_LENGTH_VALUE(length) " allowed length (was %d)"

/** Validates the max length of given input and throws an HttpParserError exception if over. */
#define VALIDATE_MAX_LENGTH(len, N) if(len > MAX_##N##_LENGTH) { rb_raise(eHttpParserError, MAX_##N##_LENGTH_ERR, len); }

/** Defines global strings in the init method. */
static inline void DEF_GLOBAL(VALUE *var, const char *cstr)
{
  rb_global_variable(var);
  *var = rb_enc_interned_str_cstr(cstr, rb_utf8_encoding());
}

/* Defines the maximum allowed lengths for various input elements.*/
#ifndef PUMA_REQUEST_URI_MAX_LENGTH
#define PUMA_REQUEST_URI_MAX_LENGTH (1024 * 12)
#endif

#ifndef PUMA_REQUEST_PATH_MAX_LENGTH
#define PUMA_REQUEST_PATH_MAX_LENGTH (8192)
#endif

#ifndef PUMA_QUERY_STRING_MAX_LENGTH
#define PUMA_QUERY_STRING_MAX_LENGTH (1024 * 10)
#endif

DEF_MAX_LENGTH(FIELD_NAME, 256);
DEF_MAX_LENGTH(FIELD_VALUE, 80 * 1024);
DEF_MAX_LENGTH(REQUEST_URI, PUMA_REQUEST_URI_MAX_LENGTH);
DEF_MAX_LENGTH(FRAGMENT, 1024); /* Don't know if this length is specified somewhere or not */
DEF_MAX_LENGTH(REQUEST_PATH, PUMA_REQUEST_PATH_MAX_LENGTH);
DEF_MAX_LENGTH(QUERY_STRING, PUMA_QUERY_STRING_MAX_LENGTH);
DEF_MAX_LENGTH(HEADER, (1024 * (80 + 32)));

struct common_field {
  const size_t len;
  const char *name;
  int raw;
  VALUE value;
};

/*
 * A list of common HTTP headers we expect to receive.
 * This allows us to avoid repeatedly creating identical string
 * objects to be used with rb_hash_aset().
 */
static struct common_field common_http_fields[] = {
# define f(N) { (sizeof(N) - 1), N, 0, Qnil }
# define fr(N) { (sizeof(N) - 1), N, 1, Qnil }
  f("ACCEPT"),
  f("ACCEPT_CHARSET"),
  f("ACCEPT_ENCODING"),
  f("ACCEPT_LANGUAGE"),
  f("ALLOW"),
  f("AUTHORIZATION"),
  f("CACHE_CONTROL"),
  f("CONNECTION"),
  f("CONTENT_ENCODING"),
  fr("CONTENT_LENGTH"),
  fr("CONTENT_TYPE"),
  f("COOKIE"),
  f("DATE"),
  f("EXPECT"),
  f("FROM"),
  f("HOST"),
  f("IF_MATCH"),
  f("IF_MODIFIED_SINCE"),
  f("IF_NONE_MATCH"),
  f("IF_RANGE"),
  f("IF_UNMODIFIED_SINCE"),
  f("KEEP_ALIVE"), /* Firefox sends this */
  f("MAX_FORWARDS"),
  f("PRAGMA"),
  f("PROXY_AUTHORIZATION"),
  f("RANGE"),
  f("REFERER"),
  f("TE"),
  f("TRAILER"),
  f("TRANSFER_ENCODING"),
  f("UPGRADE"),
  f("USER_AGENT"),
  f("VIA"),
  f("X_FORWARDED_FOR"), /* common for proxies */
  f("X_REAL_IP"), /* common for proxies */
  f("WARNING")
# undef f
};

static void init_common_fields(void)
{
  unsigned i;
  struct common_field *cf = common_http_fields;
  char tmp[256]; /* MAX_FIELD_NAME_LENGTH */
  memcpy(tmp, HTTP_PREFIX, HTTP_PREFIX_LEN);

  for(i = 0; i < ARRAY_SIZE(common_http_fields); cf++, i++) {
    rb_global_variable(&cf->value);
    if(cf->raw) {
      cf->value = rb_enc_interned_str(cf->name, cf->len, rb_utf8_encoding());
    } else {
      memcpy(tmp + HTTP_PREFIX_LEN, cf->name, cf->len + 1);
      cf->value = rb_enc_interned_str(tmp, HTTP_PREFIX_LEN + cf->len, rb_utf8_encoding());
    }
  }
}

static VALUE find_common_field_value(const char *field, size_t flen)
{
  unsigned i;
  struct common_field *cf = common_http_fields;
  for(i = 0; i < ARRAY_SIZE(common_http_fields); i++, cf++) {
    if (cf->len == flen && !memcmp(cf->name, field, flen))
      return cf->value;
  }
  return Qnil;
}

static int is_ows(const char c) {
    return c == ' ' || c == '\t';
}

static void http_field(puma_parser* hp, const char *field, size_t flen,
                                 const char *value, size_t vlen)
{
  VALUE f = Qnil;
  VALUE v;

  VALIDATE_MAX_LENGTH(flen, FIELD_NAME);
  VALIDATE_MAX_LENGTH(vlen, FIELD_VALUE);

  f = find_common_field_value(field, flen);

  if (f == Qnil) {
    /*
     * We got a strange header that we don't have a memoized value for.
     * Fallback to creating a new string to use as a hash key.
     */

    size_t new_size = HTTP_PREFIX_LEN + flen;
    assert(new_size < BUFFER_LEN);

    memcpy(hp->buf, HTTP_PREFIX, HTTP_PREFIX_LEN);
    memcpy(hp->buf + HTTP_PREFIX_LEN, field, flen);

    f = rb_enc_interned_str(hp->buf, new_size, rb_utf8_encoding());
  }

  while (vlen > 0 && is_ows(value[vlen - 1])) vlen--;
  while (vlen > 0 && is_ows(value[0])) {
      vlen--;
      value++;
  }

  /* check for duplicate header */
  v = rb_hash_aref(hp->request, f);

  if (v == Qnil) {
      v = rb_str_new(value, vlen);
      rb_hash_aset(hp->request, f, v);
  } else {
      /* if duplicate header, normalize to comma-separated values */
      rb_str_cat2(v, ", ");
      rb_str_cat(v, value, vlen);
  }
}

static void request_method(puma_parser* hp, const char *at, size_t length)
{
  VALUE val = Qnil;

  val = rb_str_new(at, length);
  rb_hash_aset(hp->request, global_request_method, val);
}

static void request_uri(puma_parser* hp, const char *at, size_t length)
{
  VALUE val = Qnil;

  VALIDATE_MAX_LENGTH(length, REQUEST_URI);

  val = rb_str_new(at, length);
  rb_hash_aset(hp->request, global_request_uri, val);
}

static void fragment(puma_parser* hp, const char *at, size_t length)
{
  VALUE val = Qnil;

  VALIDATE_MAX_LENGTH(length, FRAGMENT);

  val = rb_str_new(at, length);
  rb_hash_aset(hp->request, global_fragment, val);
}

static void request_path(puma_parser* hp, const char *at, size_t length)
{
  VALUE val = Qnil;

  VALIDATE_MAX_LENGTH(length, REQUEST_PATH);

  val = rb_str_new(at, length);
  rb_hash_aset(hp->request, global_request_path, val);
}

static void query_string(puma_parser* hp, const char *at, size_t length)
{
  VALUE val = Qnil;

  VALIDATE_MAX_LENGTH(length, QUERY_STRING);

  val = rb_str_new(at, length);
  rb_hash_aset(hp->request, global_query_string, val);
}

static void server_protocol(puma_parser* hp, const char *at, size_t length)
{
  VALUE val = rb_str_new(at, length);
  rb_hash_aset(hp->request, global_server_protocol, val);
}

/** Finalizes the request header to have a bunch of stuff that's
  needed. */

static void header_done(puma_parser* hp, const char *at, size_t length)
{
  hp->body = rb_str_new(at, length);
}


static void HttpParser_mark(void *ptr) {
  puma_parser *hp = ptr;
  rb_gc_mark_movable(hp->request);
  rb_gc_mark_movable(hp->body);
}

static size_t HttpParser_size(const void *ptr) {
  return sizeof(puma_parser);
}

static void HttpParser_compact(void *ptr) {
  puma_parser *hp = ptr;
  hp->request = rb_gc_location(hp->request);
  hp->body = rb_gc_location(hp->body);
}

static const rb_data_type_t HttpParser_data_type = {
    .wrap_struct_name = "Puma::HttpParser",
    .function = {
      .dmark = HttpParser_mark,
      .dfree = RUBY_TYPED_DEFAULT_FREE,
      .dsize = HttpParser_size,
      .dcompact = HttpParser_compact,
    },
    .flags = RUBY_TYPED_FREE_IMMEDIATELY,
};

static VALUE HttpParser_alloc(VALUE klass)
{
  puma_parser *hp = ALLOC_N(puma_parser, 1);
  hp->http_field = http_field;
  hp->request_method = request_method;
  hp->request_uri = request_uri;
  hp->fragment = fragment;
  hp->request_path = request_path;
  hp->query_string = query_string;
  hp->server_protocol = server_protocol;
  hp->header_done = header_done;
  hp->request = Qnil;

  puma_parser_init(hp);

  return TypedData_Wrap_Struct(klass, &HttpParser_data_type, hp);
}

static inline puma_parser *HttpParser_unwrap(VALUE self)
{
  puma_parser *http;
  TypedData_Get_Struct(self, puma_parser, &HttpParser_data_type, http);
  if (http == NULL) {
    rb_raise(rb_eArgError, "%s", "NULL http_parser found");
  }
  return http;
}

/**
 * call-seq:
 *    parser.new -> parser
 *
 * Creates a new parser.
 */
static VALUE HttpParser_init(VALUE self)
{
  puma_parser *http = HttpParser_unwrap(self);
  puma_parser_init(http);

  return self;
}


/**
 * call-seq:
 *    parser.reset -> nil
 *
 * Resets the parser to it's initial state so that you can reuse it
 * rather than making new ones.
 */
static VALUE HttpParser_reset(VALUE self)
{
  puma_parser *http = HttpParser_unwrap(self);
  puma_parser_init(http);

  return Qnil;
}


/**
 * call-seq:
 *    parser.finish -> true/false
 *
 * Finishes a parser early which could put in a "good" or bad state.
 * You should call reset after finish it or bad things will happen.
 */
static VALUE HttpParser_finish(VALUE self)
{
  puma_parser *http = HttpParser_unwrap(self);
  puma_parser_finish(http);

  return puma_parser_is_finished(http) ? Qtrue : Qfalse;
}


/**
 * call-seq:
 *    parser.execute(req_hash, data, start) -> Integer
 *
 * Takes a Hash and a String of data, parses the String of data filling in the Hash
 * returning an Integer to indicate how much of the data has been read.  No matter
 * what the return value, you should call HttpParser#finished? and HttpParser#error?
 * to figure out if it's done parsing or there was an error.
 *
 * This function now throws an exception when there is a parsing error.  This makes
 * the logic for working with the parser much easier.  You can still test for an
 * error, but now you need to wrap the parser with an exception handling block.
 *
 * The third argument allows for parsing a partial request and then continuing
 * the parsing from that position.  It needs all of the original data as well
 * so you have to append to the data buffer as you read.
 */
static VALUE HttpParser_execute(VALUE self, VALUE req_hash, VALUE data, VALUE start)
{
  puma_parser *http = HttpParser_unwrap(self);
  int from = 0;
  char *dptr = NULL;
  long dlen = 0;

  from = FIX2INT(start);
  RSTRING_GETMEM(data, dptr, dlen);

  if(from >= dlen) {
    rb_raise(eHttpParserError, "%s", "Requested start is after data buffer end.");
  } else {
    http->request = req_hash;
    puma_parser_execute(http, dptr, dlen, from);

    VALIDATE_MAX_LENGTH(puma_parser_nread(http), HEADER);

    if(puma_parser_has_error(http)) {
      rb_raise(eHttpParserError, "%s", "Invalid HTTP format, parsing fails. Are you trying to open an SSL connection to a non-SSL Puma?");
    } else {
      return INT2FIX(puma_parser_nread(http));
    }
  }
}



/**
 * call-seq:
 *    parser.error? -> true/false
 *
 * Tells you whether the parser is in an error state.
 */
static VALUE HttpParser_has_error(VALUE self)
{
  puma_parser *http = HttpParser_unwrap(self);

  return puma_parser_has_error(http) ? Qtrue : Qfalse;
}


/**
 * call-seq:
 *    parser.finished? -> true/false
 *
 * Tells you whether the parser is finished or not and in a good state.
 */
static VALUE HttpParser_is_finished(VALUE self)
{
  puma_parser *http = HttpParser_unwrap(self);

  return puma_parser_is_finished(http) ? Qtrue : Qfalse;
}


/**
 * call-seq:
 *    parser.nread -> Integer
 *
 * Returns the amount of data processed so far during this processing cycle.  It is
 * set to 0 on initialize or reset calls and is incremented each time execute is called.
 */
static VALUE HttpParser_nread(VALUE self)
{
  puma_parser *http = HttpParser_unwrap(self);

  return INT2FIX(http->nread);
}

/**
 * call-seq:
 *    parser.body -> nil or String
 *
 * If the request included a body, returns it.
 */
static VALUE HttpParser_body(VALUE self) {
  puma_parser *http = HttpParser_unwrap(self);

  return http->body;
}

#ifdef HAVE_OPENSSL_BIO_H
void Init_mini_ssl(VALUE mod);
#endif

RUBY_FUNC_EXPORTED void Init_puma_http11(void)
{
#ifdef HAVE_RB_EXT_RACTOR_SAFE
  rb_ext_ractor_safe(true);
#endif

  VALUE mPuma = rb_define_module("Puma");
  VALUE cHttpParser = rb_define_class_under(mPuma, "HttpParser", rb_cObject);

  DEF_GLOBAL(&global_request_method, "REQUEST_METHOD");
  DEF_GLOBAL(&global_request_uri, "REQUEST_URI");
  DEF_GLOBAL(&global_fragment, "FRAGMENT");
  DEF_GLOBAL(&global_query_string, "QUERY_STRING");
  DEF_GLOBAL(&global_server_protocol, "SERVER_PROTOCOL");
  DEF_GLOBAL(&global_request_path, "REQUEST_PATH");

  rb_global_variable(&eHttpParserError);
  eHttpParserError = rb_define_class_under(mPuma, "HttpParserError", rb_eStandardError);

  rb_define_alloc_func(cHttpParser, HttpParser_alloc);
  rb_define_method(cHttpParser, "initialize", HttpParser_init, 0);
  rb_define_method(cHttpParser, "reset", HttpParser_reset, 0);
  rb_define_method(cHttpParser, "finish", HttpParser_finish, 0);
  rb_define_method(cHttpParser, "execute", HttpParser_execute, 3);
  rb_define_method(cHttpParser, "error?", HttpParser_has_error, 0);
  rb_define_method(cHttpParser, "finished?", HttpParser_is_finished, 0);
  rb_define_method(cHttpParser, "nread", HttpParser_nread, 0);
  rb_define_method(cHttpParser, "body", HttpParser_body, 0);
  init_common_fields();

#ifdef HAVE_OPENSSL_BIO_H
  Init_mini_ssl(mPuma);
#endif
}
