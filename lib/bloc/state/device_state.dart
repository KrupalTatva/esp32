import 'package:equatable/equatable.dart';
import 'package:esp/base/base_state.dart';

class DeviceState extends BaseState {
  final int batteryLevel; // percentage 0–100
  final String deviceName;
  final String deviceId;
  final bool isLoading;
  final String? error;

  const DeviceState({
    this.batteryLevel = 0,
    this.deviceName = "ESP32 Device",
    this.deviceId = "00:11:22:33:44:55",
    this.isLoading = false,
    this.error,
  });

  DeviceState copyWith({
    int? batteryLevel,
    String? deviceName,
    String? deviceId,
  }) {
    return DeviceState(
      batteryLevel: batteryLevel ?? this.batteryLevel,
      deviceName: deviceName ?? this.deviceName,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  @override
  List<Object?> get props => [batteryLevel, deviceName, deviceId,];
}
