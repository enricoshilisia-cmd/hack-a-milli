import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart';
import 'profile_update_screen.dart';
import '../models/user.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({Key? key}) : super(key: key);

  @override
  _MyAccountScreenState createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  double _totalScore = 0;
  String _badgeLevel = 'None';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('No token available');
      }

      // Fetch total score
      final scoreResponse = await http.get(
        Uri.parse('https://api.skillproof.me.ke/api/companies/student/results/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (scoreResponse.statusCode == 200) {
        final submissions = jsonDecode(scoreResponse.body) as List;
        final total = submissions.fold<double>(
            0, (sum, submission) => sum + (submission['score'] ?? 0));
        setState(() => _totalScore = total);
      }

      // Fetch badges
      final badgeResponse = await http.get(
        Uri.parse('https://api.skillproof.me.ke/api/badges/my-badges/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (badgeResponse.statusCode == 200) {
        final badges = jsonDecode(badgeResponse.body) as List;
        final badgeNames = badges.map((b) => b['badge']['name'] as String).toList();
        if (badgeNames.contains('Expert')) {
          setState(() => _badgeLevel = 'Expert');
        } else if (badgeNames.contains('Intermediate')) {
          setState(() => _badgeLevel = 'Intermediate');
        } else if (badgeNames.contains('Beginner')) {
          setState(() => _badgeLevel = 'Beginner');
        }
      }

      // Fetch profile data
      final profileResponse = await http.get(
        Uri.parse('https://api.skillproof.me.ke/api/users/profile/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body);
        print('Profile response: ${profileResponse.body}');
        final userData = {
          'email': profileData['user']['email'],
          'first_name': profileData['user']['first_name'],
          'last_name': profileData['user']['last_name'],
          'phone_number': profileData['user']['phone_number'],
          'role': authProvider.user?.role,
          'is_verified': authProvider.user?.isVerified,
          'university_name': profileData['university_name'],
          'graduation_year': profileData['graduation_year'],
          'skills': profileData['skills'],
          'profile_image': profileData['profile_image'] != null
              ? 'https://api.skillproof.me.ke${profileData['profile_image']}'
              : null,
        };
        authProvider.updateUser(User.fromJson(userData));
        print('User profileImageUrl set to: ${userData['profile_image']}');
      } else {
        print('Profile request failed: ${profileResponse.statusCode}, ${profileResponse.body}');
      }
    } catch (e) {
      print('Error loading data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    print('Building MyAccountScreen with profileImageUrl: ${user?.profileImageUrl}');

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Card(
                    elevation: 4,
                    shape: Theme.of(context).cardTheme.shape, // Use theme's shape for outline in dark mode
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: user?.profileImageUrl != null
                                ? Colors.transparent
                                : Colors.blue.shade100,
                            backgroundImage: user?.profileImageUrl != null
                                ? NetworkImage(user!.profileImageUrl!)
                                : null,
                            onBackgroundImageError: user?.profileImageUrl != null
                                ? (error, stackTrace) {
                                    print('Image load error: $error, URL: ${user!.profileImageUrl}');
                                    setState(() {
                                      // Clear invalid URL and fall back to initials
                                      authProvider.updateUser(User(
                                        email: user!.email,
                                        firstName: user.firstName,
                                        lastName: user.lastName,
                                        phoneNumber: user.phoneNumber,
                                        role: user.role,
                                        isVerified: user.isVerified,
                                        universityName: user.universityName,
                                        graduationYear: user.graduationYear,
                                        skills: user.skills,
                                        profileImageUrl: null,
                                      ));
                                    });
                                  }
                                : null,
                            child: user?.profileImageUrl == null
                                ? Text(
                                    _getInitials(user?.firstName, user?.lastName),
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ?? 'Not set',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (user?.role == 'student' || user?.role == 'graduate')
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const ProfileUpdateScreen()),
                                      );
                                    },
                                    child: const Text(
                                      'Update Profile',
                                      style: TextStyle(
                                        color: Color(0xFF3B82F6),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Account Details
                  Card(
                    elevation: 4,
                    shape: Theme.of(context).cardTheme.shape, // Use theme's shape for outline in dark mode
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: FaIcon(FontAwesomeIcons.university, size: 20),
                            label: 'University',
                            value: user?.universityName ?? 'Not set',
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: FaIcon(FontAwesomeIcons.calendar, size: 20),
                            label: 'Graduation Year',
                            value: user?.graduationYear?.toString() ?? 'Not set',
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: FaIcon(FontAwesomeIcons.tools, size: 20),
                            label: 'Skills',
                            value: user?.skills ?? 'Not set',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Achievements
                  Card(
                    elevation: 4,
                    shape: Theme.of(context).cardTheme.shape, // Use theme's shape for outline in dark mode
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Achievements',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: FaIcon(FontAwesomeIcons.star, size: 20, color: Colors.yellow),
                            label: 'Total Score',
                            value: _totalScore.toStringAsFixed(1),
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: FaIcon(FontAwesomeIcons.award, size: 20, color: Colors.blue),
                            label: 'Badge Level',
                            value: _badgeLevel,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow({required Widget icon, required String label, required String value}) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _getInitials(String? firstName, String? lastName) {
    String initials = '';
    if (firstName != null && firstName.isNotEmpty) {
      initials += firstName[0].toUpperCase();
    }
    if (lastName != null && lastName.isNotEmpty) {
      initials += lastName[0].toUpperCase();
    }
    return initials.isEmpty ? 'U' : initials;
  }
}