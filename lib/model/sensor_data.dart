import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sensor_data.g.dart';

@JsonSerializable()
class SensorData extends Equatable {
  final int? id;
  final double temperature;
  final double humidity;
  final double pressure;
  final DateTime timestamp;
  final String deviceId;

  const SensorData({
    this.id,
    required this.temperature,
    required this.humidity,
    required this.pressure,
    required this.timestamp,
    required this.deviceId,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) => _$SensorDataFromJson(json);
  Map<String, dynamic> toJson() => _$SensorDataToJson(this);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'temperature': temperature,
      'humidity': humidity,
      'pressure': pressure,
      'timestamp': timestamp.toIso8601String(),
      'deviceId': deviceId,
    };
  }

  factory SensorData.fromMap(Map<String, dynamic> map) {
    return SensorData(
      id: map['id']?.toInt(),
      temperature: (map['temperature'] ?? 0.0).toDouble(),
      humidity: (map['humidity'] ?? 0.0).toDouble(),
      pressure: (map['pressure'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
      deviceId: map['deviceId'] ?? '',
    );
  }

  SensorData copyWith({
    int? id,
    double? temperature,
    double? humidity,
    double? pressure,
    DateTime? timestamp,
    String? deviceId,
  }) {
    return SensorData(
      id: id ?? this.id,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      pressure: pressure ?? this.pressure,
      timestamp: timestamp ?? this.timestamp,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  @override
  List<Object?> get props => [id, temperature, humidity, pressure, timestamp, deviceId];
}