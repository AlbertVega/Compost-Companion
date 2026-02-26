import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:compost_companion/data/models/user_create.dart';

class AuthService {
  final String baseUrl;

  const AuthService({this.baseUrl = 'http://127.0.0.1:8000'});

  Future<void> registerUser(UserCreate user) async {
    final uri = Uri.parse('$baseUrl/users/register');

    try {
      final resp = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 201) {
        return;
      }

      String message = 'Unknown error';
      try {
        final body = jsonDecode(resp.body);
        if (body is Map && body['detail'] != null) {
          message = body['detail'].toString();
        } else {
          message = resp.body;
        }
      } catch (_) {
        message = resp.body;
      }

      throw Exception(message);
    } on TimeoutException {
      throw Exception('Request timed out — please check the backend or network');
    } catch (e) {
      rethrow;
    }
  }
}
