#ifndef TRILOGY_PACKET_PARSER_H
#define TRILOGY_PACKET_PARSER_H

#include <stddef.h>
#include <stdint.h>

// Data between client and server is exchanged in packets of max 16MByte size.
#define TRILOGY_MAX_PACKET_LEN 0xffffff

typedef struct {
    int (*on_packet_begin)(void *);
    int (*on_packet_data)(void *, const uint8_t *, size_t);
    int (*on_packet_end)(void *);
} trilogy_packet_parser_callbacks_t;

typedef struct {
    void *user_data;
    const trilogy_packet_parser_callbacks_t *callbacks;

    uint8_t sequence_number;

    // private:
    unsigned bytes_remaining : 24;

    unsigned state : 3;
    unsigned fragment : 1;
    unsigned deferred_end_callback : 1;
} trilogy_packet_parser_t;

void trilogy_packet_parser_init(trilogy_packet_parser_t *parser, const trilogy_packet_parser_callbacks_t *callbacks);

size_t trilogy_packet_parser_execute(trilogy_packet_parser_t *parser, const uint8_t *buf, size_t len, int *error);

#endif
