import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/saved_site.dart';
import '../models/solar_area.dart';

class ApiService {
  // Use different URLs for web vs mobile
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8081/api';
    } else {
      // For physical device, use your computer's IP address
      // You can also try these alternatives:
      // - Android emulator: 'http://10.0.2.2:8081/api'
      // - iOS simulator: 'http://localhost:8081/api'
      // - Physical device: your computer's local network IP
      return 'http://192.168.1.100:8081/api'; // Update this to your computer's IP
    }
  }
  
  static Future<void> testConnection() async {
    try {
      final testUrl = kIsWeb ? 'http://localhost:8081' : 'http://192.168.1.100:8081';
      print('Testing connection to: $testUrl');
      
      final response = await http.get(
        Uri.parse('$testUrl/api/test'),
        headers: await _getAuthHeaders(),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        print('✅ Backend connection successful');
      } else {
        print('❌ Backend connection failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Backend connection error: $e');
      // Try alternative IP if first fails (for mobile)
      if (!kIsWeb) {
        try {
          print('Trying alternative IP...');
          final response = await http.get(
            Uri.parse('http://10.0.2.2:8081/api/test'),
            headers: await _getAuthHeaders(),
          ).timeout(Duration(seconds: 10));
          
          if (response.statusCode == 200) {
            print('✅ Backend connection successful on alternative IP');
          } else {
            print('❌ Alternative IP also failed: ${response.statusCode}');
          }
        } catch (e2) {
          print('❌ Alternative IP error: $e2');
        }
      }
    }
  }
  
  static Future<Map<String, String>> _getAuthHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      return {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  static Future<Map<String, dynamic>?> getSolarEstimatePolygon(List<LatLng> polygon) async {
    try {
      final points = polygon.map((p) => { 'lat': p.latitude, 'lng': p.longitude }).toList();
      final response = await http.post(
        Uri.parse('$baseUrl/solar/estimate'),
        headers: await _getAuthHeaders(),
        body: json.encode({ 'points': points }),
      );
      
      debugPrint('Solar estimate request: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        debugPrint('Parsed data: $data');
        return data;
      }
      debugPrint('Solar estimate request failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error getting solar estimate: $e');
      return null;
    }
  }

  // Enhanced area analysis with shadow mapping and light production
  static Future<Map<String, dynamic>?> analyzeArea(List<LatLng> polygon) async {
    return getSolarEstimatePolygon(polygon);
  }

  static Future<List<SavedSite>> getSavedSites() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/solar/sites'),
        headers: await _getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> sitesJson = json.decode(response.body);
        return sitesJson.map((json) => SavedSite.fromJson(json)).toList();
      }
      debugPrint('Get saved sites request failed: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error getting saved sites: $e');
      return [];
    }
  }

  static Future<bool> saveSitePolygon(String name, List<LatLng> polygon) async {
    try {
      final points = polygon.map((p) => { 'lat': p.latitude, 'lng': p.longitude }).toList();
      final response = await http.post(
        Uri.parse('$baseUrl/solar/sites'),
        headers: await _getAuthHeaders(),
        body: json.encode({
          'name': name,
          'points': points,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error saving site: $e');
      return false;
    }
  }

  static Future<bool> saveArea(String name, List<LatLng> polygon, Map<String, dynamic> analysis) async {
    return saveSitePolygon(name, polygon);
  }

  static Future<bool> deleteSite(int siteId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/solar/sites/$siteId'),
        headers: await _getAuthHeaders(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting site: $e');
      return false;
    }
  }

  static Future<bool> deleteArea(int areaId) async {
    return deleteSite(areaId);
  }

  // New methods for mobile dashboard compatibility
  static Future<Map<String, dynamic>> estimateSolarPotential(List<LatLng> polygon) async {
    final result = await getSolarEstimatePolygon(polygon);
    return result ?? {};
  }

  static Future<bool> saveSolarArea({
    required String name,
    required List<LatLng> coordinates,
    required Map<String, dynamic> analysisData,
  }) async {
    return saveSitePolygon(name, coordinates);
  }

  static Future<List<SolarArea>> getSavedAreas() async {
    // For now, return empty list since SavedSite and SolarArea are different
    // TODO: Implement proper area-based API endpoints in backend
    return [];
  }

  static Future<bool> deleteSolarArea(String areaId) async {
    final id = int.tryParse(areaId);
    if (id != null) {
      return deleteSite(id);
    }
    return false;
  }
}
