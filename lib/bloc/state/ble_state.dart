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
  final List<BleData> receivedData;
  final String? errorMessage;
  final bool isLoading;
  final String? deviceName;

  const BleState({
    required this.connectionState,
    this.receivedData = const [],
    this.errorMessage,
    this.isLoading = false,
    this.deviceName,
  });

  BleState copyWith({
    BleConnectionState? connectionState,
    List<BleData>? receivedData,
    String? errorMessage,
    bool? isLoading,
    String? deviceName,
    bool clearError = false,
  }) {
    return BleState(
      connectionState: connectionState ?? this.connectionState,
      receivedData: receivedData ?? this.receivedData,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
      deviceName: deviceName ?? this.deviceName,
    );
  }

  @override
  List<Object?> get props => [connectionState, receivedData, errorMessage, isLoading, deviceName];
}
