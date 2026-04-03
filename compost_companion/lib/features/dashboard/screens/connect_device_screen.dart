import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' show BluetoothDevice;

import 'package:compost_companion/core/services/bluetooth_service.dart';
import 'package:compost_companion/core/services/bluetooth_permission_service.dart';

enum ConnectState {
  scanningDevices,
  deviceSelected,
  scanningNetworks,
  configuring,
  success,
  error,
  permissionRequired,
}

class ConnectDeviceScreen extends StatefulWidget {
  final int pileId;
  const ConnectDeviceScreen({super.key, required this.pileId});

  @override
  State<ConnectDeviceScreen> createState() => _ConnectDeviceScreenState();
}

class _ConnectDeviceScreenState extends State<ConnectDeviceScreen> {
  final BluetoothService _bt = BluetoothService();
  final BluetoothPermissionService _perms = BluetoothPermissionService();

  ConnectState _state = ConnectState.scanningDevices;
  bool _busy = false;
  String? _error;

  // Step 1: Devices
  static const List<String> mockDevices = [
    'ESP32-Companion',
    'Sensor-Test',
    'Demo-Device',
  ];
  List<String> _devices = [];
  List<ScannedDevice> _scannedDevices = [];
  BluetoothDevice? _selectedBleDevice;
  String? _selectedDeviceName;

