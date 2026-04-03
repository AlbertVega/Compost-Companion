import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:compost_companion/core/config/api_config.dart';
import 'package:compost_companion/data/models/ingredient.dart';
import 'package:compost_companion/data/services/auth_service.dart';

class IngredientService {
  final String baseUrl;
  final AuthService _auth;

  IngredientService({this.baseUrl = ApiConfig.baseUrl, AuthService? auth})
      : _auth = auth ?? AuthService();

  Future<Ingredient> createIngredient({
    required String name,
    required double moistureContent,
    required double nitrogenContent,
    required double carbonContent,
  }) async {
    final token = _auth.currentToken?.accessToken;
    final uri = Uri.parse('$baseUrl/ingredients');

    final resp = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'name': name,
            'moisture_content': moistureContent,
            'nitrogen_content': nitrogenContent,
            'carbon_content': carbonContent,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) {
        return Ingredient.fromJson(decoded);
      }
      throw Exception('Invalid ingredient response');
    }

    String message = 'Failed to create ingredient';
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map && decoded['detail'] != null) {
        message = decoded['detail'].toString();
      }
    } catch (_) {}
    throw Exception(message);
  }
}
