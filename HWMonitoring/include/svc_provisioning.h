#ifndef SVC_PROVISIONING_H
#define SVC_PROVISIONING_H

#include <Arduino.h>

void provisioning_init(const char* ble_name);
void provisioning_poll();
bool provisioning_is_complete();
void provisioning_stop();


#endif