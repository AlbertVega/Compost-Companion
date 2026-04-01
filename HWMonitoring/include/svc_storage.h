#ifndef SVC_STORAGE_H
#define SVC_STORAGE_H

#include <Arduino.h>

void storage_init();

bool storage_has_wifi_credentials();
bool storage_load_wifi_credentials(String& ssid, String& password);
bool storage_save_wifi_credentials(const String& ssid, const String& password);
void storage_clear_wifi_credentials();

#endif