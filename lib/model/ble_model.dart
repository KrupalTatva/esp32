class BleData {
  final DateTime timestamp;
  final String data;
  final int batteryLevel;

  BleData({
    required this.timestamp,
    required this.data,
    this.batteryLevel = 0,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'data': data,
    'batteryLevel': batteryLevel,
  };

  factory BleData.fromJson(Map<String, dynamic> json) => BleData(
    timestamp: DateTime.parse(json['timestamp']),
    data: json['data'],
    batteryLevel: json['batteryLevel'] ?? 0,
  );

  @override
  String toString() => '${timestamp.toIso8601String()}: $data';
}