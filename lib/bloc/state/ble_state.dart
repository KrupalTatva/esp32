import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:esp/base/base_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../model/ble_model.dart';
import '../../service/bluetooth_service.dart';

class BleState extends Equatable {
  final BleConnectionState connectionState;
  final String? deviceId;
  final String? deviceName;
  final List<BleData> receivedData;
  final String? errorMessage;
  final bool isLoading;

  const BleState({
    required this.connectionState,
    this.deviceId,
    this.deviceName,
    this.receivedData = const [],
    this.errorMessage,
    this.isLoading = false,
  });

  // Helper getters
  bool get isConnected =>
      connectionState == BleConnectionState.connected ||
          connectionState == BleConnectionState.tracking;

  bool get isTracking => connectionState == BleConnectionState.tracking;

  bool get isScanning => connectionState == BleConnectionState.scanning;

  bool get canConnect =>
      connectionState == BleConnectionState.disconnected ||
          connectionState == BleConnectionState.notFound;

  bool get hasError => errorMessage != null;

  String get stateMessage {
    switch (connectionState) {
      case BleConnectionState.checking:
        return 'Checking Bluetooth...';
      case BleConnectionState.permissionDenied:
        return 'Bluetooth permission required';
      case BleConnectionState.bluetoothOff:
        return 'Please turn on Bluetooth';
      case BleConnectionState.scanning:
        return 'Scanning for ESP32...';
      case BleConnectionState.notFound:
        return 'ESP32 device not found';
      case BleConnectionState.connected:
        return 'Connected to $deviceName';
      case BleConnectionState.tracking:
        return 'Tracking data from $deviceName';
      case BleConnectionState.disconnected:
        return 'Disconnected';
      case BleConnectionState.permanentlyPermissionDenied:
        return 'Bluetooth permission required';
    }
  }

  BleState copyWith({
    BleConnectionState? connectionState,
    String? deviceId,
    String? deviceName,
    List<BleData>? receivedData,
    String? errorMessage,
    bool? isLoading,
    bool clearError = false,
    bool clearDeviceInfo = false,
  }) {
    return BleState(
      connectionState: connectionState ?? this.connectionState,
      deviceId: clearDeviceInfo ? null : (deviceId ?? this.deviceId),
      deviceName: clearDeviceInfo ? null : (deviceName ?? this.deviceName),
      receivedData: receivedData ?? this.receivedData,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
    connectionState,
    deviceId,
    deviceName,
    receivedData,
    errorMessage,
    isLoading,
  ];
}

