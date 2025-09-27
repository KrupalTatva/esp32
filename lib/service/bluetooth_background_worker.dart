import 'package:workmanager/workmanager.dart';

import 'bluetooth_service.dart';

class BackgroundWorker {
  static const String bleTaskName = "ble_background_task";

  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static Future<void> startBackgroundTask() async {
    await Workmanager().registerPeriodicTask(
      "1",
      bleTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  static Future<void> stopBackgroundTask() async {
    await Workmanager().cancelByUniqueName("1");
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final service = BluetoothService.instance;

      // Check if Bluetooth is ready
      final ready = await service.checkBluetoothStatus();

      if (!ready) {
        print('Background Worker: Bluetooth not ready');
        return Future.value(false);
      }

      // Initialize and restore connection
      await service.initialize();

      // If tracking was enabled, ensure notifications are active
      if (service.isTracking) {
        print('Background Worker: Resuming tracking');
        // Tracking state will be restored by initialize()
        // No need to call startTracking again
      } else {
        print('Background Worker: Device connected but not tracking');
      }

      return Future.value(true);
    } catch (e) {
      print('Background Worker Error: $e');
      return Future.value(false);
    }
  });
}