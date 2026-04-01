#include "svc_storage.h"
#include <Preferences.h>

static Preferences prefs;
static const char* NS_NAME = "wifi_cfg";
static const char* KEY_SSID = "ssid";
static const char* KEY_PASS = "pass";

void storage_init() {
    prefs.begin(NS_NAME, false);
}

bool storage_has_wifi_credentials() {
    String ssid = prefs.getString(KEY_SSID, "");
    String pass = prefs.getString(KEY_PASS, "");
    return !ssid.isEmpty() && !pass.isEmpty();
}

bool storage_load_wifi_credentials(String& ssid, String& password) {
    ssid = prefs.getString(KEY_SSID, "");
    password = prefs.getString(KEY_PASS, "");

    return !ssid.isEmpty() && !password.isEmpty();
}

bool storage_save_wifi_credentials(const String& ssid, const String& password) {
    if (ssid.isEmpty() || password.isEmpty()) {
        return false;
    }

    bool ok1 = prefs.putString(KEY_SSID, ssid) > 0;
    bool ok2 = prefs.putString(KEY_PASS, password) > 0;

    return ok1 && ok2;
}

void storage_clear_wifi_credentials() {
    if (prefs.isKey(KEY_SSID)) {
        prefs.remove(KEY_SSID);
    }
    if (prefs.isKey(KEY_PASS)) {
        prefs.remove(KEY_PASS);
    }

    Serial.println("[STORAGE] WiFi credentials cleared");
}