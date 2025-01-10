class PlantState {
  final double moisture;
  final DateTime timestamp;
  final bool isPumpOn;

  PlantState({
    required this.moisture,
    required this.timestamp,
    required this.isPumpOn,
  });

  PlantState copyWith({
    double? moisture,
    DateTime? timestamp,
    bool? isPumpOn,
  }) {
    return PlantState(
      moisture: moisture ?? this.moisture,
      timestamp: timestamp ?? this.timestamp,
      isPumpOn: isPumpOn ?? this.isPumpOn,
    );
  }

  Map<String, dynamic> toJson() => {
        'moisture': moisture,
        'timestamp': timestamp.toIso8601String(),
        'isPumpOn': isPumpOn,
      };

  factory PlantState.fromJson(Map<String, dynamic> json) => PlantState(
        moisture: json['moisture'].toDouble(),
        timestamp: DateTime.parse(json['timestamp']),
        isPumpOn: json['isPumpOn'],
      );

  factory PlantState.initial() => PlantState(
        moisture: 0.0,
        timestamp: DateTime.now(),
        isPumpOn: false,
      );
}
