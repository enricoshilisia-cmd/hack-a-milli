import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/challenge.dart';
import '../models/submission.dart';
import '../services/challenge_service.dart';
import '../widgets/input_decoration.dart';
import 'challenge_detail_screen.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({Key? key}) : super(key: key);

  @override
  _ChallengesScreenState createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  static List<Map<String, dynamic>>? _cachedChallengesWithStatus;
  static List<Map<String, dynamic>>? _cachedFilteredChallengesWithStatus;
  List<Map<String, dynamic>>? _challengesWithStatus;
  List<Map<String, dynamic>>? _filteredChallengesWithStatus;
  bool _isLoading = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadChallenges();
    _searchController.addListener(_filterChallenges);
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);
    try {
      // Check if cached data is available
      if (_cachedChallengesWithStatus != null && _cachedFilteredChallengesWithStatus != null) {
        setState(() {
          _challengesWithStatus = _cachedChallengesWithStatus;
          _filteredChallengesWithStatus = _cachedFilteredChallengesWithStatus;
          _isLoading = false;
        });
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final allChallenges = await ChallengeService().getAvailableChallenges(authProvider.token!);
      final submissions = await ChallengeService().getUserSubmissions(authProvider.token!);
      final challengesWithStatus = allChallenges.map((challenge) {
        final submission = submissions.firstWhere(
          (sub) => sub.challengeId == challenge.id,
          orElse: () => Submission(id: 0, challengeId: 0, status: ''),
        );
        if (submission.status == '' || submission.status.toLowerCase() == 'pending') {
          return {
            'challenge': challenge,
            'submissionStatus': submission.status,
          };
        }
        return null;
      }).where((item) => item != null).cast<Map<String, dynamic>>().toList();

      setState(() {
        _challengesWithStatus = challengesWithStatus;
        _filteredChallengesWithStatus = challengesWithStatus;
        // Cache the data
        _cachedChallengesWithStatus = _challengesWithStatus;
        _cachedFilteredChallengesWithStatus = _filteredChallengesWithStatus;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load challenges: $e',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Method to clear cache and refresh data
  Future<void> _refreshData() async {
    _cachedChallengesWithStatus = null;
    _cachedFilteredChallengesWithStatus = null;
    await _loadChallenges();
  }

  void _filterChallenges() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredChallengesWithStatus = _challengesWithStatus;
        _cachedFilteredChallengesWithStatus = _filteredChallengesWithStatus;
      } else {
        _filteredChallengesWithStatus = _challengesWithStatus?.where((item) {
          final challenge = item['challenge'] as Challenge;
          final title = challenge.title?.toLowerCase() ?? '';
          final type = challenge.challengeType?.toLowerCase() ?? '';
          return title.contains(query) || type.contains(query);
        }).toList();
        _cachedFilteredChallengesWithStatus = _filteredChallengesWithStatus;
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterChallenges);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: Theme.of(context).cardColor,
              collapsedHeight: 56,
              toolbarHeight: 56,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                title: TextField(
                  controller: _searchController,
                  decoration: buildInputDecoration(
                    context,
                    'Search by title or type',
                    const Icon(Icons.search, size: 18),
                  ).copyWith(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: 18,
                              color: isDarkMode ? Colors.white70 : Colors.grey.shade900,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade900,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_isLoading)
                    Center(
                      child: CircularProgressIndicator(
                        color: isDarkMode ? Colors.white70 : Theme.of(context).primaryColor,
                      ),
                    )
                  else if (_challengesWithStatus == null || _challengesWithStatus!.isEmpty)
                    Text(
                      'No challenges available',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.grey,
                        fontSize: 16,
                      ),
                    )
                  else if (_filteredChallengesWithStatus == null || _filteredChallengesWithStatus!.isEmpty)
                    Text(
                      'No matching challenges found',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.grey,
                        fontSize: 16,
                      ),
                    )
                  else
                    ..._filteredChallengesWithStatus!.map((item) => _buildChallengeCard(item['challenge'] as Challenge, item['submissionStatus'] as String)).toList(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(Challenge challenge, String submissionStatus) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String daysRemainingText;
    try {
      final endDate = DateTime.parse(challenge.endDate);
      final now = DateTime.now();
      final difference = endDate.difference(DateTime(now.year, now.month, now.day)).inDays;
      daysRemainingText = difference > 0 ? '$difference days left' : 'Ended';
    } catch (e) {
      daysRemainingText = 'N/A';
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          elevation: 4,
          shape: Theme.of(context).cardTheme.shape,
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            borderRadius: (Theme.of(context).cardTheme.shape as RoundedRectangleBorder?)?.borderRadius as BorderRadius? ?? BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChallengeDetailScreen(challengeId: challenge.id),
                ),
              );
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 100),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'thumbnail-${challenge.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: challenge.thumbnail != null
                              ? Image.network(
                                  'https://api.skillproof.me.ke${challenge.thumbnail}',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 40,
                                    height: 40,
                                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                    child: Icon(
                                      FontAwesomeIcons.image,
                                      size: 20,
                                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 40,
                                  height: 40,
                                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                  child: Icon(
                                    FontAwesomeIcons.image,
                                    size: 20,
                                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Hero(
                          tag: 'title-${challenge.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              challenge.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    challenge.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          challenge.difficulty,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        backgroundColor: _getDifficultyColor(challenge.difficulty, isDarkMode),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 4),
                      Chip(
                        label: Text(
                          challenge.challengeType,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        backgroundColor: isDarkMode ? Colors.blue.shade700 : Colors.blue.shade100,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 4),
                      Chip(
                        label: Text(
                          daysRemainingText,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (submissionStatus.toLowerCase() == 'pending')
          Positioned(
            top: -6,
            right: -6,
            child: Material(
              elevation: 6,
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
    );
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
}