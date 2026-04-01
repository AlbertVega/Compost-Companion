#ifndef HAL_WIFI_H
#define HAL_WIFI_H

#include <Arduino.h>
#include <WiFi.h>

void wifi_init();
bool wifi_connect(const char* ssid, const char* password);
bool wifi_is_connected();
void wifi_disconnect();
String wifi_get_ip();
String wifi_get_mac();
int wifi_scan_networks(String results[], int max_results);

#endif