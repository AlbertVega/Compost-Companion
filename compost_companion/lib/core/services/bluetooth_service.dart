import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScannedDevice {
  final BluetoothDevice device;
  final String displayName;
  final String id;
  final int rssi;
  final Map<int, List<int>> manufacturerData;

  ScannedDevice({
    required this.device,
    required this.displayName,
    required this.id,
    required this.rssi,
    required this.manufacturerData,
  });
}

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  // Use static API on FlutterBluePlus
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;

  bool get isConnected => _device?.isConnected ?? false;

  void selectDevice(BluetoothDevice device) {
    _device = device;
    _writeChar = null;
    _notifyChar = null;
  }

  final StreamController<Map<String, dynamic>> _incoming = StreamController.broadcast();
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  /// Scans for an ESP32 device and returns it if found.
  Future<BluetoothDevice?> scanForESP({Duration timeout = const Duration(seconds: 8)}) async {
    // startScan may return void on some versions; use scanResults stream instead
      try {
        try {
          await FlutterBluePlus.startScan(timeout: timeout);
        } catch (_) {
          // startScan might be synchronous on some platforms; call without await
          FlutterBluePlus.startScan(timeout: timeout);
        }

      final completer = Completer<BluetoothDevice?>();
      final sub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = r.device.name ?? '';
          if (name.toLowerCase().contains('esp32')) {
            _device = r.device;
            if (!completer.isCompleted) completer.complete(_device);
            break;
          }
        }
      });

      BluetoothDevice? found;
      try {
        found = await completer.future.timeout(timeout, onTimeout: () => null);
      } catch (_) {
        found = null;
      }

      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
      await sub.cancel();
      return found;
    } catch (e) {
      return null;
    }
  }

  /// Scans for BLE devices and returns the unique list.
  /// If [nameKeyword] is provided, only devices whose name contains it are returned.
  Future<List<ScannedDevice>> scanDevices({
    Duration timeout = const Duration(seconds: 6),
    String? nameKeyword,
  }) async {
    final Map<String, ScannedDevice> byId = {};
    StreamSubscription? sub;
    try {
      try {
        await FlutterBluePlus.startScan(timeout: timeout);
      } catch (_) {
        FlutterBluePlus.startScan(timeout: timeout);
      }

      sub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final adv = r.advertisementData;
          final localName = (adv.localName ?? '').trim();
          final deviceName = (r.device.name ?? '').trim();
          final display = localName.isNotEmpty
              ? localName
              : (deviceName.isNotEmpty ? deviceName : r.device.remoteId.str);
          if (nameKeyword != null && nameKeyword.isNotEmpty) {
            if (!display.toLowerCase().contains(nameKeyword.toLowerCase())) continue;
          }

          byId[r.device.remoteId.str] = ScannedDevice(
            device: r.device,
            displayName: display,
            id: r.device.remoteId.str,
            rssi: r.rssi,
            manufacturerData: adv.manufacturerData ?? {},
          );
        }
      });

      await Future<void>.delayed(timeout);
    } catch (_) {
      // ignore
    } finally {
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
      await sub?.cancel();
    }
    return byId.values.toList();
  }

  /// Connects to the discovered device and finds writable/notify characteristics.
  Future<bool> connect() async {
    if (_device == null) return false;
    try {
      await _device!.connect(autoConnect: false);
      final services = await _device!.discoverServices();
      for (final s in services) {
        for (final c in s.characteristics) {
          if (c.properties.notify) {
            _notifyChar = c;
            try {
              await _notifyChar!.setNotifyValue(true);
            } catch (_) {}
            _notifyChar!.onValueReceived.listen((data) {
              if (data.isEmpty) return;
              try {
                final str = utf8.decode(data);
                final json = jsonDecode(str) as Map<String, dynamic>;
                _incoming.add(json);
              } catch (_) {}
            });
          }
          if (c.properties.write || c.properties.writeWithoutResponse) {
            _writeChar ??= c;
          }
        }
      }
      return _writeChar != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    _writeChar = null;
    _notifyChar = null;
  }

  Future<bool> sendJson(Map<String, dynamic> msg) async {
    if (_writeChar == null) return false;
    final bytes = utf8.encode(jsonEncode(msg));
    try {
      await _writeChar!.write(bytes, withoutResponse: !_writeChar!.properties.write);
      return true;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _incoming.close();
  }
}
