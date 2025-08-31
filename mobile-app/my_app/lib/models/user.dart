class User {
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String role;
  final bool isVerified;
  final String? universityName;
  final int? graduationYear;
  final String? skills;
  final String? profileImageUrl;

  User({
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    required this.role,
    required this.isVerified,
    this.universityName,
    this.graduationYear,
    this.skills,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phoneNumber: json['phone_number'],
      role: json['role'],
      isVerified: json['is_verified'] ?? false,
      universityName: json['university_name'],
      graduationYear: json['graduation_year'],
      skills: json['skills'],
      profileImageUrl: json['profile_image'],
    );
  }
}