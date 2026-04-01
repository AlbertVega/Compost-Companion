
#pragma once
#include "types.h"
#include <stdbool.h>
#include <stdint.h>

bool svc_validate(float t, float h);
AlertType svc_alert(float t, float h, float THI, float TLO, float HHI, float HLO);
bool svc_should_send(uint32_t now_s, uint32_t last_send_s, uint32_t send_interval_s,
                     uint16_t buf_count, uint16_t buf_cap);