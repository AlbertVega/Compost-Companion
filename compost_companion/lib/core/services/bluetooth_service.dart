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
  StreamSubscription<List<int>>? _notifySub;
  String _rxBuffer = '';

  static const String _serviceShortUuid = '1234';
  static const String _notifyShortUuid = '1235';
  static const String _writeShortUuid = '1236';

  bool get isConnected => _device?.isConnected ?? false;

  void selectDevice(BluetoothDevice device) {
    _device = device;
    _writeChar = null;
    _notifyChar = null;
  }

  final StreamController<Map<String, dynamic>> _incoming = StreamController.broadcast();
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  String _bestDeviceName(ScanResult r) {
    final advName = r.advertisementData.advName.trim();
    final platformName = r.device.platformName.trim();
    if (advName.isNotEmpty) return advName;
    if (platformName.isNotEmpty) return platformName;
    return '';
  }

  bool _uuidMatchesShort(dynamic uuid, String shortUuid) {
    final s = uuid.toString().toLowerCase();
    final short = shortUuid.toLowerCase();
    return s == short || s.startsWith('0000$short-');
  }

  void _tryEmitJson(String candidate) {
    final trimmed = candidate.trim();
    if (trimmed.isEmpty) return;
    try {
      final json = jsonDecode(trimmed);
      if (json is Map<String, dynamic>) {
        _incoming.add(json);
      }
    } catch (_) {
      // Keep buffering until full JSON object is available.
    }
  }

  void _onNotifyData(List<int> data) {
    if (data.isEmpty) return;

    final filtered = data.where((b) => b != 0).toList();
    if (filtered.isEmpty) return;

    _rxBuffer += utf8.decode(filtered, allowMalformed: true);

    while (true) {
      final start = _rxBuffer.indexOf('{');
      if (start < 0) {
        _rxBuffer = '';
        break;
      }
      if (start > 0) {
        _rxBuffer = _rxBuffer.substring(start);
      }

      bool inString = false;
      bool escaped = false;
      int depth = 0;
      int end = -1;

      for (int i = 0; i < _rxBuffer.length; i++) {
        final ch = _rxBuffer[i];
        if (escaped) {
          escaped = false;
          continue;
        }
        if (ch == '\\') {
          escaped = true;
          continue;
        }
        if (ch == '"') {
          inString = !inString;
          continue;
        }
        if (inString) continue;

        if (ch == '{') {
          depth++;
        } else if (ch == '}') {
          depth--;
          if (depth == 0) {
            end = i;
            break;
          }
        }
      }

      if (end < 0) break;

      final candidate = _rxBuffer.substring(0, end + 1);
      _rxBuffer = _rxBuffer.substring(end + 1);
      _tryEmitJson(candidate);

      if (_rxBuffer.startsWith('\n')) {
        _rxBuffer = _rxBuffer.substring(1);
      }
    }
  }

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
          final name = r.device.platformName;
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
          final displayName = _bestDeviceName(r);
          final display = displayName.isNotEmpty ? displayName : r.device.remoteId.str;
          if (nameKeyword != null && nameKeyword.isNotEmpty) {
            if (!display.toLowerCase().contains(nameKeyword.toLowerCase())) continue;
          }

          byId[r.device.remoteId.str] = ScannedDevice(
            device: r.device,
            displayName: display,
            id: r.device.remoteId.str,
            rssi: r.rssi,
            manufacturerData: adv.manufacturerData,
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
      _writeChar = null;
      _notifyChar = null;
      await _notifySub?.cancel();
      _notifySub = null;
      _rxBuffer = '';

      await _device!.connect(autoConnect: false);
      final services = await _device!.discoverServices();

      BluetoothCharacteristic? notifyFallback;
      BluetoothCharacteristic? writeFallback;

      for (final s in services) {
        final isEspService = _uuidMatchesShort(s.uuid, _serviceShortUuid);
        for (final c in s.characteristics) {
          if (c.properties.notify) {
            notifyFallback ??= c;
            if (isEspService && _uuidMatchesShort(c.uuid, _notifyShortUuid)) {
              _notifyChar = c;
            }
          }
          if (c.properties.write || c.properties.writeWithoutResponse) {
            writeFallback ??= c;
            if (isEspService && _uuidMatchesShort(c.uuid, _writeShortUuid)) {
              _writeChar = c;
            }
          }
        }
      }

      _notifyChar ??= notifyFallback;
      _writeChar ??= writeFallback;

      if (_notifyChar != null) {
        try {
          await _notifyChar!.setNotifyValue(true);
        } catch (_) {}
        _notifySub = _notifyChar!.lastValueStream.listen(_onNotifyData);
      }

      return _writeChar != null && _notifyChar != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect() async {
    await _notifySub?.cancel();
    _notifySub = null;
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    _writeChar = null;
    _notifyChar = null;
    _rxBuffer = '';
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
    _notifySub?.cancel();
    _incoming.close();
  }
}
