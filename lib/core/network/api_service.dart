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
    final stopwatch = Stopwatch()..start();
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final headers = await _getHeaders();

      if (kDebugMode || kReleaseMode) {
        print('--- API GET REQUEST: $url ---');
      }

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 20));

      stopwatch.stop();

      if (kDebugMode || kReleaseMode) {
        print('--- API GET RESPONSE: $url [Status: ${response.statusCode}, Time: ${stopwatch.elapsedMilliseconds}ms] ---');
      }

      return _handleResponse(response);
    } on TimeoutException {
      stopwatch.stop();
      if (kDebugMode || kReleaseMode) {
        print('API GET Timeout ($url) after ${stopwatch.elapsedMilliseconds} ms');
      }
      throw Exception('Connection is taking too long. Please try again.');
    } on SocketException catch (e) {
      if (kDebugMode || kReleaseMode) {
        print('API GET SocketException ($url): ${e.message}, osError: ${e.osError}');
      }
      if (e.message.contains('Permission denied') || e.osError?.errorCode == 13) {
        throw Exception('Network permission denied. Please grant internet permission.');
      }
      throw Exception('Unable to connect to server. Please check your internet connection.');
    } on http.ClientException catch (e) {
      if (kDebugMode || kReleaseMode) {
        print('API GET ClientException ($url): $e');
      }
      throw Exception('Server unavailable. Please try again later.');
    } catch (e) {
      if (kDebugMode || kReleaseMode) {
        print('API GET Error ($url): $e');
      }
      rethrow;
    }
  }

  // POST request
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final stopwatch = Stopwatch()..start();
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final headers = await _getHeaders();
      
      if (kDebugMode || kReleaseMode) {
        print('--- API POST REQUEST: $url ---');
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 20));

      stopwatch.stop();

      if (kDebugMode || kReleaseMode) {
        print('--- API POST RESPONSE: $url [Status: ${response.statusCode}, Time: ${stopwatch.elapsedMilliseconds}ms] ---');
      }

      return _handleResponse(response);
    } on TimeoutException {
      stopwatch.stop();
      if (kDebugMode || kReleaseMode) {
        print('API POST Timeout ($url) after ${stopwatch.elapsedMilliseconds} ms');
      }
      throw Exception('Connection is taking too long. Please try again.');
    } on SocketException catch (e) {
      if (kDebugMode || kReleaseMode) {
        print('API POST SocketException ($url): ${e.message}, osError: ${e.osError}');
      }
      if (e.message.contains('Permission denied') || e.osError?.errorCode == 13) {
        throw Exception('Network permission denied. Please grant internet permission.');
      }
      throw Exception('Unable to connect to server. Please check your internet connection.');
    } on http.ClientException catch (e) {
      if (kDebugMode || kReleaseMode) {
        print('API POST ClientException ($url): $e');
      }
      throw Exception('Server unavailable. Please try again later.');
    } catch (e) {
      if (kDebugMode || kReleaseMode) {
        print('API POST Error ($url): $e');
      }
      rethrow;
    }
  }

  // PATCH request
  static Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> body) async {
    final stopwatch = Stopwatch()..start();
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final headers = await _getHeaders();

      if (kDebugMode || kReleaseMode) {
        print('--- API PATCH REQUEST: $url ---');
      }

      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 20));

      stopwatch.stop();

      if (kDebugMode || kReleaseMode) {
        print('--- API PATCH RESPONSE: $url [Status: ${response.statusCode}, Time: ${stopwatch.elapsedMilliseconds}ms] ---');
      }

      return _handleResponse(response);
    } on TimeoutException {
      stopwatch.stop();
      if (kDebugMode || kReleaseMode) {
        print('API PATCH Timeout ($url) after ${stopwatch.elapsedMilliseconds} ms');
      }
      throw Exception('Connection is taking too long. Please try again.');
    } on SocketException catch (e) {
      if (kDebugMode || kReleaseMode) {
        print('API PATCH SocketException ($url): ${e.message}, osError: ${e.osError}');
      }
      if (e.message.contains('Permission denied') || e.osError?.errorCode == 13) {
        throw Exception('Network permission denied. Please grant internet permission.');
      }
      throw Exception('Unable to connect to server. Please check your internet connection.');
    } on http.ClientException catch (e) {
      if (kDebugMode || kReleaseMode) {
        print('API PATCH ClientException ($url): $e');
      }
      throw Exception('Server unavailable. Please try again later.');
    } catch (e) {
      if (kDebugMode || kReleaseMode) {
        print('API PATCH Error ($url): $e');
      }
      rethrow;
    }
  }

  // Handle API response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (kDebugMode || kReleaseMode) {
      print('API Response: ${response.statusCode} - ${response.request?.url}');
    }

    try {
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Map<String, dynamic>.from(data);
      }

      if (response.statusCode == 401) {
        throw Exception(data['message'] ?? 'Invalid credentials or session expired.');
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
