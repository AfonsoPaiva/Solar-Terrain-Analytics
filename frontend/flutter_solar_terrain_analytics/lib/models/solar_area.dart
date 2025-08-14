import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class SolarArea {
  final int? id;
  final String name;
  final List<LatLng> polygon;
  final double totalArea; // in square meters
  final double averageSolarPotential;
  final Map<String, dynamic> detailedAnalysis;
  final String? userId;
  final DateTime? createdAt;

  SolarArea({
    this.id,
    required this.name,
    required this.polygon,
    required this.totalArea,
    required this.averageSolarPotential,
    required this.detailedAnalysis,
    this.userId,
    this.createdAt,
  });

  factory SolarArea.fromJson(Map<String, dynamic> json) {
    return SolarArea(
      id: json['id'] as int?,
      name: json['name'] as String,
      polygon: (json['polygon'] as List)
          .map((point) => LatLng(point['lat'], point['lng']))
          .toList(),
      totalArea: (json['totalArea'] as num).toDouble(),
      averageSolarPotential: (json['averageSolarPotential'] as num).toDouble(),
      detailedAnalysis: json['detailedAnalysis'] as Map<String, dynamic>,
      userId: json['userId'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'polygon': polygon.map((point) => {'lat': point.latitude, 'lng': point.longitude}).toList(),
      'totalArea': totalArea,
      'averageSolarPotential': averageSolarPotential,
      'detailedAnalysis': detailedAnalysis,
      'userId': userId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Calculate center point for display
  LatLng get center {
    double lat = polygon.map((p) => p.latitude).reduce((a, b) => a + b) / polygon.length;
    double lng = polygon.map((p) => p.longitude).reduce((a, b) => a + b) / polygon.length;
    return LatLng(lat, lng);
  }

  // Get bounds for the polygon
  LatLngBounds get bounds {
    double minLat = polygon.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat = polygon.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    double minLng = polygon.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng = polygon.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
    
    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }
}
