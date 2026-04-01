#include "svc_buffer.h"
#include "esp_attr.h"

RTC_DATA_ATTR static Measurement rb[RTC_BUF_CAP];
RTC_DATA_ATTR static uint16_t rb_head = 0;
RTC_DATA_ATTR static uint16_t rb_count = 0;
RTC_DATA_ATTR static bool rb_inited = false;

void svc_buffer_init_once() {
  if (rb_inited) return;
  rb_head = 0; rb_count = 0; rb_inited = true;
}

void svc_buffer_push(const Measurement& m) {
  uint16_t idx = (rb_head + rb_count) % RTC_BUF_CAP;
  rb[idx] = m;
  if (rb_count < RTC_BUF_CAP) rb_count++;
  else rb_head = (rb_head + 1) % RTC_BUF_CAP;
}

uint16_t svc_buffer_count() { return rb_count; }

uint16_t svc_buffer_peek(Measurement* out, uint16_t max_n) {
  uint16_t n = (rb_count < max_n) ? rb_count : max_n;
  for (uint16_t i = 0; i < n; i++) out[i] = rb[(rb_head + i) % RTC_BUF_CAP];
  return n;
}

void svc_buffer_pop(uint16_t n) {
  if (n > rb_count) n = rb_count;
  rb_head = (rb_head + n) % RTC_BUF_CAP;
  rb_count -= n;
}