import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'https://api.skillproof.me.ke/api';

  Future<http.Response> post(String endpoint, dynamic data, {String? token}) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };

    print('POST Request to: $url');
    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(data),
    );
    print('POST Response: ${response.statusCode} ${response.body}');
    return response;
  }

  Future<http.Response> get(String endpoint, String token) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token',
    };
    print('GET Request to: $url');
    final response = await http.get(url, headers: headers);
    print('GET Response: ${response.statusCode} ${response.body}');
    return response;
  }

  Future<Map<String, dynamic>> getUserProfile(String token) async {
    const endpoint = 'users/profile/';
    final url = Uri.parse('$baseUrl/$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token',
    };
    print('GET Request to: $url');
    final response = await http.get(url, headers: headers);
    print('GET Response: ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load profile data: ${response.statusCode} ${response.body}');
  }

  Future<http.Response> putMultipart(
    String endpoint,
    String token, {
    required Map<String, String> fields,
    List<http.MultipartFile>? files,
  }) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final request = http.MultipartRequest('PUT', url)
      ..headers['Authorization'] = 'Token $token'
      ..fields.addAll(fields);

    if (files != null) {
      request.files.addAll(files);
    }

    print('Multipart PUT Request to: $url');
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    print('Multipart PUT Response: ${response.statusCode} ${response.body}');
    return response;
  }

  Future<http.Response> postMultipart(
    String endpoint,
    String token, {
    required Map<String, String> fields,
    List<http.MultipartFile>? files,
  }) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Token $token'
      ..fields.addAll(fields);

    if (files != null) {
      request.files.addAll(files);
    }

    print('Multipart POST Request to: $url');
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    print('Multipart POST Response: ${response.statusCode} ${response.body}');
    return response;
  }

  Future<http.Response> register(String role, Map<String, dynamic> data) async {
    final endpoint = role == 'student' ? 'users/register/student/' : 'users/register/graduate/';
    final url = Uri.parse('$baseUrl/$endpoint');
    final headers = {'Content-Type': 'application/json'};

    print('Register POST Request to: $url');
    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(data),
    );
    print('Register POST Response: ${response.statusCode} ${response.body}');
    return response;
  }

  Future<List<Map<String, dynamic>>> searchCategories(String query) async {
    final url = Uri.parse('$baseUrl/companies/categories/search/?q=$query');
    final headers = {'Content-Type': 'application/json'};
    print('GET Request to: $url');
    try {
      final response = await http.get(url, headers: headers);
      print('GET Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['categories']);
      } else {
        print('Error: Failed to fetch categories, status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception in searchCategories: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchUniversities(String query) async {
    final url = Uri.parse('$baseUrl/universities/search/?q=$query');
    final headers = {'Content-Type': 'application/json'};
    print('GET Request to: $url');
    try {
      final response = await http.get(url, headers: headers);
      print('GET Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['universities'] == null) {
          print('Error: No "universities" key in response');
          return [];
        }
        return List<Map<String, dynamic>>.from(data['universities']);
      } else {
        print('Error: Failed to fetch universities, status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception in searchUniversities: $e');
      return [];
    }
  }
}