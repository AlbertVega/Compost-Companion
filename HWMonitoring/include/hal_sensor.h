#pragma once
#include <stdbool.h>
#include "types.h"

bool hal_sensor_init();
bool hal_sensor_read(Measurement* out);