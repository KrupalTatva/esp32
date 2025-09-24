import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/ble_model.dart';

enum BleConnectionState {
  checking,
  permissionDenied,
  bluetoothOff,
  disconnected,
  connecting,
  connected,
  tracking,
}

class BluetoothService {
  static BluetoothService? _instance;
  static BluetoothService get instance => _instance ??= BluetoothService._();
  BluetoothService._();

  final _connectionStateController = StreamController<BleConnectionState>.broadcast();
  final _dataStreamController = StreamController<List<BleData>>.broadcast();
  final _errorStreamController = StreamController<String?>.broadcast();

  Stream<BleConnectionState> get connectionState => _connectionStateController.stream;
  Stream<List<BleData>> get dataStream => _dataStreamController.stream;
  Stream<String?> get errorStream => _errorStreamController.stream;

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _dataCharacteristic;
  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  Timer? _reconnectTimer;
  bool _isTracking = false;
  List<BleData> _receivedData = [];

  static const String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String esp32DeviceName = "ESP32";
  static const String _trackingKey = 'is_tracking';
  static const String _deviceIdKey = 'connected_device_id';

  /// Entry point - Call this first to initialize the service
  Future<void> initialize() async {
    await _restoreState();
    _connectionStateController.add(BleConnectionState.checking);
    await checkBluetoothStatus();
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
          _connectionStateController.add(BleConnectionState.permissionDenied);
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

  /// Restore previous state from SharedPreferences (tracking state, device ID)
  Future<void> _restoreState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isTracking = prefs.getBool(_trackingKey) ?? false;
      final deviceId = prefs.getString(_deviceIdKey);

      if (deviceId != null && deviceId.isNotEmpty) {
        final connectedDevices = await FlutterBluePlus.connectedSystemDevices;
        _connectedDevice = connectedDevices.firstWhere(
              (device) => device.remoteId.str == deviceId,
          orElse: () => BluetoothDevice.fromId(''),
        );

        if (_connectedDevice?.remoteId.str.isNotEmpty == true) {
          await _setupDevice(_connectedDevice!);
          if (_isTracking) {
            await _startDataReceiving();
          }
        }
      }
    } catch (e) {
      debugPrint('Error restoring state: $e');
    }
  }

  /// Save current state to SharedPreferences
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_trackingKey, _isTracking);
      await prefs.setString(_deviceIdKey, _connectedDevice?.remoteId.str ?? '');
    } catch (e) {
      debugPrint('Error saving state: $e');
    }
  }

  /// Check overall Bluetooth system status (support, permissions, adapter state)
  Future<bool> checkBluetoothStatus() async {
    try {
      // Check if Bluetooth is supported
      if (!await FlutterBluePlus.isSupported) {
        _emitError("Bluetooth not supported on this device");
        return false;
      }

      // Check permissions
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        _connectionStateController.add(BleConnectionState.permissionDenied);
        return false;
      }

      // Check if Bluetooth adapter is on
      final bluetoothState = await FlutterBluePlus.adapterState.first;
      if (bluetoothState != BluetoothAdapterState.on) {
        _connectionStateController.add(BleConnectionState.bluetoothOff);
        return false;
      }

      // Check if we have a connected device
      if (_connectedDevice != null) {
        final connectionState = await _connectedDevice!.connectionState.first;
        if (connectionState == BluetoothConnectionState.connected) {
          _connectionStateController.add(_isTracking
              ? BleConnectionState.tracking
              : BleConnectionState.connected);
          return true;
        }
      }

      _connectionStateController.add(BleConnectionState.disconnected);
      return true;
    } catch (e) {
      _emitError("Error checking Bluetooth status: $e");
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
          return false;
        }
      }
    }
    return true;
  }

  /// Connect to ESP32 device by scanning and connecting
  Future<bool> connectToESP32() async {
    try {
      _connectionStateController.add(BleConnectionState.connecting);

      // Start scanning for ESP32 device
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        withNames: [esp32DeviceName],
      );

      BluetoothDevice? esp32Device;

      // Listen to scan results
      await for (final scanResult in FlutterBluePlus.scanResults) {
        for (final result in scanResult) {
          final device = result.device;
          if (device.platformName.toLowerCase().contains('esp32') ||
              result.advertisementData.advName.toLowerCase().contains('esp32')) {
            esp32Device = device;
            FlutterBluePlus.stopScan(); // optional: stop scanning once found
            break;
          }
        }
      }

      await FlutterBluePlus.stopScan();

      if (esp32Device == null) {
        _emitError("ESP32 device not found");
        _connectionStateController.add(BleConnectionState.disconnected);
        return false;
      }

      // Connect to the device
      await esp32Device.connect(autoConnect: true, license: License.free);
      _connectedDevice = esp32Device;
      await _setupDevice(esp32Device);

      _connectionStateController.add(BleConnectionState.connected);
      await _saveState();
      return true;
    } catch (e) {
      _emitError("Failed to connect: $e");
      _connectionStateController.add(BleConnectionState.disconnected);
      return false;
    }
  }

  /// Setup device services and characteristics after connection
  Future<void> _setupDevice(BluetoothDevice device) async {
    // Listen to connection state changes
    _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _handleDisconnection();
      } else if (state == BluetoothConnectionState.connected) {
        _connectionStateController.add(_isTracking
            ? BleConnectionState.tracking
            : BleConnectionState.connected);
      }
    });

    // Discover services and find required characteristic
    final services = await device.discoverServices();

    for (final service in services) {
      if (service.uuid.toString().toLowerCase() == serviceUUID.toLowerCase()) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toLowerCase() == characteristicUUID.toLowerCase()) {
            _dataCharacteristic = characteristic;
            return;
          }
        }
      }
    }

    throw Exception("Required service/characteristic not found");
  }

  Future<bool> checkForConnectedDevices() async {
    try {
      _connectionStateController.add(BleConnectionState.checking);

      // Get all connected system devices
      final connectedDevices = await FlutterBluePlus.connectedSystemDevices;

      if (connectedDevices.isEmpty) {
        _connectionStateController.add(BleConnectionState.disconnected);
        return false;
      }

      // Find ESP32 or any BLE device (user can connect manually)
      BluetoothDevice? targetDevice;
      for (final device in connectedDevices) {
        // Check if device has our required service
        try {
          final services = await device.discoverServices();
          for (final service in services) {
            if (service.uuid.toString().toLowerCase() == serviceUUID.toLowerCase()) {
              targetDevice = device;
              break;
            }
          }
          if (targetDevice != null) break;
        } catch (e) {
          // Skip this device if we can't discover services
          continue;
        }
      }

      if (targetDevice != null) {
        _connectedDevice = targetDevice;
        await _setupDevice(targetDevice);
        _connectionStateController.add(_isTracking
            ? BleConnectionState.tracking
            : BleConnectionState.connected);
        await _saveState();
        return true;
      } else {
        _connectionStateController.add(BleConnectionState.disconnected);
        return false;
      }
    } catch (e) {
      _emitError("Error checking connected devices: $e");
      _connectionStateController.add(BleConnectionState.disconnected);
      return false;
    }
  }

  /// Handle device disconnection and trigger reconnection
  void _handleDisconnection() {
    _connectionStateController.add(BleConnectionState.disconnected);
    _dataSubscription?.cancel();
    _attemptReconnect();
  }

  /// Attempt to reconnect to device every 10 seconds
  void _attemptReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        if (_connectedDevice != null) {
          await _connectedDevice!.connect(license: License.free);
          await _setupDevice(_connectedDevice!);

          if (_isTracking) {
            await _startDataReceiving();
          }

          timer.cancel();
        }
      } catch (e) {
        debugPrint('Reconnection failed: $e');
      }
    });
  }

  /// Start data tracking - enable notifications and begin receiving data
  Future<bool> startTracking() async {
    if (_connectedDevice == null || _dataCharacteristic == null) {
      _emitError("Device not connected properly");
      return false;
    }

    try {
      _isTracking = true;
      await _startDataReceiving();
      await _saveState();

      _connectionStateController.add(BleConnectionState.tracking);
      return true;
    } catch (e) {
      _emitError("Failed to start tracking: $e");
      return false;
    }
  }

  /// Stop data tracking - disable notifications
  Future<bool> stopTracking() async {
    try {
      _isTracking = false;
      await _stopDataReceiving();
      await _saveState();

      _connectionStateController.add(BleConnectionState.connected);
      return true;
    } catch (e) {
      _emitError("Failed to stop tracking: $e");
      return false;
    }
  }

  /// Enable characteristic notifications and listen to data
  Future<void> _startDataReceiving() async {
    if (_dataCharacteristic == null) return;

    try {
      await _dataCharacteristic!.setNotifyValue(true);

      _dataSubscription = _dataCharacteristic!.onValueReceived.listen((data) {
        final receivedString = utf8.decode(data);
        _addReceivedData(receivedString);
        _sendDataToUI(receivedString);
      });
    } catch (e) {
      _emitError("Failed to start data receiving: $e");
    }
  }

  /// Disable characteristic notifications and stop listening
  Future<void> _stopDataReceiving() async {
    if (_dataCharacteristic == null) return;

    try {
      await _dataCharacteristic!.setNotifyValue(false);
      _dataSubscription?.cancel();
    } catch (e) {
      debugPrint('Error stopping data receiving: $e');
    }
  }

  /// Add received data to internal list and emit to stream
  void _addReceivedData(String data) {
    final bleData = BleData(
      timestamp: DateTime.now(),
      data: data,
    );

    _receivedData.insert(0, bleData);

    // Keep only last 1000 entries
    if (_receivedData.length > 1000) {
      _receivedData = _receivedData.take(1000).toList();
    }

    _dataStreamController.add(List.from(_receivedData));
  }

  /// Send data to UI via isolate communication
  void _sendDataToUI(String data) {
    final sendPort = IsolateNameServer.lookupPortByName('ble_data_port');
    sendPort?.send({
      'type': 'data',
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
    });
  }

  /// Emit error messages
  void _emitError(String error) {
    debugPrint('BLE Service Error: $error');
    _errorStreamController.add(error);
  }

  /// Disconnect from device and cleanup
  Future<void> disconnect() async {
    try {
      _isTracking = false;
      await _stopDataReceiving();

      _connectionSubscription?.cancel();
      _reconnectTimer?.cancel();

      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
      }

      _connectionStateController.add(BleConnectionState.disconnected);
      await _saveState();
    } catch (e) {
      _emitError("Error during disconnect: $e");
    }
  }

  // Getters
  List<BleData> getCurrentData() => List.from(_receivedData);
  bool get isTracking => _isTracking;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Cleanup all resources
  void dispose() {
    _connectionStateController.close();
    _dataStreamController.close();
    _errorStreamController.close();
    disconnect();
  }
}