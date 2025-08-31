import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/auth_response.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _api.post(
        'users/login/',
        {'email': email, 'password': password},
        token: null,
      );

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Invalid credentials');
      } else if (response.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('Network error: Unable to connect to the server.');
      }
      rethrow;
    }
  }
}