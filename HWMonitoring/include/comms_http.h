#pragma once
#include <Arduino.h>
#include "types.h"

bool comms_begin(const char* base_url, int pile_id);

bool comms_post_single(const char* device_id,
                       const Measurement& m,
                       AlertType alert);

bool comms_post_batch(const char* device_id,
                      Measurement* batch,
                      uint16_t n);