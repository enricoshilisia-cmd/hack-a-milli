import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/auth_response.dart';
import '../models/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  String? _token;
  User? _user;
  final AuthService _authService = AuthService();

  String? get token => _token;
  User? get user => _user;
  bool get isAuthenticated => _token != null;

  Future<void> login(String email, String password) async {
    try {
      final authResponse = await _authService.login(email, password);
      _token = authResponse.token;
      _user = authResponse.user;
      // Fetch profile data after login to get profile_image
      await _fetchUserProfile();
      notifyListeners();
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<void> _fetchUserProfile() async {
    if (_token == null || _user == null) {
      print('Cannot fetch profile: No token or user available');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.skillproof.me.ke/api/users/profile/'),
        headers: {'Authorization': 'Token $_token'},
      );
      if (response.statusCode == 200) {
        final profileData = jsonDecode(response.body);
        final userData = {
          'email': profileData['user']['email'],
          'first_name': profileData['user']['first_name'],
          'last_name': profileData['user']['last_name'],
          'phone_number': profileData['user']['phone_number'],
          'role': _user?.role,
          'is_verified': _user?.isVerified,
          'university_name': profileData['university_name'],
          'graduation_year': profileData['graduation_year'],
          'skills': profileData['skills'],
          'profile_image': profileData['profile_image'] != null
              ? 'https://api.skillproof.me.ke${profileData['profile_image']}'
              : null,
        };
        _user = User.fromJson(userData);
        print('Fetched user profile with profileImageUrl: ${_user?.profileImageUrl}');
        notifyListeners();
      } else {
        print('Profile fetch failed: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    notifyListeners();
  }

  void updateUser(User newUser) {
    _user = User(
      email: newUser.email,
      firstName: newUser.firstName,
      lastName: newUser.lastName,
      phoneNumber: newUser.phoneNumber,
      role: newUser.role,
      isVerified: newUser.isVerified,
      universityName: newUser.universityName,
      graduationYear: newUser.graduationYear,
      skills: newUser.skills,
      profileImageUrl: newUser.profileImageUrl,
    );
    print('Updated user with profileImageUrl: ${_user?.profileImageUrl}');
    notifyListeners();
  }
}