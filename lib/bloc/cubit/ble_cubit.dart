import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:esp/base/base_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../model/ble_model.dart';
import '../../service/bluetooth_background_worker.dart';
import '../../service/bluetooth_service.dart';
import '../state/ble_state.dart';

class BleCubit extends Cubit<BleState> {
  final BluetoothService _bluetoothService = BluetoothService.instance;
  late StreamSubscription<BleConnectionState> _connectionSubscription;
  late StreamSubscription<List<BleData>> _dataSubscription;
  late StreamSubscription<String?> _errorSubscription;
  ReceivePort? _receivePort;

  BleCubit() : super(const BleState(connectionState: BleConnectionState.checking)) {
    _setupServiceListeners();
    _setupIsolateListener();
  }

  void _setupServiceListeners() {
    _connectionSubscription = _bluetoothService.connectionState.listen(
          (connectionState) {
        final deviceName = _bluetoothService.connectedDevice?.platformName ??
            _bluetoothService.connectedDevice?.advName;
        emit(state.copyWith(
          connectionState: connectionState,
          isLoading: false,
          deviceName: deviceName,
        ));
      },
    );

    _dataSubscription = _bluetoothService.dataStream.listen(
          (data) => emit(state.copyWith(receivedData: data)),
    );

    _errorSubscription = _bluetoothService.errorStream.listen(
          (error) {
        if (error != null) {
          emit(state.copyWith(errorMessage: error, isLoading: false));
        }
      },
    );
  }

  void _setupIsolateListener() {
    _receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(_receivePort!.sendPort, 'ble_data_port');

    _receivePort!.listen((data) {
      if (data is Map && data['type'] == 'data') {
        // Handle background data updates if needed
      }
    });
  }

  Future<void> initialize() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final currentData = _bluetoothService.getCurrentData();
      emit(state.copyWith(
        receivedData: currentData,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: "Failed to initialize: $e",
        isLoading: false,
      ));
    }
  }

  Future<void> checkStatus() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    await _bluetoothService.checkBluetoothStatus();
    print('cubit 1');
  }

  Future<void> checkForDevices() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    await _bluetoothService.checkForConnectedDevices();
  }

  Future<void> startTracking() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final success = await _bluetoothService.startTracking();
    if (success) {
      await BackgroundWorker.startBackgroundTask();
    }
  }

  Future<void> stopTracking() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final success = await _bluetoothService.stopTracking();
    if (success) {
      await BackgroundWorker.stopBackgroundTask();
    }
  }

  Future<void> disconnect() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    await BackgroundWorker.stopBackgroundTask();
    await _bluetoothService.disconnect();
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  @override
  Future<void> close() {
    _connectionSubscription.cancel();
    _dataSubscription.cancel();
    _errorSubscription.cancel();
    _receivePort?.close();
    IsolateNameServer.removePortNameMapping('ble_data_port');
    return super.close();
  }
}