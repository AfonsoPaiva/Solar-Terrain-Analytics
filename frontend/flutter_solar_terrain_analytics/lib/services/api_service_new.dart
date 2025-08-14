import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/saved_site.dart';

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

  static Future<Map<String, dynamic>?> getSolarEstimate(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/solar/estimate?lat=$lat&lng=$lng'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      debugPrint('Solar estimate request failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error getting solar estimate: $e');
      return null;
    }
  }

  static Future<List<SavedSite>> getSavedSites() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/saved-sites'),
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

  static Future<bool> saveSite(double lat, double lng, double solarPotential) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/saved-sites'),
        headers: await _getAuthHeaders(),
        body: json.encode({
          'latitude': lat,
          'longitude': lng,
          'solarPotential': solarPotential,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error saving site: $e');
      return false;
    }
  }

  static Future<bool> deleteSite(int siteId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/saved-sites/$siteId'),
        headers: await _getAuthHeaders(),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting site: $e');
      return false;
    }
  }
}
