import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/saved_site.dart';
import '../models/solar_area.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8081/api';
  
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

  static Future<List<SolarArea>> getSavedAreas() async {
    return []; // not implemented on backend yet
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
}
