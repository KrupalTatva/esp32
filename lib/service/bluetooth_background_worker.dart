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
      final bluetoothService = BluetoothService.instance;

      final isConnected = await bluetoothService.checkBluetoothStatus();
      print("worker 1");

      if (!isConnected && bluetoothService.connectedDevice == null) {
        await bluetoothService.checkForConnectedDevices();
      }

      if (bluetoothService.isTracking) {
        await bluetoothService.startTracking();
      }

      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}