import 'package:esp/model/ble_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit/ble_cubit.dart';
import '../bloc/state/ble_state.dart';
import '../service/bluetooth_service.dart';

class DeviceInfoCard extends StatefulWidget {
  final String name;
  final String id;
  final int batteryLevel;

  const DeviceInfoCard({
    super.key,
    required this.name,
    required this.id,
    required this.batteryLevel,
  });

  @override
  State<DeviceInfoCard> createState() => _DeviceInfoCardState();
}

class _DeviceInfoCardState extends State<DeviceInfoCard> {

  var bleCubit = BleCubit();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BleCubit, BleState>(
      bloc: bleCubit,
      builder: (context, state) {
        // Loading
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Error
        if (
          (state.errorMessage != null && state.errorMessage!.isNotEmpty) ||
          (state.connectionState == BleConnectionState.permanentlyPermissionDenied) ||
          (state.connectionState == BleConnectionState.bluetoothOff) ||
          (state.connectionState == BleConnectionState.permissionDenied) ||
          (state.connectionState == BleConnectionState.disconnected)
        ) {
          return Card(
            color: Colors.red[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      /*state.errorMessage ??*/
                          "Can't find your bottle. Please check Bluetooth connection with bottle and try again.",
                      style: TextStyle(color: Colors.red[800], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Connected
        if (state.connectionState == BleConnectionState.connected || state.connectionState == BleConnectionState.tracking) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Device Info
                  Text(
                    "MyBottle",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "ID: AA:BB:CC:DD:EE:FF",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Divider(height: 24),

                  // Battery Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Battery Level",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        "${_extractBatteryLevel(state.receivedData)}%",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _extractBatteryLevel(state.receivedData) > 20 ? Colors.green[400] : Colors.red[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _extractBatteryLevel(state.receivedData) / 100,
                      minHeight: 12,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(
                        _extractBatteryLevel(state.receivedData) > 20 ? Colors.green[400] : Colors.red[400],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Default (initial / searching)
        return const Center(
          child: Text(
            "Searching for your SmartSip bottle...",
            style: TextStyle(color: Colors.grey),
          ),
        );
      },
    );
  }

  int _extractBatteryLevel(List<BleData> data) {
    if (data.isEmpty) return 20;
    // Example: if your BLE packet first byte is battery %
    return data.first.batteryLevel;
  }
}
