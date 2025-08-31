import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/services.dart';
import '../providers/auth_provider.dart';
import '../theme_provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/input_decoration.dart';
import '../models/user.dart';

class ProfileUpdateScreen extends StatefulWidget {
  const ProfileUpdateScreen({Key? key}) : super(key: key);

  @override
  _ProfileUpdateScreenState createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _universityNameController = TextEditingController();
  final _graduationYearController = TextEditingController();
  final _skillsController = TextEditingController();
  final _currentPositionController = TextEditingController();
  List<String> _areasOfExpertise = [];
  static Map<String, dynamic>? _cachedOriginalProfileData;
  static List<Map<String, dynamic>>? _cachedCategories;
  Map<String, dynamic>? _originalProfileData;
  XFile? _profileImage;
  bool _isLoading = false;
  String? _expertiseError;

  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      // Check if cached profile data is available
      if (_cachedOriginalProfileData != null) {
        setState(() {
          _originalProfileData = _cachedOriginalProfileData;
          final userData = _cachedOriginalProfileData!['user'];
          _emailController.text = userData['email'] ?? '';
          _firstNameController.text = userData['first_name'] ?? '';
          _lastNameController.text = userData['last_name'] ?? '';
          _phoneNumberController.text = userData['phone_number'] != null && userData['phone_number'].startsWith('+254')
              ? userData['phone_number'].substring(4)
              : userData['phone_number'] ?? '';
          _universityNameController.text = _cachedOriginalProfileData!['university_name'] ?? '';
          _graduationYearController.text = _cachedOriginalProfileData!['graduation_year'] ?? '';
          _skillsController.text = _cachedOriginalProfileData!['skills'] ?? '';
          _areasOfExpertise = List<String>.from(_cachedOriginalProfileData!['areas_of_expertise'] ?? []);
          _currentPositionController.text = _cachedOriginalProfileData!['current_position'] ?? '';
          _isLoading = false;
        });
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final user = authProvider.user;

      if (user == null || token == null) {
        throw Exception('User or token is null');
      }

      print('Loading profile for user: ${user.email}, role: ${user.role}');

      _emailController.text = user.email;
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      _phoneNumberController.text = user.phoneNumber != null && user.phoneNumber!.startsWith('+254')
          ? user.phoneNumber!.substring(4)
          : user.phoneNumber ?? '';
      _universityNameController.text = user.universityName ?? '';
      _graduationYearController.text = user.graduationYear?.toString() ?? '';
      _skillsController.text = user.skills ?? '';

      final profileData = await _apiService.getUserProfile(token);
      print('Profile data received: $profileData');
      setState(() {
        _areasOfExpertise = List<String>.from(profileData['areas_of_expertise'] ?? []);
        if (user.role == 'graduate') {
          _currentPositionController.text = profileData['current_position'] ?? '';
        }
        _originalProfileData = {
          'user': {
            'email': user.email,
            'first_name': user.firstName ?? '',
            'last_name': user.lastName ?? '',
            'phone_number': user.phoneNumber ?? '',
          },
          'university_name': user.universityName ?? '',
          'graduation_year': user.graduationYear?.toString() ?? '',
          'skills': user.skills ?? '',
          'areas_of_expertise': List<String>.from(_areasOfExpertise),
          'current_position': user.role == 'graduate' ? profileData['current_position'] ?? '' : '',
          'profile_image': profileData['profile_image'] != null
              ? 'https://api.skillproof.me.ke${profileData['profile_image']}'
              : null,
        };
        // Cache the profile data
        _cachedOriginalProfileData = _originalProfileData;
      });
    } catch (e) {
      print('Error loading profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Method to clear cache and refresh data
  Future<void> _refreshData() async {
    _cachedOriginalProfileData = null;
    await _loadUserProfile();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _universityNameController.dispose();
    _graduationYearController.dispose();
    _skillsController.dispose();
    _currentPositionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _profileImage = pickedFile;
        });
      }
    } catch (e) {
      print('Error picking image from $source: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    var sortedList1 = List<String>.from(list1)..sort();
    var sortedList2 = List<String>.from(list2)..sort();
    for (int i = 0; i < sortedList1.length; i++) {
      if (sortedList1[i] != sortedList2[i]) return false;
    }
    return true;
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final role = authProvider.user?.role;
      final token = authProvider.token;

      if (role == null || token == null) {
        throw Exception('User not authenticated');
      }

      if (_cachedCategories == null) {
        _cachedCategories = await _apiService.searchCategories('');
      }
      final categoryMap = {for (var cat in _cachedCategories!) cat['name'] as String: cat['id'] as int};
      final expertiseIds = _areasOfExpertise.map((name) => categoryMap[name] ?? 0).where((id) => id != 0).toList();

      if (expertiseIds.length != _areasOfExpertise.length) {
        setState(() {
          _expertiseError = 'One or more selected areas are invalid';
          _isLoading = false;
        });
        return;
      }

      final fields = <String, String>{};
      if (_emailController.text.trim() != _originalProfileData?['user']['email']) {
        fields['user[email]'] = _emailController.text.trim();
      }
      if (_firstNameController.text.trim() != _originalProfileData?['user']['first_name']) {
        fields['user[first_name]'] = _firstNameController.text.trim();
      }
      if (_lastNameController.text.trim() != _originalProfileData?['user']['last_name']) {
        fields['user[last_name]'] = _lastNameController.text.trim();
      }
      final formattedPhoneNumber = '+254${_phoneNumberController.text.trim()}';
      if (formattedPhoneNumber != _originalProfileData?['user']['phone_number']) {
        fields['user[phone_number]'] = formattedPhoneNumber;
      }
      if (_passwordController.text.isNotEmpty) {
        fields['user[password]'] = _passwordController.text;
      }
      if (_universityNameController.text.trim() != _originalProfileData?['university_name']) {
        fields['university_name'] = _universityNameController.text.trim();
      }
      if (_graduationYearController.text.trim() != _originalProfileData?['graduation_year']) {
        fields['graduation_year]'] = _graduationYearController.text.trim();
      }
      if (_skillsController.text.trim() != _originalProfileData?['skills']) {
        fields['skills'] = _skillsController.text.trim();
      }
      if (role == 'graduate' && _currentPositionController.text.trim() != _originalProfileData?['current_position']) {
        fields['current_position]'] = _currentPositionController.text.trim();
      }
      for (int i = 0; i < expertiseIds.length; i++) {
        fields['areas_of_expertise[$i]'] = expertiseIds[i].toString();
      }
      if (expertiseIds.isEmpty) {
        fields['areas_of_expertise[]'] = '';
      }

      List<http.MultipartFile> files = [];
      if (_profileImage != null) {
        files.add(
          http.MultipartFile(
            'profile_image',
            _profileImage!.readAsBytes().asStream(),
            await _profileImage!.length(),
            filename: _profileImage!.name,
            contentType: MediaType('image', _profileImage!.name.split('.').last),
          ),
        );
      }

      print('Request fields: $fields');
      print('Request files: ${files.isEmpty ? 'None' : files.map((f) => f.filename).toList()}');

      final response = await _apiService.putMultipart(
        'users/profile/update/',
        token,
        fields: fields,
        files: files,
      );

      if (response.statusCode == 200) {
        final profileData = await _apiService.getUserProfile(token);
        final updatedUser = User(
          email: _emailController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneNumber: formattedPhoneNumber,
          role: role,
          isVerified: authProvider.user!.isVerified,
          universityName: _universityNameController.text.trim(),
          graduationYear: int.tryParse(_graduationYearController.text.trim()),
          skills: _skillsController.text.trim(),
          profileImageUrl: profileData['profile_image'] != null
              ? 'https://api.skillproof.me.ke${profileData['profile_image']}'
              : null,
        );
        authProvider.updateUser(updatedUser);

        setState(() {
          _originalProfileData = {
            'user': {
              'email': _emailController.text.trim(),
              'first_name': _firstNameController.text.trim(),
              'last_name': _lastNameController.text.trim(),
              'phone_number': formattedPhoneNumber,
            },
            'university_name': _universityNameController.text.trim(),
            'graduation_year': _graduationYearController.text.trim(),
            'skills': _skillsController.text.trim(),
            'areas_of_expertise': List<String>.from(_areasOfExpertise),
            'current_position': role == 'graduate' ? _currentPositionController.text.trim() : '',
            'profile_image': profileData['profile_image'] != null
                ? 'https://api.skillproof.me.ke${profileData['profile_image']}'
                : null,
          };
          // Update cache after successful update
          _cachedOriginalProfileData = _originalProfileData;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonDecode(response.body)['message'] ?? 'Profile updated successfully')),
        );
        Navigator.pop(context);
      } else {
        final error = jsonDecode(response.body)['errors'] ?? 'Profile update failed';
        print('Server error response: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile update failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onNavTap(int index) {
    if (index == 4) {
      _showMoreOptions(context);
    } else {
      Navigator.pushReplacementNamed(
        context,
        ['/dashboard', '/challenges', '/submissions', '/my_account'][index],
      );
    }
  }

  void _showMoreOptions(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext modalContext) {
        final themeProvider = Provider.of<ThemeProvider>(parentContext);
        final authProvider = Provider.of<AuthProvider>(parentContext, listen: false);
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: FaIcon(FontAwesomeIcons.briefcase, size: 20),
                title: const Text('Jobs', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(modalContext);
                  Navigator.pushNamed(parentContext, '/jobs');
                },
              ),
              ListTile(
                leading: FaIcon(
                  themeProvider.isDarkMode ? FontAwesomeIcons.sun : FontAwesomeIcons.moon,
                  size: 20,
                ),
                title: const Text('Toggle Theme', style: TextStyle(fontSize: 14)),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                ),
              ),
              ListTile(
                leading: FaIcon(FontAwesomeIcons.mobileAlt, size: 20),
                title: const Text('Use System Theme', style: TextStyle(fontSize: 14)),
                onTap: () {
                  themeProvider.setSystemTheme();
                  Navigator.pop(modalContext);
                },
              ),
              ListTile(
                leading: FaIcon(FontAwesomeIcons.signOutAlt, size: 20),
                title: const Text('Logout', style: TextStyle(fontSize: 14)),
                onTap: () {
                  authProvider.logout();
                  Navigator.pop(modalContext);
                  Navigator.pushReplacementNamed(parentContext, '/login');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isStudent = user?.role == 'student';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Update Profile'),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 10,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                    ),
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: buildInputDecoration(
                              context,
                              'Email',
                              const Icon(Icons.email, color: Colors.blue),
                              isRequired: false,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade900),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                if (isStudent) {
                                  final domain = value.split('@').last.toLowerCase();
                                  // Note: Domain validation is handled by the backend
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: buildInputDecoration(
                              context,
                              'Password (leave blank to keep unchanged)',
                              const Icon(Icons.lock, color: Colors.blue),
                              isRequired: false,
                            ),
                            obscureText: true,
                            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade900),
                            validator: (value) {
                              if (value != null && value.isNotEmpty && value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _firstNameController,
                            decoration: buildInputDecoration(
                              context,
                              'First Name',
                              const Icon(Icons.person_outline, color: Colors.blue),
                              isRequired: false,
                            ),
                            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade900),
                            validator: (value) => null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: buildInputDecoration(
                              context,
                              'Last Name',
                              const Icon(Icons.person_outline, color: Colors.blue),
                              isRequired: false,
                            ),
                            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade900),
                            validator: (value) => null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneNumberController,
                            decoration: buildInputDecoration(
                              context,
                              'Phone Number',
                              const Icon(Icons.phone, color: Colors.blue),
                              isRequired: false,
                            ).copyWith(
                              prefixText: '+254 ',
                              prefixStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(9),
                            ],
                            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade900),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (!RegExp(r'^\d{9}$').hasMatch(value)) {
                                  return 'Phone number must be exactly 9 digits';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Institution Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _universityNameController,
                            decoration: buildInputDecoration(
                              context,
                              'University Name',
                              const Icon(Icons.school, color: Colors.blue),
                              isRequired: false,
                            ),
                            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade900),
                            validator: (value) => null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _graduationYearController,
                            decoration: buildInputDecoration(
                              context,
                              'Graduation Year',
                              const Icon(Icons.calendar_today, color: Colors.blue),
                              isRequired: false,
                            ),
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade900),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid year';
                                }
                              }
                              return null;
                            },
                          ),
                          if (!isStudent) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _currentPositionController,
                              decoration: buildInputDecoration(
                                context,
                                'Current Position',
                                const Icon(Icons.work, color: Colors.blue),
                                isRequired: false,
                              ),
                              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade900),
                              validator: (value) => null,
                            ),
                          ],
                          const SizedBox(height: 24),
                          Text(
                            'Skills & Expertise',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _skillsController,
                            decoration: buildInputDecoration(
                              context,
                              'Skills (comma-separated)',
                              const Icon(Icons.build, color: Colors.blue),
                              isRequired: false,
                            ),
                            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade900),
                            validator: (value) => null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Areas of Expertise (Select up to 3)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TypeAheadField<String>(
                            decorationBuilder: (context, child) {
                              return Material(
                                type: MaterialType.card,
                                elevation: 4,
                                borderRadius: const BorderRadius.all(Radius.circular(12)),
                                child: child,
                              );
                            },
                            builder: (context, controller, focusNode) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: buildInputDecoration(
                                  context,
                                  'Search Areas of Expertise',
                                  const Icon(Icons.list, color: Colors.blue),
                                  isRequired: false,
                                ).copyWith(
                                  errorText: _expertiseError,
                                ),
                                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade900),
                              );
                            },
                            suggestionsCallback: (pattern) async {
                              if (pattern.length < 4) return [];
                              if (_cachedCategories == null) {
                                _cachedCategories = await _apiService.searchCategories('');
                              }
                              return _cachedCategories!
                                  .where((cat) => cat['name'].toLowerCase().startsWith(pattern.toLowerCase()))
                                  .map((cat) => cat['name'] as String)
                                  .toList();
                            },
                            itemBuilder: (context, suggestion) {
                              return ListTile(
                                title: Text(suggestion),
                                enabled: !_areasOfExpertise.contains(suggestion),
                              );
                            },
                            onSelected: (suggestion) {
                              setState(() {
                                if (_areasOfExpertise.length < 3 && !_areasOfExpertise.contains(suggestion)) {
                                  _areasOfExpertise.add(suggestion);
                                  _expertiseError = null;
                                } else if (_areasOfExpertise.length >= 3) {
                                  _expertiseError = 'You can select up to 3 areas only';
                                }
                              });
                            },
                            emptyBuilder: (context) => const ListTile(
                              title: Text('No matching areas found'),
                            ),
                            errorBuilder: (context, error) => const ListTile(
                              title: Text('Error loading suggestions'),
                            ),
                            loadingBuilder: (context) => const ListTile(
                              title: Text('Loading...'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: _areasOfExpertise.map((area) => Chip(
                                  label: Text(area),
                                  onDeleted: () {
                                    setState(() {
                                      _areasOfExpertise.remove(area);
                                      _expertiseError = null;
                                    });
                                  },
                                )).toList(),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Profile Image',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _profileImage != null ? _profileImage!.name : 'No image selected',
                                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _pickImage(ImageSource.camera),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    child: const Text('Take Photo'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _pickImage(ImageSource.gallery),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    child: const Text('Choose from Gallery'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _updateProfile,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(200, 48),
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Update Profile'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 3, // My Account index
        onTap: _onNavTap,
      ),
    );
  }
}