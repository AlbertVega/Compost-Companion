import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:compost_companion/data/models/compost_pile.dart';
import 'package:compost_companion/data/models/dashboard_pile.dart';
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

  /// Fetch the most recent health record for a given pile.
  ///
  /// Returns `null` when the server responds with 404 (no records yet).
  Future<HealthRecord?> fetchLatestHealthRecord(int pileId) async {
    final token = _auth.currentToken?.accessToken;
    if (token == null) {
      throw Exception('No authentication token available');
    }
    final uri = Uri.parse('$baseUrl/compost-piles/$pileId/health-records/latest');
    final resp = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      return HealthRecord.fromJson(body);
    }

    if (resp.statusCode == 404) {
      // no records yet
      return null;
    }

    String message = 'Failed to load health record';
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map && decoded['detail'] != null) {
        message = decoded['detail'].toString();
      } else {
        message = resp.body;
      }
    } catch (_) {}
    throw Exception(message);
  }

  /// Combines pile list and their latest health data.
  Future<List<DashboardPile>> fetchDashboardData() async {
    final piles = await fetchMyPiles();
    final List<DashboardPile> result = [];
    for (final p in piles) {
      HealthRecord? hr;
      String? err;
      try {
        hr = await fetchLatestHealthRecord(p.id);
      } catch (e) {
        // if fetching the health record fails for reasons other than 404,
        // capture the message so the UI can display a non-blocking error.
        err = e.toString();
      }
      result.add(DashboardPile(
        id: p.id,
        name: p.name,
        latestRecord: hr,
        error: err,
      ));
    }
    return result;
  }
}
