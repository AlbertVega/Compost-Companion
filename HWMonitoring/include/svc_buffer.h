#pragma once
#include "types.h"
#include <stdint.h>

#define RTC_BUF_CAP 48

void svc_buffer_init_once();
void svc_buffer_push(const Measurement& m);
uint16_t svc_buffer_count();
uint16_t svc_buffer_peek(Measurement* out, uint16_t max_n);
void svc_buffer_pop(uint16_t n);