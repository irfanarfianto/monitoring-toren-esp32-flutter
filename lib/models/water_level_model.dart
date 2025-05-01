class WaterLevel {
  final double distanceCm;
  final double levelCm;
  final double percent;
  final DateTime createdAt;

  WaterLevel({
    required this.distanceCm,
    required this.levelCm,
    required this.percent,
    required this.createdAt,
  });

  factory WaterLevel.fromJson(Map<String, dynamic> json) {
    return WaterLevel(
      distanceCm: (json['distance_cm'] ?? 0).toDouble(),
      levelCm: (json['level_cm'] ?? 0).toDouble(),
      percent: (json['percent'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'distance_cm': distanceCm,
      'level_cm': levelCm,
      'percent': percent,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
