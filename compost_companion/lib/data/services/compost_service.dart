import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:compost_companion/data/models/compost_pile.dart';
import 'package:compost_companion/data/models/dashboard_pile.dart';
import 'package:compost_companion/data/models/ingredient.dart';
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

  /// Fetch all available ingredients from the server.
  Future<List<Ingredient>> fetchIngredients() async {
    final token = _auth.currentToken?.accessToken;
    final uri = Uri.parse('$baseUrl/ingredients');
    final resp = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (resp.statusCode == 200) {
      final List<dynamic> body = jsonDecode(resp.body) as List<dynamic>;
      return body
          .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Failed to load ingredients');
  }

  Future<CompostPile> createCompostPile({
    required String name,
    required double volumeAtCreation,
    required String location,
  }) async {
    final token = _auth.currentToken?.accessToken;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    final uri = Uri.parse('$baseUrl/compost-piles/create');
    final resp = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'name': name,
            'volume_at_creation': volumeAtCreation,
            'location': location,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      return CompostPile.fromJson(body);
    }

    String message = 'Failed to create compost pile';
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map && decoded['detail'] != null) {
        message = decoded['detail'].toString();
      }
    } catch (_) {}
    throw Exception(message);
  }

  Future<Map<String, dynamic>> evaluateRecipe(Map<Ingredient, double> selectedMap, List<Ingredient> availableList) async {
    final uri = Uri.parse('$baseUrl/evaluate-recipe');

    final selectedJson = selectedMap.entries.map((entry) => {
      'name': entry.key.name,
      'weight_kg': entry.value,
      'moisture_content': entry.key.moistureContent ?? 0.0,
      'nitrogen_content': entry.key.nitrogenContent ?? 0.0,
      'carbon_content': entry.key.carbonContent ?? 0.0,
    }).toList();

    final availableJson = availableList.map((i) => {
      'name': i.name,
      'weight_kg': 0.0,
      'moisture_content': i.moistureContent ?? 0.0,
      'nitrogen_content': i.nitrogenContent ?? 0.0,
      'carbon_content': i.carbonContent ?? 0.0,
    }).toList();

    final body = jsonEncode({
      'selected_ingredients': selectedJson,
      'available_ingredients': availableJson,
    });

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      throw Exception('Failed to evaluate recipe: ${resp.body}');
    }
  }
}
