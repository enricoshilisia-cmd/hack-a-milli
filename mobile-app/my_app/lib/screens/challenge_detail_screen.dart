import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../models/challenge.dart';
import '../models/submission.dart';
import '../services/challenge_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/input_decoration.dart';
import '../theme_provider.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final int challengeId;

  const ChallengeDetailScreen({Key? key, required this.challengeId}) : super(key: key);

  @override
  _ChallengeDetailScreenState createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  Challenge? _challenge;
  Submission? _submission;
  bool _isLoading = false;
  bool _isTasksExpanded = false;
  bool _isRubricsExpanded = false;
  bool _isAttachmentsExpanded = false;
  final TextEditingController _repoLinkController = TextEditingController();
  List<File> _selectedFiles = [];
  late FToast fToast;

  @override
  void initState() {
    super.initState();
    fToast = FToast();
    fToast.init(context);
    _loadChallengeDetails();
  }

  Future<void> _loadChallengeDetails() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final challenge = await ChallengeService().getChallengeDetails(widget.challengeId, authProvider.token!);
      // Fetch user's submission for this challenge
      final submissions = await ChallengeService().getUserSubmissions(authProvider.token!);
      final submission = submissions.firstWhere(
        (sub) => sub.challengeId == widget.challengeId && sub.status.toLowerCase() == 'pending',
        orElse: () => Submission(id: 0, challengeId: 0, status: ''),
      );
      setState(() {
        _challenge = challenge;
        _submission = submission.status.isNotEmpty ? submission : null;
        if (_submission != null && _submission!.repoLink != null) {
          _repoLinkController.text = _submission!.repoLink!;
        }
      });
    } catch (e) {
      _showErrorToast('Failed to load challenge details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.files.map((file) => File(file.path!)));
      });
    }
  }

  Future<void> _submitChallenge() async {
    if (_repoLinkController.text.isEmpty) {
      _showErrorToast('Please enter a repository link');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final files = _selectedFiles.isNotEmpty
          ? await Future.wait(
              _selectedFiles.map((file) async => await http.MultipartFile.fromPath(
                    'files',
                    file.path,
                    contentType: MediaType('application', 'octet-stream'),
                  )),
            )
          : null;

      await ChallengeService().submitChallenge(
        widget.challengeId,
        authProvider.token!,
        _repoLinkController.text,
        files: files,
      );

      _showSuccessToast();
      Navigator.pop(context);
    } catch (e) {
      _showErrorToast('Failed to submit challenge: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessToast() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: isDarkMode ? Colors.blue.shade700 : Colors.blue.shade100,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, color: isDarkMode ? Colors.white70 : Colors.blue.shade900),
          const SizedBox(width: 12.0),
          Text(
            "Challenge submitted successfully!",
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.blue.shade900,
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.TOP,
      toastDuration: const Duration(seconds: 2),
    );
  }

  void _showErrorToast(String message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Truncate message to 50 characters to prevent overflow
    final truncatedMessage = message.length > 50 ? '${message.substring(0, 47)}...' : message;
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: isDarkMode ? Colors.red.shade700 : Colors.red.shade100,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error, color: isDarkMode ? Colors.white70 : Colors.red.shade900),
          const SizedBox(width: 12.0),
          Text(
            truncatedMessage,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.red.shade900,
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.TOP,
      toastDuration: const Duration(seconds: 2),
    );
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showErrorToast('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String daysRemainingText;
    if (_challenge != null) {
      try {
        final endDate = DateTime.parse(_challenge!.endDate);
        final now = DateTime.now();
        final difference = endDate.difference(DateTime(now.year, now.month, now.day)).inDays;
        daysRemainingText = difference > 0 ? '$difference days left' : 'Ended';
      } catch (e) {
        daysRemainingText = 'N/A';
      }
    } else {
      daysRemainingText = 'N/A';
    }

    return Scaffold(
      appBar: CustomAppBar(title: _challenge?.title ?? 'Challenge Details'),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        onTap: _onNavTap,
      ),
      body: Stack(
        children: [
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: isDarkMode ? Colors.white70 : Theme.of(context).primaryColor,
                  ),
                )
              : _challenge == null
                  ? Center(
                      child: Text(
                        'Challenge not found',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 2,
                            shape: Theme.of(context).cardTheme.shape,
                            color: Theme.of(context).cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Hero(
                                    tag: 'thumbnail-${widget.challengeId}',
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        height: 120,
                                        width: double.infinity,
                                        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                        child: _challenge!.thumbnail != null
                                            ? Image.network(
                                                'https://api.skillproof.me.ke${_challenge!.thumbnail}',
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Icon(
                                                  FontAwesomeIcons.image,
                                                  size: 40,
                                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                                ),
                                              )
                                            : Icon(
                                                FontAwesomeIcons.image,
                                                size: 40,
                                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Hero(
                                    tag: 'title-${widget.challengeId}',
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Text(
                                        _challenge!.title,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode ? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      Chip(
                                        label: Text(
                                          _challenge!.difficulty,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDarkMode ? Colors.white70 : Colors.black87,
                                          ),
                                        ),
                                        backgroundColor: _getDifficultyColor(_challenge!.difficulty, isDarkMode),
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                      ),
                                      Chip(
                                        label: Text(
                                          _challenge!.challengeType,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDarkMode ? Colors.white70 : Colors.black87,
                                          ),
                                        ),
                                        backgroundColor: isDarkMode ? Colors.blue.shade700 : Colors.blue.shade100,
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                      ),
                                      Chip(
                                        label: Text(
                                          daysRemainingText,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDarkMode ? Colors.white70 : Colors.black87,
                                          ),
                                        ),
                                        backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            elevation: 2,
                            shape: Theme.of(context).cardTheme.shape,
                            color: Theme.of(context).cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Description',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _challenge!.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: isDarkMode ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 2,
                            shape: Theme.of(context).cardTheme.shape,
                            color: Theme.of(context).cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Categories',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: _challenge!.categories.map((category) => Chip(
                                          label: Text(
                                            category['name'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDarkMode ? Colors.white70 : Colors.black87,
                                            ),
                                          ),
                                          backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                        )).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_challenge!.tasks.isNotEmpty)
                            Card(
                              elevation: 2,
                              shape: Theme.of(context).cardTheme.shape,
                              color: Theme.of(context).cardColor,
                              child: ExpansionTile(
                                title: Text(
                                  'Tasks',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                leading: FaIcon(
                                  FontAwesomeIcons.list,
                                  size: 18,
                                  color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                                ),
                                initiallyExpanded: _isTasksExpanded,
                                onExpansionChanged: (expanded) => setState(() => _isTasksExpanded = expanded),
                                children: _challenge!.tasks.map((task) {
                                  return ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                    title: Text(
                                      task['title'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDarkMode ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                    subtitle: Text(
                                      task['description'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDarkMode ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                    trailing: task['is_mandatory']
                                        ? Icon(
                                            Icons.star,
                                            size: 18,
                                            color: isDarkMode ? Colors.yellow.shade300 : Colors.yellow,
                                          )
                                        : null,
                                  );
                                }).toList(),
                              ),
                            ),
                          const SizedBox(height: 8),
                          if (_challenge!.rubrics.isNotEmpty)
                            Card(
                              elevation: 2,
                              shape: Theme.of(context).cardTheme.shape,
                              color: Theme.of(context).cardColor,
                              child: ExpansionTile(
                                title: Text(
                                  'Rubrics',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                leading: FaIcon(
                                  FontAwesomeIcons.checkCircle,
                                  size: 18,
                                  color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                                ),
                                initiallyExpanded: _isRubricsExpanded,
                                onExpansionChanged: (expanded) => setState(() => _isRubricsExpanded = expanded),
                                children: _challenge!.rubrics.map((rubric) {
                                  return ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                    title: Text(
                                      rubric['criterion'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDarkMode ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Score: ${rubric['max_score']} (Weight: ${rubric['weight']})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDarkMode ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          const SizedBox(height: 8),
                          if (_challenge!.attachments.isNotEmpty)
                            Card(
                              elevation: 2,
                              shape: Theme.of(context).cardTheme.shape,
                              color: Theme.of(context).cardColor,
                              child: ExpansionTile(
                                title: Text(
                                  'Attachments',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                leading: FaIcon(
                                  FontAwesomeIcons.paperclip,
                                  size: 18,
                                  color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                                ),
                                initiallyExpanded: _isAttachmentsExpanded,
                                onExpansionChanged: (expanded) => setState(() => _isAttachmentsExpanded = expanded),
                                children: _challenge!.attachments.map((attachment) {
                                  return ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                    title: Text(
                                      attachment['description'] ?? 'Attachment',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDarkMode ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                    subtitle: Text(
                                      attachment['file'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDarkMode ? Colors.white70 : Colors.black87,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    trailing: attachment['is_required']
                                        ? Icon(
                                            Icons.star,
                                            size: 18,
                                            color: isDarkMode ? Colors.yellow.shade300 : Colors.yellow,
                                          )
                                        : null,
                                  );
                                }).toList(),
                              ),
                            ),
                          const SizedBox(height: 8),
                          if (_submission != null)
                            Card(
                              elevation: 2,
                              shape: Theme.of(context).cardTheme.shape,
                              color: Theme.of(context).cardColor,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Submission Status',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? Colors.white70 : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            color: isDarkMode ? Colors.orange.shade700 : Colors.orange.shade100,
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
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (_submission!.repoLink != null && _submission!.repoLink!.isNotEmpty)
                                      InkWell(
                                        onTap: () => _launchUrl(_submission!.repoLink!),
                                        child: Row(
                                          children: [
                                            FaIcon(
                                              FontAwesomeIcons.link,
                                              size: 16,
                                              color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _submission!.repoLink!,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                                                  decoration: TextDecoration.underline,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (_submission!.files.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Submitted Files:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDarkMode ? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ..._submission!.files.map((file) => Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            child: Row(
                                              children: [
                                                FaIcon(
                                                  FontAwesomeIcons.file,
                                                  size: 16,
                                                  color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    file.split('/').last,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDarkMode ? Colors.white70 : Colors.black87,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 2,
                            shape: Theme.of(context).cardTheme.shape,
                            color: Theme.of(context).cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Submit Solution',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _repoLinkController,
                                    decoration: buildInputDecoration(
                                      context,
                                      'Repository Link',
                                      const Icon(Icons.link),
                                      isRequired: true,
                                    ).copyWith(
                                      suffixIcon: _repoLinkController.text.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.clear,
                                                size: 18,
                                                color: isDarkMode ? Colors.white70 : Colors.grey.shade900,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _repoLinkController.clear();
                                                });
                                              },
                                            )
                                          : null,
                                    ),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode ? Colors.white70 : Colors.grey.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: _pickFiles,
                                    icon: const FaIcon(FontAwesomeIcons.upload, size: 16),
                                    label: const Text('Select Files (Optional)', style: TextStyle(fontSize: 14)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                                      foregroundColor: isDarkMode ? Colors.white70 : Colors.black87,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                  if (_selectedFiles.isNotEmpty)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        Text(
                                          'Selected Files:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode ? Colors.white70 : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        ..._selectedFiles.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final file = entry.value;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            child: Row(
                                              children: [
                                                FaIcon(
                                                  FontAwesomeIcons.file,
                                                  size: 16,
                                                  color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    file.path.split('/').last,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDarkMode ? Colors.white70 : Colors.black87,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.delete,
                                                    size: 18,
                                                    color: isDarkMode ? Colors.red.shade300 : Colors.red,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedFiles.removeAt(index);
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
          if (_challenge != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitChallenge,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        ),
                      Text(
                        _isLoading ? 'Submitting...' : 'Submit',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.blue.shade700 : Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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