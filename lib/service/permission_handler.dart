import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

enum PermissionType {
  bluetooth,
  location,
  notification,
  storage,
}

class PermissionHandlerService {
  static final PermissionHandlerService _instance = PermissionHandlerService._internal();
  factory PermissionHandlerService() => _instance;
  PermissionHandlerService._internal();

  Future<bool> requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final permissions = [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location,
      ];

      Map<Permission, PermissionStatus> statuses = await permissions.request();

      return statuses.values.every((status) =>
      status == PermissionStatus.granted || status == PermissionStatus.limited);
    } else if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      return status == PermissionStatus.granted;
    }
    return true;
  }

  Future<bool> requestNotificationPermissions() async {
    final status = await Permission.notification.request();
    return status == PermissionStatus.granted;
  }

  Future<bool> requestStoragePermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status == PermissionStatus.granted;
    }
    return true;
  }

  Future<bool> checkPermission(PermissionType type) async {
    Permission permission;

    switch (type) {
      case PermissionType.bluetooth:
        if (Platform.isAndroid) {
          final bluetoothScan = await Permission.bluetoothScan.status;
          final bluetoothConnect = await Permission.bluetoothConnect.status;
          final location = await Permission.location.status;

          return bluetoothScan.isGranted &&
              bluetoothConnect.isGranted &&
              location.isGranted;
        } else {
          permission = Permission.bluetooth;
        }
        break;
      case PermissionType.location:
        permission = Permission.location;
        break;
      case PermissionType.notification:
        permission = Permission.notification;
        break;
      case PermissionType.storage:
        permission = Permission.storage;
        break;
    }

    final status = await permission.status;
    return status.isGranted;
  }

  Future<Map<PermissionType, bool>> checkAllPermissions() async {
    return {
      PermissionType.bluetooth: await checkPermission(PermissionType.bluetooth),
      PermissionType.location: await checkPermission(PermissionType.location),
      PermissionType.notification: await checkPermission(PermissionType.notification),
      PermissionType.storage: await checkPermission(PermissionType.storage),
    };
  }

  Future<bool> requestAllPermissions() async {
    final bluetoothGranted = await requestBluetoothPermissions();
    final notificationGranted = await requestNotificationPermissions();
    final storageGranted = await requestStoragePermissions();

    return bluetoothGranted && notificationGranted && storageGranted;
  }

  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}