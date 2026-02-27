import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:compost_companion/data/models/compost_pile.dart';
import 'package:compost_companion/data/services/auth_service.dart';

class CompostService {
  final String baseUrl;
  final AuthService _auth;

  CompostService({this.baseUrl = 'http://127.0.0.1:8000', AuthService? auth})
      : _auth = auth ?? AuthService();

  Future<List<CompostPile>> fetchMyPiles() async {
    final token = _auth.currentToken?.accessToken;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    final uri = Uri.parse('$baseUrl/compost-piles/me');
    final resp = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (resp.statusCode == 200) {
      final List<dynamic> body = jsonDecode(resp.body) as List<dynamic>;
      return body
          .map((e) => CompostPile.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    String message = 'Failed to load piles';
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map && decoded['detail'] != null) {
        message = decoded['detail'].toString();
      }
    } catch (_) {}
    throw Exception(message);
  }
}
