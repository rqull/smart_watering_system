class PlantData {
  final double moisture;
  final DateTime timestamp;
  final bool isPumpOn;

  PlantData({
    required this.moisture,
    required this.timestamp,
    required this.isPumpOn,
  });

  Map<String, dynamic> toJson() => {
        'moisture': moisture,
        'timestamp': timestamp.toIso8601String(),
        'isPumpOn': isPumpOn,
      };

  factory PlantData.fromJson(Map<String, dynamic> json) => PlantData(
        moisture: json['moisture'].toDouble(),
        timestamp: DateTime.parse(json['timestamp']),
        isPumpOn: json['isPumpOn'],
      );
}
