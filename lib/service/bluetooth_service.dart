import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothHandlerService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;
  StreamSubscription? _deviceStateSubscription;
  StreamSubscription? _dataSubscription;

  // Callbacks
  Function(String)? onDataReceived;
  Function(BluetoothConnectionState)? onConnectionStateChanged;
  Function(String)? onError;

  // Common ESP32 service and characteristic UUIDs
  static const String serviceUUID = "12345678-1234-5678-9012-123456789abc";
  static const String writeCharUUID = "87654321-4321-8765-2109-cba987654321";
  static const String readCharUUID = "11111111-2222-3333-4444-555555555555";

  bool get isConnected => _device?.isConnected ?? false;
  BluetoothDevice? get connectedDevice => _device;


  /// Find ESP32 device by name (includes already connected devices)
  Future<List<BluetoothDevice>> findDevices({String deviceName = "ESP32"}) async {
    List<BluetoothDevice> devices = [];

    try {
      // Check if Bluetooth is available
      if (await FlutterBluePlus.isAvailable == false) {
        throw Exception("Bluetooth not available");
      }

      // First, check for already connected devices
      List<BluetoothDevice> connectedDevices = FlutterBluePlus.connectedDevices;
      for (BluetoothDevice device in connectedDevices) {
        if (device.platformName.contains(deviceName)) {
          devices.add(device);
        }
      }

      // Then scan for nearby devices
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 10));

      // Listen for scan results
      await for (List<ScanResult> results in FlutterBluePlus.scanResults) {
        for (ScanResult result in results) {
          if (result.device.platformName.contains(deviceName) &&
              !devices.contains(result.device)) {
            devices.add(result.device);
          }
        }
      }

      await FlutterBluePlus.stopScan();
      return devices;

    } catch (e) {
      onError?.call("Error finding devices: $e");
      return [];
    }
  }

  /// Connect to ESP32 device (handles already connected devices)
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _device = device;

      // Check if device is already connected
      if (device.isConnected) {
        // Device already connected, just setup characteristics
        await _setupCharacteristics();
        onConnectionStateChanged?.call(BluetoothConnectionState.connected);
        return true;
      }

      // Listen to connection state changes
      _deviceStateSubscription = device.connectionState.listen((state) {
        onConnectionStateChanged?.call(state);
        if (state == BluetoothConnectionState.disconnected) {
          _cleanup();
        }
      });

      // Connect to device
      await device.connect(timeout: Duration(seconds: 15), license: License.free);

      // Setup characteristics
      await _setupCharacteristics();

      return true;

    } catch (e) {
      onError?.call("Connection failed: $e");
      await disconnect();
      return false;
    }
  }

  /// Setup service and characteristics
  Future<void> _setupCharacteristics() async {
    if (_device == null) return;

    // Discover services
    List<BluetoothService> services = (await _device!.discoverServices()).cast<BluetoothService>();

    // Find the service and characteristics
    BluetoothService? targetService;
    for (BluetoothService service in services) {
      if (service.uuid.toString().toLowerCase() == serviceUUID.toLowerCase()) {
        targetService = service;
        break;
      }
    }

    if (targetService == null) {
      throw Exception("Service not found");
    }

    // Find characteristics
    for (BluetoothCharacteristic characteristic in targetService.characteristics) {
      String charUuid = characteristic.uuid.toString().toLowerCase();

      if (charUuid == writeCharUUID.toLowerCase()) {
        _writeCharacteristic = characteristic;
      } else if (charUuid == readCharUUID.toLowerCase()) {
        _readCharacteristic = characteristic;
      }
    }

    // Enable notifications for read characteristic
    if (_readCharacteristic != null) {
      await _readCharacteristic!.setNotifyValue(true);
      _startListening();
    }
  }

  /// Start listening for incoming data
  void _startListening() {
    if (_readCharacteristic == null) return;

    _dataSubscription = _readCharacteristic!.lastValueStream.listen(
            (data) {
          if (data.isNotEmpty) {
            String receivedData = utf8.decode(data);
            onDataReceived?.call(receivedData);
          }
        },
        onError: (error) {
          onError?.call("Data listening error: $error");
        }
    );
  }

  /// Send data to ESP32
  Future<bool> sendData(String data) async {
    if (!isConnected || _writeCharacteristic == null) {
      onError?.call("Device not connected or write characteristic not found");
      return false;
    }

    try {
      List<int> bytes = utf8.encode(data);
      await _writeCharacteristic!.write(bytes);
      return true;
    } catch (e) {
      onError?.call("Failed to send data: $e");
      return false;
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    try {
      if (_device != null) {
        await _device!.disconnect();
      }
    } catch (e) {
      onError?.call("Disconnect error: $e");
    } finally {
      _cleanup();
    }
  }

  /// Clean up resources
  void _cleanup() {
    _deviceStateSubscription?.cancel();
    _dataSubscription?.cancel();
    _device = null;
    _writeCharacteristic = null;
    _readCharacteristic = null;
  }

  /// Check if device is already connected by this handler
  bool isAlreadyConnected(BluetoothDevice device) {
    return _device?.remoteId == device.remoteId && isConnected;
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
  }
}