import 'dart:async';
import 'dart:convert';
import 'package:esp/base/ValueStream.dart';
import 'package:esp/model/sensor_data.dart';
import 'package:esp/service/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/ble_model.dart';

enum BleConnectionState {
  checking,
  permissionDenied,
  permanentlyPermissionDenied,
  bluetoothOff,
  scanning,
  notFound,
  connected,
  tracking,
  disconnected,
}

extension DateOnly on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);
}

extension BluetoothDeviceX on BluetoothDevice {
  /// Returns a safe name:
  /// - mock name if it's your mock device
  /// - otherwise the platformName
  String get safeName {
    if (remoteId.str == "AA:BB:CC:DD:EE:FF") {
      return "ESP32_MOCK";
    }
    return platformName.isNotEmpty ? platformName : "Unknown Device";
  }
}

class BluetoothService {
  static BluetoothService? _instance;

  static BluetoothService get instance => _instance ??= BluetoothService._();

  BluetoothService._();

  bool isMock = false;

  // Streams
  final _stateController = ValueStream<BleConnectionState>();
  final _dataController = StreamController<List<BleData>>.broadcast();
  final _errorController = StreamController<String?>.broadcast();

  Stream<BleConnectionState> get stateStream => _stateController.stream;

  Stream<List<BleData>> get dataStream => _dataController.stream;

  Stream<String?> get errorStream => _errorController.stream;

  // Device info
  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  String? _deviceId;
  String? _deviceName;

  // State
  bool _isTracking = false;
  List<BleData> _data = [];

  // Subscriptions
  StreamSubscription<List<int>>? _dataSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<ScanResult>>? _scanSub;

  // Constants
  static const serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const esp32DeviceName = "ESP32";

  // Getters
  String? get deviceId => _deviceId;

  String? get deviceName => _deviceName;

  bool get isTracking => _isTracking;

  List<BleData> get currentData => List.from(_data);

  // ============================================================
  // STEP 1: Initialize and restore state
  // ============================================================
  Future<void> initialize({bool isMock = false}) async {
    _emit(BleConnectionState.checking);
    this.isMock = isMock;

    final restored = await _restoreState();

    if (!restored) {
      // First time or no previous connection
      // Check Bluetooth status and guide user
      await checkBluetoothStatus();
    }
  }

