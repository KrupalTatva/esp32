import 'package:esp/base/base_state.dart';
import 'package:esp/bloc/state/device_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../service/preference_service.dart';
import '../state/auth_state.dart';
import '../state/dashboard_state.dart';

class DashboardCubit extends Cubit<BaseState> {
  DashboardCubit() : super(BaseInitState());

  Future<void> logout() async {
    await PrefsService.clearAuth();
    emit(LogOutState());
  }

  /// Mock method to simulate fetching battery level from Bluetooth service
  Future<void> getBatteryLevel() async {
    try {
      emit(LoadingState());

      // simulate async call to Bluetooth service
      await Future.delayed(const Duration(seconds: 2));

      // mock battery value
      final battery = 76;

      emit(DeviceState(batteryLevel: battery));
    } catch (e) {
      emit(ErrorState(errorMessage: e.toString()));
    }
  }

  /// Optionally refresh device info
  Future<void> refreshDeviceInfo() async {
    emit(DeviceState(deviceName: "ESP32-WaterTracker", deviceId: "AA:BB:CC:DD:EE:FF"));
  }
}