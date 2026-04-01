#pragma once
#include <stdint.h>

struct Measurement {
  uint32_t seq;
  uint32_t t_logical_s;
  float temp_c;
  float rh;
  int16_t rssi;
  uint8_t flags;
};

enum AlertType : uint8_t {
  ALERT_NONE = 0,
  ALERT_TEMP_HIGH,
  ALERT_TEMP_LOW,
  ALERT_RH_HIGH,
  ALERT_RH_LOW,
  ALERT_SENSOR_INVALID
};