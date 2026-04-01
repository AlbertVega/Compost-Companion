#include <Arduino.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "comms_http.h"


static String g_base_url = "";
static int g_pile_id = 1;

static String join_url(const String& base, const String& path) {
  String url = base;
  if (url.endsWith("/")) {
    url.remove(url.length() - 1);
  }
  return url + path;
}

static bool post_record(const char* device_id,
                        const Measurement& m,
                        AlertType alert,
                        float nitrogen_content,
                        float carbon_content) {
  HTTPClient http;

  String path = "/test/compost-piles/" + String(g_pile_id) + "/health-records";
  String url = join_url(g_base_url, path);

  Serial.print("[COMMS] POST ");
  Serial.println(url);

  if (!http.begin(url)) {
    Serial.println("[COMMS] HTTP begin failed");
    return false;
  }

  http.addHeader("Content-Type", "application/json");

  JsonDocument doc;
  doc["temperature"] = m.temp_c;
  doc["moisture"] = m.rh;
  doc["nitrogen_content"] = nitrogen_content;
  doc["carbon_content"] = carbon_content;


  doc["device_id"] = device_id;
  doc["flags"] = m.flags;
  doc["alert"] = (int)alert;
  doc["seq"] = m.seq;
  doc["timestamp_s"] = m.t_logical_s;

  String payload;
  serializeJson(doc, payload);

  Serial.println("[COMMS] Payload:");
  Serial.println(payload);

  int http_code = http.POST(payload);

  Serial.print("[COMMS] HTTP code: ");
  Serial.println(http_code);

  if (http_code <= 0) {
    Serial.print("[COMMS] POST failed: ");
    Serial.println(http.errorToString(http_code));
    http.end();
    return false;
  }

  String response = http.getString();
  Serial.println("[COMMS] Response:");
  Serial.println(response);

  http.end();
  return (http_code >= 200 && http_code < 300);
}

bool comms_begin(const char* base_url, int pile_id) {
  if (!base_url) return false;
  g_base_url = String(base_url);
  g_pile_id = pile_id;

  Serial.print("[COMMS] Base URL: ");
  Serial.println(g_base_url);
  Serial.print("[COMMS] Pile ID: ");
  Serial.println(g_pile_id);

  return true;
}

bool comms_post_single(const char* device_id,
                       const Measurement& m,
                       AlertType alert) {
  Serial.println("[COMMS] SINGLE send");
  return post_record(device_id, m, alert, 1.2f, 24.8f);
}

bool comms_post_batch(const char* device_id,
                      Measurement* batch,
                      uint16_t n) {
  Serial.println("[COMMS] BATCH send");

  bool ok_all = true;

  for (uint16_t i = 0; i < n; i++) {
    bool ok = post_record(device_id, batch[i], ALERT_NONE, 1.2f, 24.8f);
    if (!ok) ok_all = false;
  }

  return ok_all;
}