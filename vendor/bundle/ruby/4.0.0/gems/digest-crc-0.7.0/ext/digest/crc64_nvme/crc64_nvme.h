#ifndef _CRC64_NVME_H_
#define _CRC64_NVME_H_

#include "../crc64/crc64.h"

crc64_t crc64_nvme_update(crc64_t crc, const void *data, size_t data_len);

#endif
