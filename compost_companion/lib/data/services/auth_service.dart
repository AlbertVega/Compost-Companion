import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:compost_companion/data/models/user_create.dart';
import 'package:compost_companion/data/models/token_response.dart';

/// A very lightweight singleton for authentication state.  All callers
/// using `AuthService()` will share the same instance and therefore the
/// same stored token.  This avoids the "no authentication token available"
/// error when the service is recreated later (e.g. in `CompostService`).
class AuthService {
  static final AuthService _instance = AuthService._internal();

  /// You can override the base URL on first access if needed; afterwards
  /// it will be ignored.
  late String baseUrl;

  TokenResponse? _token;

  factory AuthService({String baseUrl = 'http://127.0.0.1:8000'}) {
    _instance.baseUrl = baseUrl;
    return _instance;
  }

  AuthService._internal() {
    baseUrl = 'http://127.0.0.1:8000';
  }

  TokenResponse? get currentToken => _token;

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

  /// Returns a parsed [TokenResponse] on success.
  Future<TokenResponse> login({required String username, required String password}) async {
    final uri = Uri.parse('$baseUrl/users/login');

    try {
      // Sending as form data — http.post will encode a Map<String, String>
      final resp = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': username, 'password': password},
      )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final token = TokenResponse.fromJson(body as Map<String, dynamic>);
        _token = token;
        return token;
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
    }
  }
}
