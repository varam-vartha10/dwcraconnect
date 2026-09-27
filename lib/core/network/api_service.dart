import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Development URL (Android Emulator)
  static const String devBaseUrl = 'http://10.0.2.2:5000/api';

  // Production URL (Render)
  static const String prodBaseUrl = 'https://dwcra-connect-backend.onrender.com/api';

  // Use production backend
  static const bool isProduction = true;

  // Select the backend URL
  static String get baseUrl => isProduction ? prodBaseUrl : devBaseUrl;

  // Simple in-memory cache for the token to improve performance
  static String? _cachedToken;

  static void setToken(String? token) {
    _cachedToken = token;
  }

  static Future<void> clearCache() async {
    _cachedToken = null;
  }

  // Get common headers and attach saved JWT token
  static Future<Map<String, String>> _getHeaders() async {
    if (_cachedToken == null) {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString('auth_token');
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_cachedToken';
    }

    return headers;
  }

  // GET request
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final startTime = DateTime.now();
    final stopwatch = Stopwatch()..start();
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final headers = await _getHeaders();

      if (kDebugMode) {
        print('--- API GET REQUEST START ---');
        print('URL: $url');
        print('Request Start Time: $startTime');
      }

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 20));

      stopwatch.stop();
      final endTime = DateTime.now();

      if (kDebugMode) {
        print('--- API GET RESPONSE END ---');
        print('URL: $url');
        print('HTTP status: ${response.statusCode}');
        print('Request Start Time: $startTime');
        print('Request End Time: $endTime');
        print('Elapsed ms: ${stopwatch.elapsedMilliseconds}');
      }

      return _handleResponse(response);
    } on TimeoutException {
      stopwatch.stop();
      if (kDebugMode) {
        print('API GET Timeout ($url) after ${stopwatch.elapsedMilliseconds} ms');
      }
      throw Exception('Connection is taking too long. Please try again.');
    } on SocketException {
      if (kDebugMode) print('No internet connection to $baseUrl');
      throw Exception('No internet connection');
    } on http.ClientException {
      if (kDebugMode) print('Server unavailable at $baseUrl');
      throw Exception('Server unavailable');
    } catch (e) {
      if (kDebugMode) print('API GET Error: $e');
      rethrow;
    }
  }

  // POST request
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final startTime = DateTime.now();
    final stopwatch = Stopwatch()..start();
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final headers = await _getHeaders();
      
      if (kDebugMode) {
        print('--- API POST REQUEST START ---');
        print('URL: $url');
        print('Request Start Time: $startTime');
        if (endpoint.contains('login')) {
          print('Phone: ${body['phoneNumber']}');
        }
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 20));

      stopwatch.stop();
      final endTime = DateTime.now();

      if (kDebugMode) {
        print('--- API POST RESPONSE END ---');
        print('URL: $url');
        print('HTTP status: ${response.statusCode}');
        print('Request Start Time: $startTime');
        print('Request End Time: $endTime');
        print('Elapsed ms: ${stopwatch.elapsedMilliseconds}');
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('message')) {
            print('Response Message: ${decoded['message']}');
          }
        } catch (_) {}
      }

      return _handleResponse(response);
    } on TimeoutException {
      stopwatch.stop();
      if (kDebugMode) {
        print('API POST Timeout ($url) after ${stopwatch.elapsedMilliseconds} ms');
      }
      throw Exception('Connection is taking too long. Please try again.');
    } on SocketException {
      if (kDebugMode) print('No internet connection to $baseUrl');
      throw Exception('No internet connection');
    } catch (e) {
      if (kDebugMode) print('API POST Error: $e');
      rethrow;
    }
  }

  // PATCH request
  static Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> body) async {
    final startTime = DateTime.now();
    final stopwatch = Stopwatch()..start();
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final headers = await _getHeaders();

      if (kDebugMode) {
        print('--- API PATCH REQUEST START ---');
        print('URL: $url');
        print('Request Start Time: $startTime');
      }

      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 20));

      stopwatch.stop();
      final endTime = DateTime.now();

      if (kDebugMode) {
        print('--- API PATCH RESPONSE END ---');
        print('URL: $url');
        print('HTTP status: ${response.statusCode}');
        print('Request Start Time: $startTime');
        print('Request End Time: $endTime');
        print('Elapsed ms: ${stopwatch.elapsedMilliseconds}');
      }

      return _handleResponse(response);
    } on TimeoutException {
      stopwatch.stop();
      if (kDebugMode) {
        print('API PATCH Timeout ($url) after ${stopwatch.elapsedMilliseconds} ms');
      }
      throw Exception('Connection is taking too long. Please try again.');
    } on SocketException {
      if (kDebugMode) print('No internet connection to $baseUrl');
      throw Exception('No internet connection');
    } catch (e) {
      if (kDebugMode) print('API PATCH Error: $e');
      rethrow;
    }
  }

  // Handle API response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (kDebugMode) {
      print('API Response: ${response.statusCode} - ${response.request?.url}');
    }

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data);
    }

    if (response.statusCode == 401) {
      throw Exception(data['message'] ?? 'Session expired. Please login again.');
    }

    throw Exception(data['message'] ?? 'API request failed');
  }
}
