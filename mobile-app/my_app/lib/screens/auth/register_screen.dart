import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../widgets/auth_app_bar.dart';
import '../../widgets/input_decoration.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  String _role = 'student';
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _universityNameController = TextEditingController();
  final _universityDomainController = TextEditingController();
  final _graduationYearController = TextEditingController();
  final _skillsController = TextEditingController();
  final _currentPositionController = TextEditingController();
  List<String> _areasOfExpertise = [];
  bool _isLoading = false;
  String? _expertiseError;
  List<Map<String, dynamic>>? _cachedCategories;

  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _universityNameController.dispose();
    _universityDomainController.dispose();
    _graduationYearController.dispose();
    _skillsController.dispose();
    _currentPositionController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _currentStep = _getFirstInvalidStep();
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_cachedCategories == null) {
        _cachedCategories = await _apiService.searchCategories('');
      }
      final categoryMap = {for (var cat in _cachedCategories!) cat['name'] as String: cat['id'] as int};
      final expertiseIds = _areasOfExpertise.map((name) => categoryMap[name] ?? 0).where((id) => id != 0).toList();

      if (expertiseIds.length != _areasOfExpertise.length) {
        setState(() {
          _expertiseError = 'One or more selected areas are invalid';
          _isLoading = false;
          _currentStep = 2;
        });
        return;
      }

      final data = {
        'user': {
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'role': _role,
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
        },
        'university_name': _universityNameController.text.trim(),
        'graduation_year': int.tryParse(_graduationYearController.text.trim()),
        'skills': _skillsController.text.trim(),
        'areas_of_expertise': expertiseIds,
      };

      if (_role == 'student') {
        data['university_domain'] = _universityDomainController.text.trim().toLowerCase();
      } else {
        if (_universityDomainController.text.isNotEmpty) {
          data['university_domain'] = _universityDomainController.text.trim().toLowerCase();
        }
        data['current_position'] = _currentPositionController.text.trim();
      }

      final response = await _apiService.register(_role, data);

      if (response.statusCode == 201) {
        final message = jsonDecode(response.body)['message'] ?? 'Registration successful';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        Navigator.pop(context);
      } else {
        final error = jsonDecode(response.body)['errors'] ?? 'Registration failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int _getFirstInvalidStep() {
    if (_role == null ||
        _emailController.text.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text) ||
        _passwordController.text.isEmpty ||
        _passwordController.text.length < 8 ||
        _firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty) {
      return 0;
    }
    if (_universityNameController.text.isEmpty ||
        (_role == 'student' && _universityDomainController.text.isEmpty) ||
        _graduationYearController.text.isEmpty ||
        int.tryParse(_graduationYearController.text) == null ||
        (_role == 'graduate' && _currentPositionController.text.isEmpty)) {
      return 1;
    }
    if (_skillsController.text.isEmpty) {
      return 2;
    }
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AuthAppBar(title: 'Welcome to SkillProof'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3B82F6),
              Color(0xFF7C3AED),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      kToolbarHeight,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      elevation: 10,
                      shadowColor: Colors.black.withOpacity(0.2),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: const BorderRadius.all(Radius.circular(20)),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Stepper(
                            physics: const ClampingScrollPhysics(),
                            currentStep: _currentStep,
                            onStepContinue: () {
                              if (_currentStep < 2) {
                                setState(() => _currentStep += 1);
                              } else {
                                _register();
                              }
                            },
                            onStepCancel: () {
                              if (_currentStep > 0) {
                                setState(() => _currentStep -= 1);
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            controlsBuilder: (context, details) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: _isLoading ? null : details.onStepContinue,
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(120, 48),
                                        backgroundColor: const Color(0xFF3B82F6),
                                        foregroundColor: Colors.white,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(Radius.circular(12)),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const CircularProgressIndicator(color: Colors.white)
                                          : Text(_currentStep < 2 ? 'Next' : 'Register'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: _isLoading ? null : details.onStepCancel,
                                      child: Text(
                                        'Back',
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.blue.shade300 : const Color(0xFF3B82F6),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            steps: [
                              Step(
                                title: Text(
                                  'User Details',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                content: Column(
                                  children: [
                                    DropdownButtonFormField<String>(
                                      value: _role,
                                      decoration: buildInputDecoration(
                                        context,
                                        'User Role',
                                        const Icon(Icons.person),
                                        isRequired: true,
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'student', child: Text('Student')),
                                        DropdownMenuItem(value: 'graduate', child: Text('Graduate')),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _role = value!;
                                          _universityDomainController.clear();
                                          _currentPositionController.clear();
                                          _areasOfExpertise = [];
                                          _expertiseError = null;
                                        });
                                      },
                                      validator: (value) => value == null ? 'Please select a role' : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _emailController,
                                      decoration: buildInputDecoration(
                                        context,
                                        'Email',
                                        const Icon(Icons.email),
                                        isRequired: true,
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDarkMode ? Colors.white70 : Colors.grey.shade900,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Please enter your email';
                                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _passwordController,
                                      decoration: buildInputDecoration(
                                        context,
                                        'Password',
                                        const Icon(Icons.lock),
                                        isRequired: true,
                                      ),
                                      obscureText: true,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDarkMode ? Colors.white70 : Colors.grey.shade900,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Please enter a password';
                                        if (value.length < 8) return 'Password must be at least 8 characters';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _firstNameController,
                                      decoration: buildInputDecoration(
                                        context,
                                        'First Name',
                                        const Icon(Icons.person_outline),
                                        isRequired: true,
                                      ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDarkMode ? Colors.white70 : Colors.grey.shade900,
                                      ),
                                      validator: (value) => value == null || value.isEmpty ? 'Please enter your first name' : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _lastNameController,
                                      decoration: buildInputDecoration(
                                        context,
                                        'Last Name',
                                        const Icon(Icons.person_outline),
                                        isRequired: true,
                                      ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDarkMode ? Colors.white70 : Colors.grey.shade900,
                                      ),
                                      validator: (value) => value == null || value.isEmpty ? 'Please enter your last name' : null,
                                    ),
                                  ],
                                ),
                                isActive: _currentStep == 0,
                              ),
                              Step(
                                title: Text(
                                  'Institution Details',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                content: Column(
                                  children: [
                                    TextFormField(
                                      controller: _universityNameController,
                                      decoration: buildInputDecoration(
                                        context,
                                        'University Name',
                                        const Icon(Icons.school),
                                        isRequired: true,
                                      ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDarkMode ? Colors.white70 : Colors.grey.shade900,
                                      ),
                                      validator: (value) => value == null || value.isEmpty ? 'Please enter your university name' : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _universityDomainController,
                                      decoration: buildInputDecoration(
                                        context,
                                        _role == 'student' ? 'University Domain' : 'University Domain',
                                        const Icon(Icons.domain),
                                        isRequired: _role == 'student',
                                      ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDarkMode ? Colors.white70 : Colors.grey.shade900,
                                      ),
                                      validator: (value) {
                                        if (_role == 'student' && (value == null || value.isEmpty)) {
                                          return 'Please enter your university domain';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _graduationYearController,
                                      decoration: buildInputDecoration(
                                        context,
                                        'Graduation Year',
                                        const Icon(Icons.calendar_today),
                                        isRequired: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDarkMode ? Colors.white70 : Colors.grey.shade900,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Please enter your graduation year';
                                        if (int.tryParse(value) == null) return 'Please enter a valid year';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    if (_role == 'graduate')
                                      TextFormField(
                                        controller: _currentPositionController,
                                        decoration: buildInputDecoration(
                                          context,
                                          'Current Position',
                                          const Icon(Icons.work),
                                          isRequired: true,
                                        ),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isDarkMode ? Colors.white70 : Colors.grey.shade900,
                                        ),
                                        validator: (value) => value == null || value.isEmpty ? 'Please enter your current position' : null,
                                      ),
                                  ],
                                ),
                                isActive: _currentStep == 1,
                              ),
                              Step(
                                title: Text(
                                  'Skills & Expertise',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      controller: _skillsController,
                                      decoration: buildInputDecoration(
                                        context,
                                        'Skills (comma-separated)',
                                        const Icon(Icons.build),
                                        isRequired: true,
                                      ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDarkMode ? Colors.white70 : Colors.grey.shade900,
                                      ),
                                      validator: (value) => value == null || value.isEmpty ? 'Please enter your skills' : null,
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
                                            const Icon(Icons.list),
                                          ).copyWith(
                                            errorText: _expertiseError,
                                          ),
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: isDarkMode ? Colors.white70 : Colors.grey.shade900,
                                          ),
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
                                          title: Text(
                                            suggestion,
                                            style: TextStyle(
                                              color: isDarkMode ? Colors.white70 : Colors.black87,
                                            ),
                                          ),
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
                                      emptyBuilder: (context) => ListTile(
                                        title: Text(
                                          'No matching areas found',
                                          style: TextStyle(
                                            color: isDarkMode ? Colors.white70 : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      errorBuilder: (context, error) => ListTile(
                                        title: Text(
                                          'Error loading suggestions',
                                          style: TextStyle(
                                            color: isDarkMode ? Colors.red.shade300 : Colors.red,
                                          ),
                                        ),
                                      ),
                                      loadingBuilder: (context) => ListTile(
                                        title: Text(
                                          'Loading...',
                                          style: TextStyle(
                                            color: isDarkMode ? Colors.white70 : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      constraints: const BoxConstraints(
                                        maxHeight: 200,
                                      ),
                                      offset: const Offset(0, -200),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8.0,
                                      runSpacing: 4.0,
                                      children: _areasOfExpertise.map((area) => Chip(
                                        label: Text(
                                          area,
                                          style: TextStyle(
                                            color: isDarkMode ? Colors.white70 : Colors.black87,
                                          ),
                                        ),
                                        backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.blue.shade50,
                                        onDeleted: () {
                                          setState(() {
                                            _areasOfExpertise.remove(area);
                                            _expertiseError = null;
                                          });
                                        },
                                      )).toList(),
                                    ),
                                  ],
                                ),
                                isActive: _currentStep == 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}