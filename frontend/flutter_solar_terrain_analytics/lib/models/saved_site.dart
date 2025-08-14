class SavedSite {
  final int? id;
  final double latitude;
  final double longitude;
  final double solarPotential;
  final String? userId;
  final DateTime? createdAt;

  SavedSite({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.solarPotential,
    this.userId,
    this.createdAt,
  });

  factory SavedSite.fromJson(Map<String, dynamic> json) {
    return SavedSite(
      id: json['id'] as int?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      solarPotential: (json['solarPotential'] as num).toDouble(),
      userId: json['userId'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'solarPotential': solarPotential,
      'userId': userId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
