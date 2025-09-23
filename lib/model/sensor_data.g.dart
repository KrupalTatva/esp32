// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SensorData _$SensorDataFromJson(Map<String, dynamic> json) => SensorData(
  id: (json['id'] as num?)?.toInt(),
  temperature: (json['temperature'] as num).toDouble(),
  humidity: (json['humidity'] as num).toDouble(),
  pressure: (json['pressure'] as num).toDouble(),
  timestamp: DateTime.parse(json['timestamp'] as String),
  deviceId: json['deviceId'] as String,
);

Map<String, dynamic> _$SensorDataToJson(SensorData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'temperature': instance.temperature,
      'humidity': instance.humidity,
      'pressure': instance.pressure,
      'timestamp': instance.timestamp.toIso8601String(),
      'deviceId': instance.deviceId,
    };
