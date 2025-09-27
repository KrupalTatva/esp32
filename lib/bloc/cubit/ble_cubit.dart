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
  final BluetoothService _service = BluetoothService.instance;

  StreamSubscription<BleConnectionState>? _stateSub;
  StreamSubscription<List<BleData>>? _dataSub;
  StreamSubscription<String?>? _errorSub;

  BleCubit()
      : super(const BleState(connectionState: BleConnectionState.checking)) {
    _setupListeners();
    _initialize();
  }

  // ============================================================
  // Setup Listeners
  // ============================================================
  void _setupListeners() {
    // Listen to connection state
    _stateSub = _service.stateStream.listen((bleState) {
      emit(state.copyWith(
        connectionState: bleState,
        deviceId: _service.deviceId,
        deviceName: _service.deviceName,
        isLoading: false,
      ));
    });

    // Listen to data stream
    _dataSub = _service.dataStream.listen((data) {
      emit(state.copyWith(receivedData: data));
    });

    // Listen to errors
    _errorSub = _service.errorStream.listen((error) {
      if (error != null) {
        emit(state.copyWith(
          errorMessage: error,
          isLoading: false,
        ));
      }
    });
  }

  // ============================================================
  // Initialize - Restore previous state or check Bluetooth
  // ============================================================
  Future<void> _initialize() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      await _service.initialize();

      // Update UI with current device info
      emit(state.copyWith(
        deviceId: _service.deviceId,
        deviceName: _service.deviceName,
        receivedData: _service.currentData,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: "Initialization failed: $e",
        isLoading: false,
      ));
    }
  }

  // ============================================================
  // Check Bluetooth Status (Permissions + Adapter)
  // ============================================================
  Future<void> checkBluetoothStatus() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    await _service.checkBluetoothStatus();
    // State will be updated via stream listener
  }

  // ============================================================
  // Scan and Connect to ESP32
  // ============================================================
  Future<void> scanAndConnect() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final success = await _service.scanAndConnect();

    if (success) {
      emit(state.copyWith(
        deviceId: _service.deviceId,
        deviceName: _service.deviceName,
        isLoading: false,
      ));
    } else {
      emit(state.copyWith(
        errorMessage: "Failed to connect to ESP32",
        isLoading: false,
      ));
    }
  }

  // ============================================================
  // Start Data Tracking
  // ============================================================
  Future<void> startTracking() async {
    if (!state.isConnected) {
      emit(state.copyWith(
        errorMessage: "Device not connected",
        isLoading: false,
      ));
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    final success = await _service.startTracking();

    if (!success) {
      emit(state.copyWith(
        errorMessage: "Failed to start tracking",
        isLoading: false,
      ));
    }
  }

  // ============================================================
  // Stop Data Tracking
  // ============================================================
  Future<void> stopTracking() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final success = await _service.stopTracking();

    if (!success) {
      emit(state.copyWith(
        errorMessage: "Failed to stop tracking",
        isLoading: false,
      ));
    }
  }

  // ============================================================
  // Disconnect from Device
  // ============================================================
  Future<void> disconnect() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    await _service.disconnect();

    emit(state.copyWith(
      clearDeviceInfo: true,
      isLoading: false,
    ));
  }

  // ============================================================
  // Clear Error Message
  // ============================================================
  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  // ============================================================
  // Cleanup
  // ============================================================
  @override
  Future<void> close() {
    _stateSub?.cancel();
    _dataSub?.cancel();
    _errorSub?.cancel();
    return super.close();
  }
}