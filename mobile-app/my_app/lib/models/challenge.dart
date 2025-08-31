class Challenge {
  final int id;
  final String title;
  final String description;
  final String challengeType;
  final String difficulty;
  final String endDate;
  final List<Map<String, dynamic>> categories;
  final String? countdown;
  final int maxSubmissions;
  final bool isCollaborative;
  final int? maxTeamSize;
  final String skillTags;
  final String learningOutcomes;
  final String prerequisiteDescription;
  final int? estimatedCompletionTime;
  final double maxScore;
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> attachments;
  final List<Map<String, dynamic>> rubrics;
  final String? thumbnail;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.challengeType,
    required this.difficulty,
    required this.endDate,
    required this.categories,
    this.countdown,
    required this.maxSubmissions,
    required this.isCollaborative,
    this.maxTeamSize,
    required this.skillTags,
    required this.learningOutcomes,
    required this.prerequisiteDescription,
    this.estimatedCompletionTime,
    required this.maxScore,
    required this.tasks,
    required this.attachments,
    required this.rubrics,
    this.thumbnail,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      challengeType: json['challenge_type'],
      difficulty: json['difficulty'],
      endDate: json['end_date'],
      categories: List<Map<String, dynamic>>.from(json['categories']),
      countdown: json['countdown'],
      maxSubmissions: json['max_submissions'] ?? 1,
      isCollaborative: json['is_collaborative'] ?? false,
      maxTeamSize: json['max_team_size'],
      skillTags: json['skill_tags'] ?? '',
      learningOutcomes: json['learning_outcomes'] ?? '',
      prerequisiteDescription: json['prerequisite_description'] ?? '',
      estimatedCompletionTime: json['estimated_completion_time'],
      maxScore: (json['max_score'] as num?)?.toDouble() ?? 100.0,
      tasks: List<Map<String, dynamic>>.from(json['tasks'] ?? []),
      attachments: List<Map<String, dynamic>>.from(json['attachments'] ?? []),
      rubrics: List<Map<String, dynamic>>.from(json['rubrics'] ?? []),
      thumbnail: json['thumbnail'],
    );
  }
}