#include "ruby.h"
#include "extconf.h"

#include "crc64_nvme.h"

VALUE Digest_CRC64NVMe_update(VALUE self, VALUE data)
{
	VALUE crc_ivar_name = rb_intern("@crc");
	VALUE crc_ivar = rb_ivar_get(self, crc_ivar_name);
	crc64_t crc = NUM2ULONG(crc_ivar);

	const char *data_ptr = StringValuePtr(data);
	size_t length = RSTRING_LEN(data);

	crc = crc64_nvme_update(crc,data_ptr,length);

	rb_ivar_set(self, crc_ivar_name, ULONG2NUM(crc));
	return self;
}

void Init_crc64_nvme_ext()
{
	VALUE mDigest = rb_const_get(rb_cObject, rb_intern("Digest"));
	VALUE cCRC64NVMe = rb_const_get(mDigest, rb_intern("CRC64NVMe"));

	#ifdef HAVE_RB_EXT_RACTOR_SAFE
		rb_ext_ractor_safe(true);
	#endif

	rb_define_method(cCRC64NVMe, "update", Digest_CRC64NVMe_update, 1);
}
