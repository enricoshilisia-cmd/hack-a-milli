import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart';
import 'challenge_detail_screen.dart';

class SubmissionsScreen extends StatefulWidget {
  const SubmissionsScreen({Key? key}) : super(key: key);

  @override
  _SubmissionsScreenState createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  String _selectedTab = 'graded'; // Default to graded submissions
  static int? _cachedTotalSubmitted;
  static int? _cachedGradedCount;
  static int? _cachedPendingCount;
  static Map<String, List<dynamic>> _cachedSubmissions = {};
  int _totalSubmitted = 0;
  int _gradedCount = 0;
  int _pendingCount = 0;
  bool _isLoadingCounts = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissionCounts();
  }

  Future<void> _loadSubmissionCounts() async {
    setState(() => _isLoadingCounts = true);
    try {
      // Check if cached counts are available
      if (_cachedTotalSubmitted != null &&
          _cachedGradedCount != null &&
          _cachedPendingCount != null) {
        setState(() {
          _totalSubmitted = _cachedTotalSubmitted!;
          _gradedCount = _cachedGradedCount!;
          _pendingCount = _cachedPendingCount!;
          _isLoadingCounts = false;
        });
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        setState(() {
          _totalSubmitted = 0;
          _gradedCount = 0;
          _pendingCount = 0;
          _isLoadingCounts = false;
        });
        return;
      }

      // Fetch counts concurrently
      final [graded, pending, rejected] = await Future.wait([
        fetchSubmissions('results', token),
        fetchSubmissions('submissions/pending', token),
        fetchSubmissions('submissions/rejected', token),
      ]);

      setState(() {
        _gradedCount = graded.length;
        _pendingCount = pending.length;
        _totalSubmitted = graded.length + pending.length + rejected.length;
        // Cache the counts
        _cachedTotalSubmitted = _totalSubmitted;
        _cachedGradedCount = _gradedCount;
        _cachedPendingCount = _pendingCount;
        // Cache the submission lists
        _cachedSubmissions['results'] = graded;
        _cachedSubmissions['submissions/pending'] = pending;
        _cachedSubmissions['submissions/rejected'] = rejected;
        _isLoadingCounts = false;
        print('Submission counts: total=$_totalSubmitted, graded=$_gradedCount, pending=$_pendingCount');
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load submission counts: $e')),
      );
      setState(() => _isLoadingCounts = false);
    }
  }

  // Method to clear cache and refresh data
  Future<void> _refreshData() async {
    _cachedTotalSubmitted = null;
    _cachedGradedCount = null;
    _cachedPendingCount = null;
    _cachedSubmissions.clear();
    await _loadSubmissionCounts();
  }

  Future<List<dynamic>> fetchSubmissions(String endpoint, String? token) async {
    // Check if cached submissions are available
    if (_cachedSubmissions.containsKey(endpoint)) {
      return _cachedSubmissions[endpoint]!;
    }

    if (token == null) {
      return [];
    }
    try {
      final response = await http.get(
        Uri.parse('https://api.skillproof.me.ke/api/companies/student/$endpoint/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) {
        final submissions = jsonDecode(response.body);
        print('Fetched $endpoint: $submissions');
        return submissions;
      } else {
        throw Exception('Failed to load submissions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching submissions ($endpoint): $e');
      return [];
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final token = authProvider.token;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Column(
          children: [
            // Summary Cards
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoadingCounts
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSummaryCard(
                              icon: FaIcon(FontAwesomeIcons.fileAlt, size: 20, color: Colors.blue),
                              label: 'Submitted',
                              value: _totalSubmitted.toString(),
                              maxWidth: constraints.maxWidth / 3 - 8,
                            ),
                            _buildSummaryCard(
                              icon: FaIcon(FontAwesomeIcons.check, size: 20, color: Colors.green),
                              label: 'Graded',
                              value: _gradedCount.toString(),
                              maxWidth: constraints.maxWidth / 3 - 8,
                            ),
                            _buildSummaryCard(
                              icon: FaIcon(FontAwesomeIcons.clock, size: 20, color: Colors.orange),
                              label: 'Pending',
                              value: _pendingCount.toString(),
                              maxWidth: constraints.maxWidth / 3 - 8,
                            ),
                          ],
                        );
                      },
                    ),
            ),
            // Segmented Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'graded',
                    label: Text('Graded', style: TextStyle(fontSize: 12)),
                    icon: FaIcon(FontAwesomeIcons.check, size: 16),
                  ),
                  ButtonSegment(
                    value: 'pending',
                    label: Text('Pending', style: TextStyle(fontSize: 12)),
                    icon: FaIcon(FontAwesomeIcons.clock, size: 16),
                  ),
                  ButtonSegment(
                    value: 'rejected',
                    label: Text('Rejected', style: TextStyle(fontSize: 12)),
                    icon: FaIcon(FontAwesomeIcons.times, size: 16),
                  ),
                ],
                selected: {_selectedTab},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedTab = newSelection.first;
                  });
                },
              ),
            ),
            // Submissions List
            Expanded(
              child: FutureBuilder(
                future: fetchSubmissions(
                  _selectedTab == 'graded'
                      ? 'results'
                      : 'submissions/$_selectedTab',
                  token,
                ),
                builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(
                      child: Text(
                        'Error loading submissions',
                        style: TextStyle(fontSize: 14),
                      ),
                    );
                  }
                  final submissions = snapshot.data!;
                  if (submissions.isEmpty) {
                    return Center(
                      child: Text(
                        'No $_selectedTab submissions',
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: submissions.length,
                    itemBuilder: (context, index) {
                      final submission = submissions[index];
                      final challengeId = submission['challenge']?['id'];
                      final isClickable = _selectedTab == 'pending' && challengeId != null;
                      return Card(
                        elevation: 4,
                        shape: Theme.of(context).cardTheme.shape,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ListTile(
                              onTap: isClickable
                                  ? () {
                                      print('Navigating to ChallengeDetailScreen with challengeId: $challengeId');
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChallengeDetailScreen(
                                            challengeId: challengeId,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              leading: FaIcon(
                                _selectedTab == 'graded'
                                    ? FontAwesomeIcons.checkCircle
                                    : _selectedTab == 'pending'
                                        ? FontAwesomeIcons.clock
                                        : FontAwesomeIcons.timesCircle,
                                size: 24,
                                color: _selectedTab == 'graded'
                                    ? Colors.green
                                    : _selectedTab == 'pending'
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                              title: Text(
                                submission['challenge_title'] ?? 'Unknown Challenge',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isClickable
                                      ? (isDarkMode ? Colors.blue.shade300 : Colors.blue)
                                      : (isDarkMode ? Colors.white70 : Colors.black87),
                                  decoration: isClickable ? TextDecoration.underline : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  _selectedTab == 'graded'
                                      ? Text(
                                          'Score: ${submission['score']?.toString() ?? 'N/A'}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode ? Colors.white70 : Colors.black87,
                                          ),
                                        )
                                      : Text(
                                          'Status: ${_selectedTab[0].toUpperCase() + _selectedTab.substring(1)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode ? Colors.white70 : Colors.black87,
                                          ),
                                        ),
                                ],
                              ),
                            ),
                            if (_selectedTab == 'pending' && challengeId != null)
                              Positioned(
                                top: -6,
                                right: -6,
                                child: Material(
                                  elevation: 2,
                                  borderRadius: BorderRadius.circular(8),
                                  color: isDarkMode ? Colors.orange.shade700 : Colors.orange.shade100,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDarkMode ? Colors.orange.shade500 : Colors.orange.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'Submitted',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: isDarkMode ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
}