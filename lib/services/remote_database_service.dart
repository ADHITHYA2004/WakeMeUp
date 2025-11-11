import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;
import '../models/destination.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'auth_service.dart';

class RemoteDatabaseService {
  static final RemoteDatabaseService instance = RemoteDatabaseService._init();
  RemoteDatabaseService._init();

  // Change this to your server base URL
  String baseUrl = 'http://localhost:4000';

  // Resolve base URL based on platform/emulator
  String get resolvedBaseUrl {
    if (kIsWeb) return baseUrl;
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator cannot reach host loopback via localhost
      return baseUrl.replaceFirst('localhost', '10.0.2.2');
    }
    return baseUrl;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.instance.getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<List<Destination>> getAllDestinations() async {
    try {
      final res = await http.get(Uri.parse('$resolvedBaseUrl/api/destinations'), headers: await _authHeaders());
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body) as List<dynamic>;
        return list.map((m) {
          return Destination(
            id: m['id'] as int?,
            name: m['name'] as String,
            latitude: (m['latitude'] as num).toDouble(),
            longitude: (m['longitude'] as num).toDouble(),
            createdAt: DateTime.parse(m['created_at'] as String),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Remote getAllDestinations error: $e');
    }
    return [];
  }

  Future<int> insertDestination(Destination destination) async {
    try {
      final body = jsonEncode({
        'name': destination.name,
        'latitude': destination.latitude,
        'longitude': destination.longitude,
        'created_at': destination.createdAt.toIso8601String(),
      });
      final res = await http.post(
        Uri.parse('$resolvedBaseUrl/api/destinations'),
        headers: await _authHeaders(),
        body: body,
      );
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return (data['id'] as num).toInt();
      }
    } catch (e) {
      debugPrint('Remote insertDestination error: $e');
    }
    return -1;
  }

  Future<bool> deleteDestination(int id) async {
    try {
      final res = await http.delete(Uri.parse('$resolvedBaseUrl/api/destinations/$id'), headers: await _authHeaders());
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Remote deleteDestination error: $e');
      return false;
    }
  }
}
