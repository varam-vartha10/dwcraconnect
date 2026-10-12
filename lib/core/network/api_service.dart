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

  // GET request with automatic transient retry for Render cold-start
  static Future<Map<String, dynamic>> get(String endpoint) async {
    return _executeWithRetry(() async {
      final stopwatch = Stopwatch()..start();
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 25));

      stopwatch.stop();
      if (kDebugMode) {
        print('--- API GET [${response.statusCode}] $url (${stopwatch.elapsedMilliseconds}ms) ---');
      }

      return _handleResponse(response);
    });
  }

  // POST request with automatic transient retry for cold-start
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    return _executeWithRetry(() async {
      final stopwatch = Stopwatch()..start();
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 25));

      stopwatch.stop();
      if (kDebugMode) {
        print('--- API POST [${response.statusCode}] $url (${stopwatch.elapsedMilliseconds}ms) ---');
      }

      return _handleResponse(response);
    });
  }

  // PATCH request
  static Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> body) async {
    return _executeWithRetry(() async {
      final stopwatch = Stopwatch()..start();
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 25));

      stopwatch.stop();
      if (kDebugMode) {
        print('--- API PATCH [${response.statusCode}] $url (${stopwatch.elapsedMilliseconds}ms) ---');
      }

      return _handleResponse(response);
    });
  }

  // Executes an API operation with 1 automatic retry on transient connection timeouts / socket errors
  static Future<Map<String, dynamic>> _executeWithRetry(
    Future<Map<String, dynamic>> Function() action,
  ) async {
    int attempts = 0;
    while (true) {
      attempts++;
      try {
        return await action();
      } on TimeoutException {
        if (attempts >= 2) {
          throw Exception('Server took too long to respond. Please check your internet connection.');
        }
        await Future.delayed(const Duration(milliseconds: 1000));
      } on SocketException catch (e) {
        if (e.message.contains('Permission denied') || e.osError?.errorCode == 13) {
          throw Exception('Network permission denied. Please grant internet permission.');
        }
        if (attempts >= 2) {
          throw Exception('Unable to connect to server. Please check your internet connection.');
        }
        await Future.delayed(const Duration(milliseconds: 1000));
      } on http.ClientException {
        if (attempts >= 2) {
          throw Exception('Server unavailable. Please try again later.');
        }
        await Future.delayed(const Duration(milliseconds: 1000));
      } catch (e) {
        // HTTP 401, 400, 403, 500 exceptions rethrow immediately without retrying!
        rethrow;
      }
    }
  }

  // Handle API response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Map<String, dynamic>.from(data);
      }

      if (response.statusCode == 401) {
        throw Exception(data['message'] ?? 'Invalid phone number or password.');
      }

      if (response.statusCode == 403) {
        throw Exception(data['message'] ?? 'You are not authorized to perform this action.');
      }

      if (response.statusCode == 404) {
        throw Exception(data['message'] ?? 'Service endpoint not found.');
      }

      if (response.statusCode >= 500) {
        throw Exception(data['message'] ?? 'Server error. Please try again later.');
      }

      throw Exception(data['message'] ?? 'API request failed');
    } catch (e) {
      if (e.toString().contains('Exception: ')) rethrow;
      throw Exception('Server error. Invalid response received.');
    }
  }
}
