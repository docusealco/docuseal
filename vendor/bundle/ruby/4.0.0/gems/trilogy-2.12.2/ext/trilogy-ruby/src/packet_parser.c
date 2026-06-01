#include "trilogy/packet_parser.h"
#include "trilogy/error.h"

enum {
    S_LEN_0 = 0,
    S_LEN_1 = 1,
    S_LEN_2 = 2,
    S_SEQ = 3,
    S_PAYLOAD = 4,
};

void trilogy_packet_parser_init(trilogy_packet_parser_t *parser, const trilogy_packet_parser_callbacks_t *callbacks)
{
    parser->user_data = NULL;
    parser->callbacks = callbacks;
    parser->state = S_LEN_0;
    parser->fragment = 0;
    parser->deferred_end_callback = 0;
    parser->sequence_number = 0;
}

size_t trilogy_packet_parser_execute(trilogy_packet_parser_t *parser, const uint8_t *buff, size_t len, int *error)
{
    size_t i = 0;

    if (parser->deferred_end_callback) {
        parser->deferred_end_callback = 0;

        int rc = parser->callbacks->on_packet_end(parser->user_data);

        if (rc) {
            *error = rc;
            return 0;
        }
    }

    while (i < len) {
        uint8_t cur_byte = buff[i];

        switch (parser->state) {
        case S_LEN_0: {
            parser->bytes_remaining = cur_byte;
            parser->state = S_LEN_1;

            i++;
            break;
        }
        case S_LEN_1: {
            parser->bytes_remaining |= cur_byte << 8;
            parser->state = S_LEN_2;

            i++;
            break;
        }
        case S_LEN_2: {
            parser->bytes_remaining |= cur_byte << 16;

            int was_fragment = parser->fragment;

            parser->fragment = (parser->bytes_remaining == TRILOGY_MAX_PACKET_LEN);

            parser->state = S_SEQ;
            i++;

            if (!was_fragment) {
                int rc = parser->callbacks->on_packet_begin(parser->user_data);

                if (rc) {
                    *error = rc;
                    return i;
                }
            }

            break;
        }
        case S_SEQ: {
            if (cur_byte != parser->sequence_number && cur_byte > 0) {
                *error = TRILOGY_INVALID_SEQUENCE_ID;
                return i;
            }

            parser->sequence_number++;
            parser->state = S_PAYLOAD;

            i++;

            if (parser->bytes_remaining == 0) {
                goto end_of_payload;
            }

            break;
        }
        case S_PAYLOAD: {
            const uint8_t *ptr = buff + i;
            size_t chunk_length = len - i;

            if (chunk_length > parser->bytes_remaining) {
                chunk_length = parser->bytes_remaining;
            }

            i += chunk_length;
            parser->bytes_remaining -= chunk_length;

            int rc = parser->callbacks->on_packet_data(parser->user_data, ptr, chunk_length);

            if (rc) {
                if (parser->bytes_remaining == 0) {
                    parser->deferred_end_callback = 1;
                }

                *error = rc;
                return i;
            }

            if (parser->bytes_remaining == 0) {
                goto end_of_payload;
            }

            break;
        }
        end_of_payload : {
            parser->state = S_LEN_0;

            if (!parser->fragment) {
                int rc = parser->callbacks->on_packet_end(parser->user_data);

                if (rc) {
                    *error = rc;
                    return i;
                }
            }

            break;
        }
        }
    }

    *error = 0;
    return i;
}
