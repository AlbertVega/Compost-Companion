#include "svc_provisioning.h"

#include <ArduinoJson.h>

#include "hal_ble.h"
#include "hal_wifi.h"
#include "svc_storage.h"

static bool g_provisioning_complete = false;

void provisioning_init(const char* ble_name) {
    g_provisioning_complete = false;
    ble_init(ble_name);
}

bool provisioning_is_complete() {
    return g_provisioning_complete;
}

static void handle_scan_request() {
    const int MAX_NETWORKS = 10;
    String networks[MAX_NETWORKS];

    int count = wifi_scan_networks(networks, MAX_NETWORKS);

    JsonDocument doc;
    doc["status"] = "scan_result";

    JsonArray arr = doc["networks"].to<JsonArray>();
    for (int i = 0; i < count; i++) {
        arr.add(networks[i]);
    }

    String response;
    serializeJson(doc, response);
    ble_send_message(response);
}

static void handle_set_wifi_request(JsonDocument& doc) {
    if (!doc["ssid"].is<const char*>() || !doc["password"].is<const char*>()) {
        ble_send_message("{\"status\":\"error\",\"reason\":\"missing_fields\"}");
        return;
    }

    String ssid = doc["ssid"].as<String>();
    String password = doc["password"].as<String>();

    ble_send_message("{\"status\":\"connecting\"}");

    bool ok = wifi_connect(ssid.c_str(), password.c_str());

   if (ok) {
    bool saved = storage_save_wifi_credentials(ssid, password);

    if (saved) {
        // Build success response with MAC address
        JsonDocument respDoc;
        respDoc["status"] = "success";
        respDoc["mac"] = wifi_get_mac();  //mac address

        String respStr;
        serializeJson(respDoc, respStr);
        ble_send_message(respStr);

        g_provisioning_complete = true;
    } else {
        ble_send_message("{\"status\":\"error\",\"reason\":\"save_failed\"}");
    }
}
}

void provisioning_poll() {
    ble_poll();

    if (!ble_has_message()) {
        return;
    }

    String msg = ble_get_message();
    ble_clear_message();

    Serial.println("[PROV] Received message:");
    Serial.println(msg);

    JsonDocument doc;
    DeserializationError err = deserializeJson(doc, msg);

    if (err) {
        ble_send_message("{\"status\":\"error\",\"reason\":\"invalid_json\"}");
        return;
    }

    if (!doc["action"].is<const char*>()) {
        ble_send_message("{\"status\":\"error\",\"reason\":\"missing_action\"}");
        return;
    }

    String action = doc["action"].as<String>();

    if (action == "scan") {
        handle_scan_request();
    } else if (action == "set_wifi") {
        handle_set_wifi_request(doc);
    } else if (action == "ping") {
        ble_send_message("{\"status\":\"ok\"}");
    } else if (action == "clear_wifi") {
        Serial.println("[PROV] Clearing WiFi credentials...");
        storage_clear_wifi_credentials();
        ble_send_message("{\"status\":\"wifi_cleared\"}");
        delay(500);
        ESP.restart();
    } else {
        ble_send_message("{\"status\":\"error\",\"reason\":\"unknown_action\"}");
    }
    
}
void provisioning_stop() {
    ble_stop();
}