#include "hal_wifi.h"

void wifi_init() {
    WiFi.mode(WIFI_STA);
    delay(200);
}

bool wifi_connect(const char* ssid, const char* password) {
    if (ssid == nullptr || password == nullptr) {
        Serial.println("[WIFI] SSID o password nulos");
        return false;
    }
    WiFi.disconnect(true);
    delay(500);
    WiFi.mode(WIFI_STA);
    delay(200);

    Serial.print("Connecting to WiFi: ");
    Serial.println(ssid);

    WiFi.begin(ssid, password);

    int retries = 0;
    const int maxRetries = 20;

    while (WiFi.status() != WL_CONNECTED && retries < maxRetries) {
        delay(500);
        Serial.print(".");
        retries++;
    }

    Serial.println();

    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("WiFi connected");
        Serial.print("ESP32 IP: ");
        Serial.println(WiFi.localIP());
        return true;
    } else {
        Serial.println("WiFi connection failed");
        WiFi.disconnect(true);
        delay(300);
        return false;
    }
}

bool wifi_is_connected() {
    return WiFi.status() == WL_CONNECTED;
}

void wifi_disconnect() {
    if (WiFi.status() == WL_CONNECTED) {
        WiFi.disconnect(true);
        Serial.println("WiFi disconnected");
    }
}

String wifi_get_ip() {
    if (WiFi.status() == WL_CONNECTED) {
        return WiFi.localIP().toString();
    }
    return "";
}

String wifi_get_mac() {
    return WiFi.macAddress();
}

int wifi_scan_networks(String results[], int max_results) {
    if (max_results <= 0) {
        return 0;
    }

    WiFi.mode(WIFI_STA);
    delay(200);

    Serial.println("[WIFI] Scanning networks...");
    int n = WiFi.scanNetworks();

    if (n <= 0) {
        Serial.print("[WIFI] Scan result code: ");
        Serial.println(n);
        Serial.println("[WIFI] No networks found");
        return 0;
    }

    int count = (n < max_results) ? n : max_results;

    for (int i = 0; i < count; i++) {
        results[i] = WiFi.SSID(i);
        Serial.print("[WIFI] ");
        Serial.print(i);
        Serial.print(": ");
        Serial.println(results[i]);
    }

    WiFi.scanDelete();
    return count;
}