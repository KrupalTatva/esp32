import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'bluetooth_service.dart';
import 'database_service.dart';

class BackgroundWorker {
  static const String bleTaskName = "ble_background_task";
  static const String uniqueName = 'bleBackgroundWork';

  static Future<void> startBackgroundTask() async {
    await Workmanager().registerOneOffTask(
      uniqueName,
      bleTaskName,
      // frequency: Duration(minutes: 15),
      initialDelay: const Duration(seconds: 10),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
    print("worker stared");
  }

  static Future<void> stopBackgroundTask() async {
    await Workmanager().cancelByUniqueName(uniqueName);
    print("worker stopped");
  }

  static Future<bool> getSensorData() async {
    try {
      final service = BluetoothService.instance;
      await DatabaseService().initialize();
      final ready = kDebugMode ? true : await service.checkBluetoothStatus();

      if (!ready) {
        ('Background Worker: Bluetooth not ready');
        return Future.value(false);
      }
      await service.initialize(isMock: true, isBackground: true);

      if (service.isTracking) {
        print('Background Worker: Resuming tracking');
      } else {
        log('Background Worker: Device connected but not tracking');
      }
      return Future.value(true);
    } catch (e) {
      print('Background Worker Error: $e');
      return Future.value(false);
    }
  }
}