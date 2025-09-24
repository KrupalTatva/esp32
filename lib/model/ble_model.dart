class BleData {
  final DateTime timestamp;
  final String data;

  BleData({
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'data': data,
  };

  factory BleData.fromJson(Map<String, dynamic> json) => BleData(
    timestamp: DateTime.parse(json['timestamp']),
    data: json['data'],
  );

  @override
  String toString() => '${timestamp.toIso8601String()}: $data';
}