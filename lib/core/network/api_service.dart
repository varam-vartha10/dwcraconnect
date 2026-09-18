import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Development URL (Android Emulator)
  static const String devBaseUrl = 'http://10.0.2.2:5000/api';
  
  // Production URL - Replace with your actual deployed domain
  static const String prodBaseUrl = 'https://api.dwcraconnect.com/api';

  // Toggle this for production
  static const bool isProduction = false;

  static String get baseUrl => isProduction ? prodBaseUrl : devBaseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (kDebugMode) {
      print('API Response: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(data['message'] ?? 'API request failed');
  }
}
