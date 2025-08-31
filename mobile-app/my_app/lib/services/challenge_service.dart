import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/challenge.dart';
import '../models/submission.dart';
import 'api_service.dart';

class ChallengeService {
  final ApiService _api = ApiService();

  Future<List<Challenge>> getAvailableChallenges(String token) async {
    final response = await _api.get('companies/student/challenges/', token);
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      List<Challenge> challenges = [];
      data.forEach((category, challengeList) {
        if (challengeList is List) {
          challenges.addAll(challengeList.map((json) => Challenge.fromJson(json)).toList());
        }
      });
      return challenges;
    } else {
      throw Exception('Failed to load challenges: ${response.statusCode}');
    }
  }

  Future<Challenge> getChallengeDetails(int challengeId, String token) async {
    final response = await _api.get('companies/student/challenges/$challengeId/', token);
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return Challenge.fromJson(data);
    } else {
      throw Exception('Failed to load challenge details: ${response.statusCode}');
    }
  }

  Future<void> submitChallenge(int challengeId, String token, String repoLink, {List<http.MultipartFile>? files}) async {
    final Map<String, String> fields = {'repo_link': repoLink};
    final response = await _api.postMultipart(
      'companies/student/challenges/$challengeId/submit/',
      token,
      fields: fields,
      files: files,
    );

    if (response.statusCode == 201) {
      return;
    } else {
      final error = json.decode(response.body)['error'] ?? 'Failed to submit challenge';
      throw Exception(error);
    }
  }

  Future<List<Submission>> getUserSubmissions(String token) async {
    final response = await _api.get('companies/student/submissions/', token);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Submission.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load user submissions: ${response.statusCode}');
    }
  }
}