  Future<bool> _restoreState() async {
    if(isMock){
      return await _mockRestoreState();
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        _isTracking = prefs.getBool('is_tracking') ?? false;
        _deviceId = prefs.getString('device_id');
        _deviceName = prefs.getString('device_name');

        // Check if we have previous device data
        if (_deviceId != null && _deviceId!.isNotEmpty) {
          final devices = await FlutterBluePlus.connectedSystemDevices;
          _device = devices
              .where((d) => d.remoteId.str == _deviceId)
              .firstOrNull;

          if (_device != null) {
            // Previous device is still connected
            await _setupDevice();
            if (_isTracking) await _startNotifications();
            _emit(
              _isTracking
                  ? BleConnectionState.tracking
                  : BleConnectionState.connected,
            );
            return true; // Successfully restored
          } else {
            // Device ID exists but device not connected anymore
            _emitError('Previous device not found. Please scan again.');
          }
        } else {
          // First time - no previous device data
          debugPrint('No previous device found. First time setup required.');
        }
      } catch (e) {
        _emitError('Restore failed: $e');
      }

      // Either first time or restoration failed
      return false;
    }
  }

  Future<bool> _mockRestoreState() async {
    try {
      // Simulate a small delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock tracking state
      final prefs = await SharedPreferences.getInstance();
      _isTracking = prefs.getBool('is_tracking') ?? false;

      // Mock device ID and name
      _deviceId = "AA:BB:CC:DD:EE:FF";
      _deviceName = "ESP32_MOCK";

      // Create mock device
      _device = BluetoothDevice.fromId(_deviceId!);

      // Setup device and notifications (mocked)
      await _setupDevice();
      if (_isTracking) await _startNotifications();

      _emit(_isTracking ? BleConnectionState.tracking : BleConnectionState.connected);

      return true; // Successfully "restored" mock state
    } catch (e) {
      _emitError('Mock restore failed: $e');
      return false;
    }
  }


  // ============================================================
  // STEP 2: Check Bluetooth Status (Support + Permissions)
  // ============================================================
  Future<bool> checkBluetoothStatus() async {
    _emit(BleConnectionState.checking);

    // Check support
    if (!await FlutterBluePlus.isSupported) {
      _emitError("Bluetooth not supported");
      return false;
    }

    // Check permissions
    if (!await _checkPermissions()) {
      return false;
    }

    // Check adapter state
    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      _emit(BleConnectionState.bluetoothOff);
      return false;
    }

    // Check if already connected
    if (_device != null) {
      final connState = await _device!.connectionState.first;
      if (connState == BluetoothConnectionState.connected) {
        _emit(
          _isTracking
              ? BleConnectionState.tracking
              : BleConnectionState.connected,
        );
        return true;
      }
    }

    _emit(BleConnectionState.disconnected);
    return false;
  }

  /// NEW METHOD: Request all required Bluetooth permissions
  /// Call this before attempting any Bluetooth operations
  Future<bool> requestPermissions() async {
    try {
      final permissions = [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ];

      // Check current status of all permissions
      Map<Permission, PermissionStatus> statuses = await permissions.request();

      // Check if all permissions are granted
      for (final permission in permissions) {
        final status = statuses[permission] ?? await permission.status;
        if (status != PermissionStatus.granted) {
          _emitError("Permission ${permission.toString()} denied");
          _emit(BleConnectionState.permissionDenied);
          return false;
        }
      }

      debugPrint('All Bluetooth permissions granted');
      return true;
    } catch (e) {
      _emitError("Error requesting permissions: $e");
      return false;
    }
  }

  /// Internal method to check permissions (used by checkBluetoothStatus)
  Future<bool> _checkPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    for (final permission in permissions) {
      final status = await permission.status;

      if (status != PermissionStatus.granted) {
        final result = await permission.request();

        if (result != PermissionStatus.granted) {
          if (result.isPermanentlyDenied) {
            _emit(BleConnectionState.permanentlyPermissionDenied);
            return false;
          }
          _emit(BleConnectionState.permissionDenied);
          return false;
        }
      }
    }
    return true;
  }

  // ============================================================
  // STEP 3: Scan and Connect
  // ============================================================
  Future<bool> scanAndConnect() async {
    try {
      _emit(BleConnectionState.scanning);

      // Start scan
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 3),
        withServices: [Guid(serviceUUID)],
        withNames: [esp32DeviceName],
      );

      // Listen for results
      final completer = Completer<BluetoothDevice?>();

      if (!isMock) {
        _scanSub = FlutterBluePlus.scanResults.listen((results) {
          for (final r in results) {
            if (r.advertisementData.serviceUuids.contains(Guid(serviceUUID)) &&
                (r.device.platformName.contains('ESP32') ||
                    r.advertisementData.advName.contains('ESP32'))) {
              completer.complete(r.device);
              FlutterBluePlus.stopScan();
              return;
            }
          }
        });
      } else {
        Future.delayed(const Duration(seconds: 3), () {
          final mockDevice = BluetoothDevice.fromId(
              "AA:BB:CC:DD:EE:FF",
          );
          completer.complete(mockDevice);
        });
      }

      // Wait for device or timeout
      _device = await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => null,
      );

      _scanSub?.cancel();
      await FlutterBluePlus.stopScan();

      if (_device == null) {
        _emit(BleConnectionState.notFound);
        _emitError("ESP32 device not found");
        return false;
      }

      // Connect
      return await _connectToDevice();
    } catch (e) {
      _emitError("Scan failed: $e");
      _emit(BleConnectionState.disconnected);
      return false;
    }
  }

  Future<bool> _connectToDevice() async {
    if (_device == null) return false;

    try {
      if (!isMock) {
        await _device!.connect(
          autoConnect: true,
          timeout: const Duration(seconds: 10),
          license: License.free,
        );
      }

      await _setupDevice();

      // Store device info
      _deviceId = _device!.remoteId.str;
      _deviceName = _device!.safeName;
      await _saveState();

      _emit(BleConnectionState.connected);
      return true;
    } catch (e) {
      _emitError("Connection failed: $e");
      _emit(BleConnectionState.disconnected);
      return false;
    }
  }

  // ============================================================
  // STEP 4: Setup Device (Services & Characteristics)
  // ============================================================
  Future<void> _setupDevice() async {
    if(isMock){
      await _mockSetupDevice();
    }else {
      if (_device == null) return;

      // Listen to connection state
      _connSub?.cancel();
      _connSub = _device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        } else if (state == BluetoothConnectionState.connected) {
          _emit(
            _isTracking
                ? BleConnectionState.tracking
                : BleConnectionState.connected,
          );
        }
      });

      // Discover services
      final services = await _device!.discoverServices();

      for (final service in services) {
        if (service.uuid.toString().toLowerCase() ==
            serviceUUID.toLowerCase()) {
          for (final char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() ==
                characteristicUUID.toLowerCase()) {
              _characteristic = char;
              return;
            }
          }
        }
      }

      throw Exception("Service/Characteristic not found");
    }
  }

  Future<void> _mockSetupDevice() async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // simulate discovery delay
    print("_mockSetupDevice");
    // Fake connection state listener
    _connSub?.cancel();
    _connSub =
        Stream<BluetoothConnectionState>.multi((controller) async {
          // await Future.delayed(Duration(seconds: 2));
          controller.add(BluetoothConnectionState.disconnected);
          await Future.delayed(Duration(seconds: 2));
          controller.add(BluetoothConnectionState.connected);
        }
        ).distinct().listen((state) {
          if (state == BluetoothConnectionState.disconnected) {
            _handleDisconnection();
          } else {
            _emit(
              _isTracking
                  ? BleConnectionState.tracking
                  : BleConnectionState.connected,
            );
          }
        });
    // Create a mock characteristic
    _characteristic = BluetoothCharacteristic(
      remoteId: _device!.remoteId,
      serviceUuid: Guid(serviceUUID),
      characteristicUuid: Guid(characteristicUUID),
      primaryServiceUuid: Guid(serviceUUID),
      instanceId: 0,
    );
  }

  // ============================================================
  // STEP 5: Start/Stop Tracking
  // ============================================================
  Future<bool> startTracking() async {
    if (_device == null || _characteristic == null) {
      _emitError("Device not ready");
      return false;
    }

    _isTracking = true;
    await _startNotifications();
    await _saveState();
    _emit(BleConnectionState.tracking);
    return true;
  }

  Future<bool> stopTracking() async {
    _isTracking = false;
    await _stopNotifications();
    await _saveState();
    _emit(BleConnectionState.connected);
    return true;
  }

  Future<void> _startNotifications() async {
    if(isMock){
      await _mockStartNotifications();
    } else {
      if (_characteristic == null) return;

      try {
        await _characteristic!.setNotifyValue(true);

        _dataSub = _characteristic!.onValueReceived.listen((data) async {
          final str = utf8.decode(data);
          await _addData(str);
        });
      } catch (e) {
        _emitError("Failed to start notifications: $e");
      }
    }
  }

  /// Mock version for testing
  Future<void> _mockStartNotifications() async {
    // Simulate enabling notifications delay
    await Future.delayed(const Duration(milliseconds: 200));

    print("start mock notification");
    // Periodically emit fake data
    try {
      await _dataSub?.cancel();
      _dataSub = Stream<List<int>>.periodic(
        const Duration(seconds: 2),
            (count) {
          // Example: sending fake sensor/battery values
          final message = "MockData_${count + 1}";
          print(message);
          return utf8.encode(message);
        },
      ).listen((data) async {
        final str = utf8.decode(data);
        print(str);
        await _addData(str);
      });
    } catch (e){
      print(e.toString());
    }
  }

  Future<void> _stopNotifications() async {
    if (isMock) {
      await _mockStopNotifications();
    } else {
      if (_characteristic == null) return;

      try {
        await _characteristic!.setNotifyValue(false);
        _dataSub?.cancel();
      } catch (e) {
        debugPrint('Stop notifications error: $e');
      }
    }
  }

  Future<void> _mockStopNotifications() async {
    try {
      _dataSub?.cancel();
    } catch (e) {
      debugPrint('Stop notifications error: $e');
    }
  }

  Future<void> _addData(String data) async {
    if(isMock){
      await _mockAddData(data);
    }else {
      final bleData = BleData(timestamp: DateTime.now(), data: data);

      _data.insert(0, bleData);
      await DatabaseService().insertOrUpdateSensorData(SensorData(hydrationLevel: 2, timestamp: bleData.timestamp.dateOnly));
      if (_data.length > 1000) {
        _data = _data.take(1000).toList();
      }

      _dataController.add(List.from(_data));
    }
  }

  /// Mock addData (simulates BLE data)
  Future<void> _mockAddData(String mockData) async {
    final bleData = BleData(timestamp: DateTime.now(), data: mockData, batteryLevel: int.tryParse(mockData.split("_").last) ?? 0);

    _data.insert(0, bleData);
    await DatabaseService().insertOrUpdateSensorData(SensorData(hydrationLevel: 2, timestamp: bleData.timestamp.dateOnly));
    if (_data.length > 1000) {
      _data = _data.take(1000).toList();
    }
    print("added mocked data");
    _dataController.add(List.from(_data));
  }

  // ============================================================
  // STEP 6: Disconnect and Cleanup
  // ============================================================
  Future<void> disconnect() async {
    try {
      _isTracking = false;
      await _stopNotifications();

      _connSub?.cancel();
      _scanSub?.cancel();

      if (_device != null) {
    if(!isMock){
          await _device!.disconnect();
        }
        _device = null;
      }

      _deviceId = null;
      _deviceName = null;

      await _saveState();
      _emit(BleConnectionState.disconnected);
    } catch (e) {
      _emitError("Disconnect error: $e");
    }
  }

  Future<void> _handleDisconnection() async {
    _emit(BleConnectionState.disconnected);
    await _dataSub?.cancel();
    // Auto-reconnect logic can be added here if needed
  }

  // ============================================================
  // Helper Methods
  // ============================================================
  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_tracking', _isTracking);
    await prefs.setString('device_id', _deviceId ?? '');
    await prefs.setString('device_name', _deviceName ?? '');
  }

  void _emit(BleConnectionState state) => _stateController.add(state);

  void _emitError(String error) {
    debugPrint('BLE Error: $error');
    _errorController.add(error);
  }

  void dispose() {
    _stateController.close();
    _dataController.close();
    _errorController.close();
    disconnect();
  }
}

// Usage Example:
/*
final bleService = BluetoothService.instance;

// Initialize
await bleService.initialize();

// Check Bluetooth status
final ready = await bleService.checkBluetoothStatus();

// Scan and connect
if (ready) {
  final connected = await bleService.scanAndConnect();

  if (connected) {
    print('Device: ${bleService.deviceName} (${bleService.deviceId})');

    // Start tracking
    await bleService.startTracking();
  }
}

// Listen to state
bleService.stateStream.listen((state) {
  print('BLE State: $state');
});

// Listen to data
bleService.dataStream.listen((data) {
  print('Received ${data.length} items');
});
*/
