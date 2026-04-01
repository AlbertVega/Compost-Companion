#include "hal_ble.h"
#include <NimBLEDevice.h>

static NimBLEServer* g_server = nullptr;
static NimBLECharacteristic* g_txChar = nullptr;
static NimBLECharacteristic* g_rxChar = nullptr;

static bool g_bleConnected = false;
static bool g_hasMessage = false;
static String g_lastMessage = "";

class ServerCallbacks : public NimBLEServerCallbacks {
public:
    void onConnect(NimBLEServer* pServer, NimBLEConnInfo& connInfo) override {
        g_bleConnected = true;
        Serial.println("[BLE] Connected");
    }

    void onDisconnect(NimBLEServer* pServer, NimBLEConnInfo& connInfo, int reason) override {
        g_bleConnected = false;
        Serial.println("[BLE] Disconnected");
        NimBLEDevice::startAdvertising();
    }
};

class RxCallbacks : public NimBLECharacteristicCallbacks {
public:
    void onWrite(NimBLECharacteristic* pCharacteristic, NimBLEConnInfo& connInfo) override {
        std::string value = pCharacteristic->getValue();

        if (!value.empty()) {
            g_lastMessage = String(value.c_str());
            g_hasMessage = true;

            Serial.println("[BLE] Received:");
            Serial.println(g_lastMessage);
        }
    }
};

void ble_init(const char* device_name) {
    Serial.println("[BLE] Init NimBLE...");

    NimBLEDevice::init(device_name);

    g_server = NimBLEDevice::createServer();
    g_server->setCallbacks(new ServerCallbacks());

    NimBLEService* service = g_server->createService("1234");

    g_txChar = service->createCharacteristic(
        "1235",
        NIMBLE_PROPERTY::NOTIFY
    );

    g_rxChar = service->createCharacteristic(
        "1236",
        NIMBLE_PROPERTY::WRITE
    );

    g_rxChar->setCallbacks(new RxCallbacks());

    NimBLEAdvertising* advertising = NimBLEDevice::getAdvertising();
    advertising->addServiceUUID("1234");
    advertising->start();

    Serial.println("[BLE] Advertising...");
}

bool ble_has_message() {
    return g_hasMessage;
}

String ble_get_message() {
    return g_lastMessage;
}

void ble_clear_message() {
    g_lastMessage = "";
    g_hasMessage = false;
}

void ble_send_message(const String& msg) {
    if (!g_txChar) return;

    g_txChar->setValue(msg.c_str());
    g_txChar->notify();

    Serial.println("[BLE] Sent:");
    Serial.println(msg);
}

bool ble_is_connected() {
    return g_bleConnected;
}

void ble_poll() {
}

void ble_stop() {
    NimBLEDevice::deinit(true);
}