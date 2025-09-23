import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothDeviceModel extends Equatable {
  final String id;
  final String name;
  final int rssi;
  final BluetoothDevice device;
  final bool isConnected;

  const BluetoothDeviceModel({
    required this.id,
    required this.name,
    required this.rssi,
    required this.device,
    this.isConnected = false,
  });

  BluetoothDeviceModel copyWith({
    String? id,
    String? name,
    int? rssi,
    BluetoothDevice? device,
    bool? isConnected,
  }) {
    return BluetoothDeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      device: device ?? this.device,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  List<Object?> get props => [id, name, rssi, device, isConnected];
}
