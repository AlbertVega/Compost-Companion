#include <Arduino.h>
#include "esp_attr.h"
#include "esp_sleep.h"

#include "hal_wifi.h"
#include "types.h"
#include "hal_sensor.h"
#include "svc_buffer.h"
#include "svc_rules.h"
#include "comms_http.h"
#include "svc_storage.h"
#include "svc_provisioning.h"

static const char* DEVICE_ID = "compost_01";

static const uint32_t SAMPLE_INTERVAL_S = 20;
static const uint32_t SEND_INTERVAL_S   = 30;
static const uint16_t BATCH_MAX_SEND    = 2;

static const float TEMP_HI = 70.0;
static const float TEMP_LO = 5.0;
static const float RH_HI   = 75.0;
static const float RH_LO   = 35.0;

static const char* BASE_URL = "http://192.168.1.10:8001";
//static const char* BASE_URL = "http://192.168.18.2:8001";
//static const char* BASE_URL = "http://20.186.57.186:8001";
static const int PILE_ID = 1;
static int g_pile_id = 1;
static const char* BLE_DEVICE_NAME = "CompostMonitor";

// rtc persistent
RTC_DATA_ATTR static uint32_t g_seq = 0;
RTC_DATA_ATTR static uint32_t g_t_logical_s = 0;
RTC_DATA_ATTR static uint32_t g_last_send_s = 0;

enum SystemState {
  STATE_PROVISIONING,
  STATE_NORMAL_OPERATION
};

static SystemState g_state = STATE_PROVISIONING;
static bool g_mode_initialized = false;

static void go_to_sleep(uint32_t seconds) {
  wifi_disconnect();
  Serial.printf("Going to deep sleep for %u s\n", (unsigned)seconds);
  Serial.flush();
  esp_sleep_enable_timer_wakeup((uint64_t)seconds * 1000000ULL);
  esp_deep_sleep_start();
}

static bool connect_saved_wifi() {
  String ssid, password;

  if (!storage_load_wifi_credentials(ssid, password)) {
    Serial.println("[MAIN] No saved WiFi credentials");
    return false;
  }

  Serial.println("[MAIN] Found saved WiFi credentials");
  Serial.print("[MAIN] SSID: ");
  Serial.println(ssid);

  bool ok = wifi_connect(ssid.c_str(), password.c_str());

  if (ok) {
    Serial.println("[MAIN] WiFi connected using saved credentials");
  } else {
    Serial.println("[MAIN] Failed to connect with saved credentials");
  }

  return ok;
}

static void init_normal_mode() {
  if (g_mode_initialized) return;

  Serial.println("[MAIN] Initializing normal operation mode...");

  svc_buffer_init_once();
  hal_sensor_init();
  //comms_begin(BASE_URL, PILE_ID);
  g_pile_id = storage_load_pile_id();

  Serial.print("[MAIN] Using pile_id: ");
  Serial.println(g_pile_id);

  comms_begin(BASE_URL, g_pile_id);
  //
  g_mode_initialized = true;
}

static void run_normal_cycle() {
  g_seq++;
  g_t_logical_s += SAMPLE_INTERVAL_S;

  // read sensor
  Measurement m{};
  if (!hal_sensor_read(&m)) {
    Serial.println("Sensor read failed");
    go_to_sleep(SAMPLE_INTERVAL_S);
    return;
  }

  m.seq = g_seq;
  m.t_logical_s = g_t_logical_s;

  // validate
  if (!svc_validate(m.temp_c, m.rh) || (m.flags & 0x01)) {
    Serial.println("Invalid measurement: store + alert invalid");
    m.flags |= 0x01;
    svc_buffer_push(m);

    if (wifi_is_connected()) {
      comms_post_single(DEVICE_ID, m, ALERT_SENSOR_INVALID);
    } else {
      Serial.println("WiFi not connected, cannot send alert");
    }

    go_to_sleep(SAMPLE_INTERVAL_S);
    return;
  }

  // alert check
  AlertType alert = svc_alert(m.temp_c, m.rh, TEMP_HI, TEMP_LO, RH_HI, RH_LO);

  // store always
  svc_buffer_push(m);

  // immediate send if alert
  if (alert != ALERT_NONE) {
    Serial.println("ALERT: immediate send");

    if (wifi_is_connected()) {
      comms_post_single(DEVICE_ID, m, alert);
    } else {
      Serial.println("WiFi not connected, cannot send alert");
    }

    go_to_sleep(SAMPLE_INTERVAL_S);
    return;
  }

  Serial.printf("logical=%u last_send=%u buf=%u\n",
                (unsigned)g_t_logical_s,
                (unsigned)g_last_send_s,
                (unsigned)svc_buffer_count());

  bool shouldSend = svc_should_send(g_t_logical_s,
                                    g_last_send_s,
                                    SEND_INTERVAL_S,
                                    svc_buffer_count(),
                                    RTC_BUF_CAP);

  Serial.printf("shouldSend = %s\n", shouldSend ? "true" : "false");

  if (shouldSend) {
    Serial.println("Batch condition met");

    Measurement batch[BATCH_MAX_SEND];
    uint16_t n = svc_buffer_peek(batch, BATCH_MAX_SEND);

    Serial.printf("Peeked %u measurements for batch\n", (unsigned)n);

    bool ok = false;
    if (wifi_is_connected()) {
      ok = (n > 0) ? comms_post_batch(DEVICE_ID, batch, n) : true;
      Serial.printf("comms_post_batch result = %s\n", ok ? "OK" : "FAIL");
    } else {
      Serial.println("WiFi not connected, cannot send batch");
    }

    if (ok && n > 0) {
      svc_buffer_pop(n);
      g_last_send_s = g_t_logical_s;
      Serial.printf("Batch sent, popped %u\n", (unsigned)n);
    }
  }

  Serial.printf("buf=%u | seq=%u\n",
                (unsigned)svc_buffer_count(),
                (unsigned)g_seq);

  go_to_sleep(SAMPLE_INTERVAL_S);
}

void setup() {
  Serial.begin(115200);
  delay(3000); //aumentar delay para que de tiempo a abrir monitor serial
  Serial.println("\nHWMonitoring");

  storage_init();
  //storage_clear_wifi_credentials(); ///////////////ATTENTION
  wifi_init();

  if (connect_saved_wifi()) {
    g_state = STATE_NORMAL_OPERATION;
  } else {
    Serial.println("[MAIN] Entering BLE provisioning mode...");
    provisioning_init(BLE_DEVICE_NAME);
    g_state = STATE_PROVISIONING;
  }
}

void loop() {
  switch (g_state) {
    case STATE_PROVISIONING:
      provisioning_poll();

      if (provisioning_is_complete()) {
        Serial.println("[MAIN] Provisioning completed");

        provisioning_stop();

        g_state = STATE_NORMAL_OPERATION;
        g_mode_initialized = false;

        // inicializar modo normal inmediatamente
        init_normal_mode();

        // ejecutar un ciclo normal apenas termine provisioning
        run_normal_cycle();
      }
      break;

    case STATE_NORMAL_OPERATION:
      init_normal_mode();
      run_normal_cycle();
      break;
  }

  delay(50);
}