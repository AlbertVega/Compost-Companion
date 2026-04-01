#ifndef HAL_BLE_H
#define HAL_BLE_H

#include <Arduino.h>

void ble_init(const char* device_name);
void ble_poll();
bool ble_is_connected();

bool ble_has_message();
String ble_get_message();
void ble_clear_message();

void ble_send_message(const String& msg);
void ble_stop();

#endif