  // Step 2: WiFi
  List<String> _networks = [];
  String? _selectedSsid;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _preflightPermissions();
  }

  Future<void> _preflightPermissions() async {
    final ok = await _perms.hasAllRequired();
    if (!ok && mounted) {
      setState(() {
        _state = ConnectState.permissionRequired;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _bt.disconnect();
    super.dispose();
  }

  void _setError(String message) {
    setState(() {
      _error = message;
      _busy = false;
      _state = ConnectState.error;
    });
  }

  Future<void> _scanDevices() async {
    // Never attempt BLE scanning on Android without permissions.
    final hasPerms = await _perms.hasAllRequired();
    if (!hasPerms) {
      setState(() {
        _state = ConnectState.permissionRequired;
        _error = 'Bluetooth permissions are required';
        _busy = false;
      });
      return;
    }

    setState(() {
      _state = ConnectState.scanningDevices;
      _busy = true;
      _error = null;
      _devices = [];
      _selectedDeviceName = null;
      _selectedBleDevice = null;
      _selectedSsid = null;
      _networks = [];
      _passwordController.text = '';
    });

    try {
      // Optional BLE scan. If empty or fails, fall back to mockDevices.
      final scanned = await _bt.scanDevices(timeout: const Duration(seconds: 4));

      final sortedScanned = [...scanned]
        ..sort((a, b) {
          final byName = a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
          if (byName != 0) return byName;
          return a.id.compareTo(b.id);
        });

      // Build display labels using displayName and a short id fallback.
      final labels = sortedScanned
          .map((d) {
            final shortId = d.id.contains(':') ? d.id.split(':').last : d.id;
            return d.displayName.isNotEmpty ? '${d.displayName} ($shortId)' : d.id;
          })
          .toList();

      setState(() {
        _scannedDevices = sortedScanned;
        _devices = labels.isNotEmpty ? labels : List<String>.from(mockDevices);
        _busy = false;
      });
    } catch (_) {
      setState(() {
        _scannedDevices = [];
        _devices = List<String>.from(mockDevices);
        _busy = false;
      });
    }
  }
  Future<void> _selectDeviceByIndex(int index) async {
    final name = _devices[index];
    setState(() {
      _selectedDeviceName = name;
      _state = ConnectState.deviceSelected;
      _error = null;
      _busy = false;
    });

    // Try to bind to a real BLE device if we have a scanned match.
    try {
      if (index < _scannedDevices.length) {
        final entry = _scannedDevices[index];
        final device = entry.device;
        _selectedBleDevice = device;
        _bt.selectDevice(_selectedBleDevice!);
        final ok = await _bt.connect();
        if (!ok) {
          // Keep flow usable even if BLE connect fails.
          _selectedBleDevice = null;
        }
      } else {
        _selectedBleDevice = null;
      }
    } catch (_) {
      _selectedBleDevice = null;
    }
  }

  Future<void> _scanNetworks() async {
    if (_selectedDeviceName == null) {
      _setError('Select a device first');
      return;
    }
    setState(() {
      _state = ConnectState.scanningNetworks;
      _busy = true;
      _error = null;
      _networks = [];
      _selectedSsid = null;
      _passwordController.text = '';
    });

    if (!_bt.isConnected && _selectedBleDevice != null) {
      _bt.selectDevice(_selectedBleDevice!);
      final connected = await _bt.connect();
      if (!connected) {
        _setError('Could not connect to selected ESP32 over BLE');
        return;
      }
    }

    if (!_bt.isConnected) {
      _setError('No real BLE connection. Please select a detected ESP32 device first');
      return;
    }

    try {
      final completer = Completer<List<String>>();
      late final StreamSubscription sub;
      sub = _bt.incoming.listen((msg) {
        if (msg['status'] == 'scan_result' && msg['networks'] is List) {
          final nets = (msg['networks'] as List).map((e) => e.toString()).toList();
          if (!completer.isCompleted) completer.complete(nets);
        } else if (msg['status'] == 'error') {
          if (!completer.isCompleted) {
            completer.completeError(Exception(msg['reason']?.toString() ?? 'scan_error'));
          }
        }
      });

        final ok = await _bt.sendJson({'action': 'scan'});
        if (!ok) {
          await sub.cancel();
          _setError('Failed to send Wi-Fi scan request to ESP32');
          return;
        }

      final nets = await completer.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw TimeoutException('Timed out waiting for Wi-Fi scan result'),
      );
      await sub.cancel();

      setState(() {
        _networks = nets;
        _busy = false;
        if (_networks.isEmpty) {
          _error = 'ESP32 returned no Wi-Fi networks';
        }
      });
      return;
    } on TimeoutException catch (e) {
      _setError(e.message ?? 'Timed out waiting for Wi-Fi scan result from ESP32');
      return;
    } catch (e) {
      _setError('Failed to scan Wi-Fi networks from ESP32: $e');
      return;
    }
  }

  Future<void> _connectWifi() async {
    if (_selectedSsid == null) {
      _setError('Select a WiFi network');
      return;
    }
    setState(() {
      _state = ConnectState.configuring;
      _busy = true;
      _error = null;
    });

    final payload = {
      'action': 'set_wifi',
      'ssid': _selectedSsid,
      'password': _passwordController.text,
      'pileId': widget.pileId.toString(),
    };

    // Real BLE path
    if (_bt.isConnected) {
      String? failureReason;
      try {
        final completer = Completer<void>();
        late final StreamSubscription sub;
        sub = _bt.incoming.listen((msg) {
          final status = msg['status']?.toString().trim().toLowerCase();
          if (status == 'success') {
            if (!completer.isCompleted) completer.complete();
          } else if (status == 'error') {
            failureReason = msg['reason']?.toString() ?? 'unknown_error';
            if (!completer.isCompleted) {
              completer.completeError(Exception(failureReason));
            }
          } else if (status == 'connecting') {
            // remain in configuring state
          }
        });

        final ok = await _bt.sendJson(payload);
        if (!ok) {
          await sub.cancel();
          _setError('Failed to send credentials');
          return;
        }

        try {
          await completer.future.timeout(
            const Duration(seconds: 12),
            onTimeout: () => throw TimeoutException('Timed out waiting for success'),
          );
        } finally {
          await sub.cancel();
        }

        setState(() {
          _busy = false;
          _state = ConnectState.success;
        });
        return;
      } on TimeoutException catch (e) {
        _setError(e.message ?? 'Timed out waiting for success response from ESP32');
        return;
      } catch (e) {
        final detail = failureReason == null ? '$e' : failureReason!;
        _setError('Failed to configure device: $detail');
        return;
      }
    }

    // Mock path
    await Future<void>.delayed(const Duration(seconds: 1));
    setState(() {
      _busy = false;
      _state = ConnectState.success;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect Device')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pile ID: ${widget.pileId}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            if (_state == ConnectState.permissionRequired) ...[
              const Spacer(),
              const Center(
                child: Icon(Icons.bluetooth_disabled, color: Colors.grey, size: 64),
              ),
              const SizedBox(height: 12),
              const Center(child: Text('Bluetooth permissions are required')),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final ok = await _perms.requestBluetoothPermissions();
                  if (!ok) {
                    final permDenied = await _perms.isPermanentlyDenied();
                    if (permDenied) {
                      setState(() {
                        _error = 'Permissions permanently denied. Please enable them in Settings.';
                      });
                    } else {
                      setState(() {
                        _error = 'Permissions denied. Please grant them to scan.';
                      });
                    }
                    return;
                  }
                  if (!mounted) return;
                  setState(() {
                    _state = ConnectState.scanningDevices;
                    _error = null;
                  });
                },
                child: const Text('Grant Permissions'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  final permDenied = await _perms.isPermanentlyDenied();
                  if (permDenied) {
                    await _perms.openSettings();
                  } else {
                    await _perms.requestBluetoothPermissions();
                  }
                },
                child: const Text('Open Settings'),
              ),
              const Spacer(),
            ] else if (_state == ConnectState.scanningDevices) ...[
              ElevatedButton(
                onPressed: _busy ? null : _scanDevices,
                child: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Scan Devices'),
              ),
              const SizedBox(height: 12),
              const Text('Discovered Devices', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Expanded(
                child: _devices.isEmpty
                    ? const Center(child: Text('No devices found'))
                    : ListView.separated(
                        itemCount: _devices.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final name = _devices[i];
                          return ListTile(
                            title: Text(name),
                            onTap: _busy ? null : () => _selectDeviceByIndex(i),
                          );
                        },
                      ),
              ),
            ] else if (_state == ConnectState.deviceSelected || _state == ConnectState.scanningNetworks) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bluetooth),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_selectedDeviceName ?? 'No device selected')),
                    Text(_bt.isConnected ? 'Connected' : 'Mock', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _busy ? null : _scanNetworks,
                child: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Scan WiFi Networks'),
              ),
              const SizedBox(height: 12),
              const Text('Available Networks', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Expanded(
                child: _networks.isEmpty
                    ? const Center(child: Text('No networks found'))
                    : ListView.separated(
                        itemCount: _networks.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final ssid = _networks[i];
                          final selected = _selectedSsid == ssid;
                          return ListTile(
                            title: Text(ssid),
                            trailing: selected ? const Icon(Icons.check) : null,
                            onTap: _busy
                                ? null
                                : () {
                                    setState(() {
                                      _selectedSsid = ssid;
                                    });
                                  },
                          );
                        },
                      ),
              ),
              if (_selectedSsid != null) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'WiFi Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _busy ? null : _connectWifi,
                  child: const Text('Connect'),
                ),
                const SizedBox(height: 8),
              ],
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        setState(() {
                          _state = ConnectState.scanningDevices;
                          _devices = [];
                          _selectedDeviceName = null;
                          _selectedBleDevice = null;
                          _networks = [];
                          _selectedSsid = null;
                          _passwordController.text = '';
                          _error = null;
                        });
                      },
                child: const Text('Back to Devices'),
              ),
            ] else if (_state == ConnectState.configuring) ...[
              const Spacer(),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              const Center(child: Text('Configuring device...')),
              const Spacer(),
            ] else if (_state == ConnectState.success) ...[
              const Spacer(),
              const Center(
                child: Icon(Icons.check_circle, color: Colors.green, size: 64),
              ),
              const SizedBox(height: 12),
              const Center(child: Text('Device connected successfully')),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
              const Spacer(),
            ] else if (_state == ConnectState.error) ...[
              const Spacer(),
              const Center(child: Icon(Icons.error_outline, color: Colors.red, size: 64)),
              const SizedBox(height: 12),
              Center(child: Text(_error ?? 'Something went wrong')),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _busy
                    ? null
                    : () {
                        setState(() {
                          _state = ConnectState.scanningDevices;
                          _error = null;
                          _busy = false;
                        });
                      },
                child: const Text('Retry'),
              ),
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}
