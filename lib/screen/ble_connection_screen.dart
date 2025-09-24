import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit/ble_cubit.dart';
import '../bloc/state/ble_state.dart';
import '../model/ble_model.dart';
import '../service/bluetooth_service.dart' hide BleData;

class BleConnectionScreen extends StatefulWidget {
  const BleConnectionScreen({super.key});

  @override
  State<BleConnectionScreen> createState() => _BleConnectionScreenState();
}

class _BleConnectionScreenState extends State<BleConnectionScreen>
    with WidgetsBindingObserver {
  var bleCubit = BleCubit();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    bleCubit.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // bleCubit.checkStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE ESP32 Connection'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              bleCubit.checkStatus();
              print('screen 1');
            },
          ),
        ],
      ),
      body: BlocConsumer<BleCubit, BleState>(
        bloc: bleCubit,
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusCard(state),
                const SizedBox(height: 20),
                _buildActionButtons(state),
                const SizedBox(height: 20),
                if (state.receivedData.isNotEmpty) _buildDataList(state),
              ],
            ),
          );
        },
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? "Something went wrong"),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Dismiss',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    bleCubit.clearError();
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildStatusCard(BleState state) {
    IconData icon;
    String title;
    String subtitle;
    Color color;

    switch (state.connectionState) {
      case BleConnectionState.checking:
        icon = Icons.bluetooth_searching;
        title = "Checking Connection...";
        subtitle = "Please wait";
        color = Colors.orange;
        break;
      case BleConnectionState.bluetoothOff:
        icon = Icons.bluetooth_disabled;
        title = "Bluetooth is Off";
        subtitle = "Please turn on Bluetooth in settings";
        color = Colors.red;
        break;
      case BleConnectionState.permissionDenied:
        icon = Icons.block;
        title = "Permission Denied";
        subtitle = "Please grant Bluetooth permissions";
        color = Colors.red;
        break;
      case BleConnectionState.disconnected:
        icon = Icons.bluetooth_disabled;
        title = "No Device Connected";
        subtitle = "Please pair your ESP32 device in Bluetooth settings first";
        color = Colors.orange;
        break;
      case BleConnectionState.connected:
        icon = Icons.bluetooth;
        title = state.deviceName != null
            ? "Connected to ${state.deviceName}"
            : "Connected to ESP32";
        subtitle = "Ready to track";
        color = Colors.blue;
        break;
      case BleConnectionState.tracking:
        icon = Icons.bluetooth_connected;
        title = state.deviceName != null
            ? "Connected to ${state.deviceName}"
            : "Connected to ESP32";
        subtitle = "Tracking active (${state.receivedData.length} data points)";
        color = Colors.green;
        break;
      case BleConnectionState.connecting:
        icon = Icons.bluetooth_searching;
        title = "Connecting...";
        subtitle = "Please wait";
        color = Colors.orange;
        break;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: state.isLoading
                  ? SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  : Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BleState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (state.connectionState) {
      case BleConnectionState.bluetoothOff:
        return Column(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                bleCubit.checkStatus();
                print('screen 2');
              },
              icon: const Icon(Icons.bluetooth),
              label: const Text("Check Bluetooth Status"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please enable Bluetooth in your device settings",
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case BleConnectionState.permissionDenied:
        return ElevatedButton.icon(
          onPressed: () {
            bleCubit.checkStatus();
            print('screen 3');
          },
          icon: const Icon(Icons.refresh),
          label: const Text("Retry Permissions"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        );

      case BleConnectionState.disconnected:
        return Column(
          children: [
            ElevatedButton.icon(
              onPressed: () => bleCubit.checkForDevices(),
              icon: const Icon(Icons.refresh),
              label: const Text("Check for Connected Devices"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "How to connect:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "1. Go to your device's Bluetooth settings\n2. Pair with your ESP32 device\n3. Come back and tap 'Check for Connected Devices'",
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
          ],
        );

      case BleConnectionState.connected:
        return Column(
          children: [
            ElevatedButton.icon(
              onPressed: () => bleCubit.startTracking(),
              icon: const Icon(Icons.play_arrow),
              label: const Text("Start Tracking"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => bleCubit.disconnect(),
              icon: const Icon(Icons.bluetooth_disabled),
              label: const Text("Disconnect"),
            ),
          ],
        );

      case BleConnectionState.tracking:
        return Column(
          children: [
            ElevatedButton.icon(
              onPressed: () => bleCubit.stopTracking(),
              icon: const Icon(Icons.stop),
              label: const Text("Stop Tracking"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => bleCubit.disconnect(),
              icon: const Icon(Icons.bluetooth_disabled),
              label: const Text("Disconnect"),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDataList(BleState state) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Received Data",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${state.receivedData.length}",
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: state.receivedData.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.data_usage_outlined,
                        size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text("No data received yet..."),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: state.receivedData.length,
                itemBuilder: (context, index) {
                  final BleData item = state.receivedData[index];
                  return ListTile(
                    leading: const Icon(Icons.bluetooth, color: Colors.blue),
                    title: Text(
                      item.data,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      item.timestamp.toLocal().toString(),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
