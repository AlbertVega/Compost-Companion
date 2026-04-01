#include <Arduino.h>
#include "hal_sensor.h"
#include <Wire.h>
#include "DFRobot_SHT20.h"
#include <math.h>

#ifdef USE_FAKE_SENSOR

////////// SENSOR SIMULADO NO ELIMINAR ////////////


bool hal_sensor_init() {
  Serial.println("HAL: Using fake sensor");
  return true;
}

bool hal_sensor_read(Measurement* out) {
  if (!out) return false;

  static uint32_t k = 0;
  k++;

  // cada 20 lecturas simula falla
  if (k % 20 == 0) {
    out->flags = 0x01; // invalid
    return true;
  }

  float baseT = 35.0f + 10.0f * sinf(k * 0.15f);
  float baseH = 55.0f + 12.0f * sinf(k * 0.10f);

  float noiseT = ((int)(esp_random() % 100) - 50) / 200.0f;
  float noiseH = ((int)(esp_random() % 100) - 50) / 100.0f;

  out->temp_c = baseT + noiseT;
  out->rh     = baseH + noiseH;
  out->flags  = 0;

  return true;
}

#else


////// SENSOR REAL /////

static DFRobot_SHT20 sht20(&Wire, SHT20_I2C_ADDR);

bool hal_sensor_init() {
  Serial.println("HAL: Using SHT20");
  Wire.begin(6, 7); // SDA=GPIO6, SCL=GPIO7
  sht20.initSHT20();
  delay(50);
  return true;
}

bool hal_sensor_read(Measurement* out) {
  if (!out) return false;

  float h = sht20.readHumidity();
  float t = sht20.readTemperature();

  Serial.printf("SHT20: T=%.2f C | RH=%.2f %%\n", t, h);

  if (t < -40 || t > 125 || h < 0 || h > 100) {
    out->flags = 0x01;
    return true;
  }

  out->temp_c = t;
  out->rh     = h;
  out->flags  = 0;

  return true;
}
#endif