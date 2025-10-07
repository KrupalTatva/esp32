import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sensor_data.g.dart';

@JsonSerializable()
class SensorData extends Equatable {
  final int? id;
  final double hydrationLevel;
  final DateTime timestamp;

  const SensorData({
    this.id,
    required this.hydrationLevel,
    required this.timestamp
  });

  factory SensorData.fromJson(Map<String, dynamic> json) => _$SensorDataFromJson(json);
  Map<String, dynamic> toJson() => _$SensorDataToJson(this);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hydrationLevel': hydrationLevel,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SensorData.fromMap(Map<String, dynamic> map) {
    return SensorData(
      id: map['id']?.toInt(),
      hydrationLevel: (map['hydrationLevel'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  SensorData copyWith({
    int? id,
    double? hydrationLevel,
    DateTime? timestamp,
  }) {
    return SensorData(
      id: id ?? this.id,
      hydrationLevel: hydrationLevel ?? this.hydrationLevel,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [id, hydrationLevel, timestamp];
}