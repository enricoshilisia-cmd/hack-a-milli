class Submission {
  final int id;
  final int challengeId;
  final String status;
  final String? repoLink;
  final List<String> files;
  final double? score;
  final String? challengeTitle;
  final String? submittedAt;

  Submission({
    required this.id,
    required this.challengeId,
    required this.status,
    this.repoLink,
    this.files = const [],
    this.score,
    this.challengeTitle,
    this.submittedAt,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] ?? 0,
      challengeId: json['challenge']['id'] ?? 0,
      status: json['status'] ?? '',
      repoLink: json['repo_link'],
      files: (json['files'] as List<dynamic>?)?.cast<String>() ?? [],
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      challengeTitle: json['challenge_title'],
      submittedAt: json['submitted_at'],
    );
  }
}