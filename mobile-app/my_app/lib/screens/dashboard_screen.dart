import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart';
import 'challenge_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static List<dynamic>? _cachedFeaturedChallenges;
  static Map<String, dynamic>? _cachedSummary;
  static Map<String, dynamic>? _cachedPerformance;
  static List<dynamic>? _cachedRecentSubmissions;
  static List<dynamic>? _cachedRecommendations;
  List<dynamic>? _featuredChallenges;
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _performance;
  List<dynamic>? _recentSubmissions;
  List<dynamic>? _recommendations;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // Check if cached data is available
      if (_cachedFeaturedChallenges != null &&
          _cachedSummary != null &&
          _cachedPerformance != null &&
          _cachedRecentSubmissions != null &&
          _cachedRecommendations != null) {
        setState(() {
          _featuredChallenges = _cachedFeaturedChallenges;
          _summary = _cachedSummary;
          _performance = _cachedPerformance;
          _recentSubmissions = _cachedRecentSubmissions;
          _recommendations = _cachedRecommendations;
          _isLoading = false;
        });
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) {
        throw Exception('No token available');
      }

      final headers = {'Authorization': 'Token $token'};
      final responses = await Future.wait([
        http.get(Uri.parse('https://api.skillproof.me.ke/api/companies/student/featured-challenges/'), headers: headers),
        http.get(Uri.parse('https://api.skillproof.me.ke/api/companies/student/summary/'), headers: headers),
        http.get(Uri.parse('https://api.skillproof.me.ke/api/companies/student/performance/'), headers: headers),
        http.get(Uri.parse('https://api.skillproof.me.ke/api/companies/student/recent-submissions/'), headers: headers),
        http.get(Uri.parse('https://api.skillproof.me.ke/api/companies/student/recommendations/'), headers: headers),
      ]);

      setState(() {
        _featuredChallenges = responses[0].statusCode == 200 ? jsonDecode(responses[0].body) : [];
        _summary = responses[1].statusCode == 200 ? jsonDecode(responses[1].body) : {};
        _performance = responses[2].statusCode == 200 ? jsonDecode(responses[2].body) : {};
        _recentSubmissions = responses[3].statusCode == 200 ? jsonDecode(responses[3].body) : [];
        _recommendations = responses[4].statusCode == 200 ? jsonDecode(responses[4].body) : [];
        // Cache the data
        _cachedFeaturedChallenges = _featuredChallenges;
        _cachedSummary = _summary;
        _cachedPerformance = _performance;
        _cachedRecentSubmissions = _recentSubmissions;
        _cachedRecommendations = _recommendations;
        _isLoading = false;
        print('Performance API response: ${responses[2].body}');
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load dashboard: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  // Optional: Method to clear cache and refresh data
  Future<void> _refreshData() async {
    _cachedFeaturedChallenges = null;
    _cachedSummary = null;
    _cachedPerformance = null;
    _cachedRecentSubmissions = null;
    _cachedRecommendations = null;
    await _loadDashboardData();
  }

  Future<List<dynamic>> _fetchSubmissionsForDate(DateTime date) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      throw Exception('No token available');
    }

    final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final headers = {'Authorization': 'Token $token'};
    final uri = Uri.parse('https://api.skillproof.me.ke/api/companies/student/recent-submissions/?submitted_at=$formattedDate');

    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load submissions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching submissions for $formattedDate: $e');
      return [];
    }
  }

  void _showSubmissionsDialog(DateTime date, List<dynamic> submissions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Submissions on ${date.day}/${date.month}/${date.year}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: submissions.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  itemCount: submissions.length,
                  itemBuilder: (context, index) {
                    final submission = submissions[index];
                    return ListTile(
                      title: Text(
                        submission['challenge_title'] ?? 'Unknown Challenge',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Score: ${submission['score']?.toString() ?? 'N/A'} | Status: ${submission['status'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    );
                  },
                )
              : const Text(
                  'No submissions found for this date.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  List<dynamic> _filterRecommendations(List<dynamic>? recommendations) {
    if (recommendations == null) return [];
    const gradingKeywords = ['grade', 'grading', 'review', 'evaluate', 'mark'];
    const gradingLinks = ['/grade', '/submissions/review'];
    return recommendations.where((rec) {
      final action = (rec['action'] ?? '').toString().toLowerCase();
      final link = (rec['link'] ?? '').toString().toLowerCase();
      return !gradingKeywords.any((keyword) => action.contains(keyword)) &&
             !gradingLinks.any((gradingLink) => link.contains(gradingLink));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData, // Optional: Allows manual refresh
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Text(
                      '${_getGreeting()}, ${user?.lastName ?? 'User'}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Challenge Carousel
                    if (_featuredChallenges != null && _featuredChallenges!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Featured Challenges',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          CarouselSlider(
                            options: CarouselOptions(
                              height: 180,
                              autoPlay: true,
                              enlargeCenterPage: true,
                              aspectRatio: 16 / 9,
                              viewportFraction: 0.8,
                            ),
                            items: _featuredChallenges!.map((challenge) {
                              return Card(
                                elevation: 4,
                                shape: Theme.of(context).cardTheme.shape,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChallengeDetailScreen(challengeId: challenge['id']),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: challenge['thumbnail'] != null
                                                  ? Image.network(
                                                      'https://api.skillproof.me.ke${challenge['thumbnail']}',
                                                      height: 40,
                                                      width: 40,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => Container(
                                                        height: 40,
                                                        width: 40,
                                                        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                                        child: const Icon(FontAwesomeIcons.image, size: 20, color: Colors.grey),
                                                      ),
                                                    )
                                                  : Container(
                                                      height: 40,
                                                      width: 40,
                                                      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                                      child: const Icon(FontAwesomeIcons.image, size: 20, color: Colors.grey),
                                                    ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                challenge['title'] ?? 'N/A',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDarkMode ? Colors.white70 : Colors.black87,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          challenge['description'] ?? 'N/A',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode ? Colors.white70 : Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Chip(
                                              label: Text(
                                                challenge['difficulty'] ?? 'N/A',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDarkMode ? Colors.white70 : Colors.black87,
                                                ),
                                              ),
                                              backgroundColor: _getDifficultyColor(challenge['difficulty'] ?? '', isDarkMode),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ChallengeDetailScreen(challengeId: challenge['id']),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Join Now'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    // Summary Cards
                    if (_summary != null)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSummaryCard(
                                icon: FaIcon(FontAwesomeIcons.star, size: 20, color: Colors.yellow),
                                label: 'Total Score',
                                value: _summary!['total_score']?.toString() ?? '0',
                                maxWidth: constraints.maxWidth / 3 - 8,
                              ),
                              _buildSummaryCard(
                                icon: FaIcon(FontAwesomeIcons.fileAlt, size: 20, color: Colors.blue),
                                label: 'Submissions',
                                value: _summary!['total_submissions']?.toString() ?? '0',
                                maxWidth: constraints.maxWidth / 3 - 8,
                              ),
                              _buildSummaryCard(
                                icon: FaIcon(FontAwesomeIcons.award, size: 20, color: Colors.amber),
                                label: 'Badges',
                                value: _summary!['badges_earned']?.toString() ?? '0',
                                maxWidth: constraints.maxWidth / 3 - 8,
                              ),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                    // Progress Graph (Heatmap)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Performance Trend',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 4,
                          shape: Theme.of(context).cardTheme.shape,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final daysInWeek = 7;
                                final squareSize = (constraints.maxWidth / daysInWeek - 6).clamp(16.0, 20.0);
                                return SizedBox(
                                  height: 300,
                                  child: _performance != null &&
                                          _performance!['scores'] != null &&
                                          _performance!['scores'].isNotEmpty
                                      ? () {
                                          final currentMonth = DateTime.now();
                                          final currentMonthStr = '${currentMonth.year}-${currentMonth.month.toString().padLeft(2, '0')}';
                                          final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
                                          final initDate = DateTime(currentMonth.year, currentMonth.month, 1);

                                          final heatmapData = <DateTime, int>{};
                                          for (var i = 1; i <= daysInMonth; i++) {
                                            final day = i.toString().padLeft(2, '0');
                                            final dateStr = '$currentMonthStr-$day';
                                            final date = DateTime.parse(dateStr);
                                            final normalizedDate = DateTime(date.year, date.month, date.day);
                                            final scoreEntry = _performance!['scores'].firstWhere(
                                              (score) => score['date'] == dateStr,
                                              orElse: () => {'date': dateStr, 'score': 0.0},
                                            );
                                            final score = (scoreEntry['score'] as num).toDouble();
                                            heatmapData[normalizedDate] = score.toInt();
                                          }

                                          return Column(
                                            children: [
                                              Expanded(
                                                child: HeatMapCalendar(
                                                  initDate: initDate,
                                                  datasets: heatmapData,
                                                  colorsets: const {
                                                    1: Color(0xFF9BE9A8),
                                                    50: Color(0xFF40C463),
                                                    100: Color(0xFF30A14E),
                                                    150: Color(0xFF216E39),
                                                  },
                                                  defaultColor: Color(0xFFE6E7E8),
                                                  textColor: Color(0xFF8A8A8A),
                                                  colorMode: ColorMode.color,
                                                  size: squareSize,
                                                  borderRadius: 6.0,
                                                  margin: const EdgeInsets.all(4),
                                                  monthFontSize: 14.0,
                                                  weekFontSize: 12.0,
                                                  weekTextColor: Color(0xFF758EA1),
                                                  onClick: (date) async {
                                                    if (heatmapData[DateTime(date.year, date.month, date.day)] != null &&
                                                        heatmapData[DateTime(date.year, date.month, date.day)]! > 0) {
                                                      final submissions = await _fetchSubmissionsForDate(date);
                                                      _showSubmissionsDialog(date, submissions);
                                                    }
                                                  },
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Text('Less', style: TextStyle(fontSize: 10, color: Color(0xFF8A8A8A))),
                                                  const SizedBox(width: 6),
                                                  ...[0, 1, 50, 100, 150].map((threshold) {
                                                    return Container(
                                                      width: 10,
                                                      height: 10,
                                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                                      decoration: BoxDecoration(
                                                        color: threshold == 0
                                                            ? const Color(0xFFE6E7E8)
                                                            : threshold <= 1
                                                                ? const Color(0xFF9BE9A8)
                                                                : threshold <= 50
                                                                    ? const Color(0xFF40C463)
                                                                    : threshold <= 100
                                                                        ? const Color(0xFF30A14E)
                                                                        : const Color(0xFF216E39),
                                                        borderRadius: BorderRadius.circular(3),
                                                      ),
                                                    );
                                                  }).toList(),
                                                  const SizedBox(width: 6),
                                                  const Text('More', style: TextStyle(fontSize: 10, color: Color(0xFF8A8A8A))),
                                                ],
                                              ),
                                            ],
                                          );
                                        }()
                                      : const Center(
                                          child: Text(
                                            'No performance data available yet.',
                                            style: TextStyle(fontSize: 14, color: Colors.grey),
                                          ),
                                        ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Recent Activity Table
                    if (_recentSubmissions != null && _recentSubmissions!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Activity',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(context, '/submissions');
                                },
                                child: const Text('View All', style: TextStyle(color: Colors.blue, fontSize: 14)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 2,
                            shape: Theme.of(context).cardTheme.shape,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Table(
                                border: TableBorder.all(color: Colors.grey.shade200, width: 0.5),
                                columnWidths: const {
                                  0: FlexColumnWidth(3),
                                  1: FlexColumnWidth(2),
                                  2: FlexColumnWidth(1),
                                },
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainer),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                        child: Text(
                                          'Challenge',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Theme.of(context).textTheme.bodySmall?.color,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                        child: Text(
                                          'Status',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Theme.of(context).textTheme.bodySmall?.color,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                        child: Text(
                                          'Score',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Theme.of(context).textTheme.bodySmall?.color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ..._recentSubmissions!.map((submission) {
                                    return TableRow(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ChallengeDetailScreen(
                                                    challengeId: submission['challenge']['id'] ?? 0,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              submission['challenge_title'] ?? 'N/A',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                          child: Chip(
                                            label: Text(
                                              submission['status'] ?? 'N/A',
                                              style: const TextStyle(fontSize: 10),
                                              textAlign: TextAlign.left,
                                            ),
                                            backgroundColor: _getStatusColor(submission['status'] ?? ''),
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                          child: Text(
                                            submission['score']?.toString() ?? 'N/A',
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      const Text('No recent submissions available.'),
                    const SizedBox(height: 24),
                    // Recommended Actions
                    if (_recommendations != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recommended Actions',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ..._filterRecommendations(_recommendations).map((rec) {
                            return Card(
                              elevation: 4,
                              shape: Theme.of(context).cardTheme.shape,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: FaIcon(
                                  rec['link'].startsWith('/challenges/')
                                      ? FontAwesomeIcons.trophy
                                      : rec['link'] == '/my_account'
                                          ? FontAwesomeIcons.userEdit
                                          : FontAwesomeIcons.briefcase,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                title: Text(rec['action'] ?? 'N/A', style: const TextStyle(fontSize: 14)),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    final link = rec['link'] ?? '/';
                                    if (link.startsWith('/challenges/')) {
                                      final challengeId = int.tryParse(link.split('/').last);
                                      if (challengeId != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChallengeDetailScreen(challengeId: challengeId),
                                          ),
                                        );
                                      }
                                    } else {
                                      Navigator.pushReplacementNamed(context, link);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  child: const Text('Take Action', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                  ],
                ),
              ),
      ),
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

  Color _getDifficultyColor(String difficulty, bool isDarkMode) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return isDarkMode ? Colors.green.shade700 : Colors.green.shade100;
      case 'medium':
        return isDarkMode ? Colors.orange.shade700 : Colors.orange.shade100;
      case 'hard':
        return isDarkMode ? Colors.red.shade700 : Colors.red.shade100;
      default:
        return isDarkMode ? Colors.blue.shade700 : Colors.blue.shade100;
    }
  }

  Color _getStatusColor(String status) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (isDarkMode) {
      switch (status.toLowerCase()) {
        case 'graded':
          return Colors.green.shade700;
        case 'pending':
          return Colors.orange.shade700;
        case 'rejected':
          return Colors.red.shade700;
        default:
          return Colors.grey.shade700;
      }
    } else {
      switch (status.toLowerCase()) {
        case 'graded':
          return Colors.green.shade100;
        case 'pending':
          return Colors.orange.shade100;
        case 'rejected':
          return Colors.red.shade100;
        default:
          return Colors.grey.shade100;
      }
    }
  }

  String _formatDate(String date) {
    if (date.isEmpty) return 'N/A';
    try {
      final parsed = DateTime.parse(date);
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildSummaryCard({required Widget icon, required String label, required String value, required double maxWidth}) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: Theme.of(context).cardTheme.shape,
        child: Container(
          constraints: BoxConstraints(
            minHeight: 100,
            maxWidth: maxWidth,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}