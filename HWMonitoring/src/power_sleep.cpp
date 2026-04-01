#include "power_sleep.h"
#include <Arduino.h>
#include "esp_sleep.h"

void power_sleep_seconds(uint32_t s) {
  esp_sleep_enable_timer_wakeup((uint64_t)s * 1000000ULL);
  Serial.printf("Sleeping %us...\n", s);
  Serial.flush();
  esp_deep_sleep_start();
}