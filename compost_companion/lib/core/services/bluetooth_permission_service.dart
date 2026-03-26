import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class BluetoothPermissionService {
  Future<bool> requestBluetoothPermissions() async {
    // Non-Android platforms generally don't need these runtime permissions.
    if (!Platform.isAndroid) return true;

    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    final location = await Permission.location.request();

    // Debug support
    // ignore: avoid_print
    print('Scan permission: $scan');
    // ignore: avoid_print
    print('Connect permission: $connect');
    // ignore: avoid_print
    print('Location permission: $location');

    return scan.isGranted && connect.isGranted && location.isGranted;
  }

  Future<bool> isPermanentlyDenied() async {
    if (!Platform.isAndroid) return false;
    final scanDenied = await Permission.bluetoothScan.isPermanentlyDenied;
    final locDenied = await Permission.location.isPermanentlyDenied;
    return scanDenied || locDenied;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<bool> hasAllRequired() async {
    if (!Platform.isAndroid) return true;
    final scan = await Permission.bluetoothScan.status;
    final connect = await Permission.bluetoothConnect.status;
    final location = await Permission.location.status;
    // ignore: avoid_print
    print('Scan permission: $scan');
    // ignore: avoid_print
    print('Connect permission: $connect');
    // ignore: avoid_print
    print('Location permission: $location');
    return scan.isGranted && connect.isGranted && location.isGranted;
  }
}
