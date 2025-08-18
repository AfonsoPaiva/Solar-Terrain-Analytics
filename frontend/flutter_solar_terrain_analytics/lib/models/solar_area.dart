import 'package:latlong2/latlong.dart';

class SolarArea {
  final String id;
  final String name;
  final List<LatLng> coordinates;
  final double area;
  final double solarPotential;
  final double? estimatedOutput;
  final double? savingsPerYear;
  final double? co2Reduction;
  final double? paybackPeriod;
  final String? userId;
  final DateTime? createdAt;

  SolarArea({
    required this.id,
    required this.name,
    required this.coordinates,
    required this.area,
    required this.solarPotential,
    this.estimatedOutput,
    this.savingsPerYear,
    this.co2Reduction,
    this.paybackPeriod,
    this.userId,
    this.createdAt,
  });

  factory SolarArea.fromJson(Map<String, dynamic> json) {
    var coordinatesJson = json['coordinates'] as List?;
    List<LatLng> coords = [];
    
    if (coordinatesJson != null) {
      coords = coordinatesJson.map((point) {
        if (point is Map) {
          double lat = (point['lat'] ?? point['latitude'] ?? 0.0).toDouble();
          double lng = (point['lng'] ?? point['longitude'] ?? 0.0).toDouble();
          return LatLng(lat, lng);
        }
        return LatLng(0.0, 0.0);
      }).toList();
    }

    return SolarArea(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      coordinates: coords,
      area: (json['area'] ?? json['totalArea'] ?? 0.0).toDouble(),
      solarPotential: (json['solarPotential'] ?? json['averageSolarPotential'] ?? 0.0).toDouble(),
      estimatedOutput: (json['estimatedOutput'] as num?)?.toDouble(),
      savingsPerYear: (json['savingsPerYear'] as num?)?.toDouble(),
      co2Reduction: (json['co2Reduction'] as num?)?.toDouble(),
      paybackPeriod: (json['paybackPeriod'] as num?)?.toDouble(),
      userId: json['userId'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'coordinates': coordinates.map((point) => {
        'lat': point.latitude,
        'lng': point.longitude
      }).toList(),
      'area': area,
      'solarPotential': solarPotential,
      'estimatedOutput': estimatedOutput,
      'savingsPerYear': savingsPerYear,
      'co2Reduction': co2Reduction,
      'paybackPeriod': paybackPeriod,
      'userId': userId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  LatLng get center {
    if (coordinates.isEmpty) return LatLng(0, 0);
    
    double lat = coordinates.map((p) => p.latitude).reduce((a, b) => a + b) / coordinates.length;
    double lng = coordinates.map((p) => p.longitude).reduce((a, b) => a + b) / coordinates.length;
    return LatLng(lat, lng);
  }
}
