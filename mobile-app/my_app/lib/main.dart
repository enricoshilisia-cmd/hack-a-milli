import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'theme_provider.dart';
import 'themes.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/profile_update_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/challenges_screen.dart';
import 'screens/submissions_screen.dart';
import 'screens/my_account_screen.dart';
import 'screens/jobs_screen.dart';
import 'widgets/custom_app_bar.dart';
import 'widgets/custom_bottom_nav_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'SkillProof',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            routes: {
              '/login': (context) => LoginScreen(),
              '/register': (context) => RegisterScreen(),
              '/profile_update': (context) => const ProfileUpdateScreen(),
              '/dashboard': (context) => const HomeScreen(initialIndex: 0),
              '/challenges': (context) => const HomeScreen(initialIndex: 1),
              '/submissions': (context) => const HomeScreen(initialIndex: 2),
              '/my_account': (context) => const HomeScreen(initialIndex: 3),
              '/jobs': (context) => const JobsScreen(),
            },
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return auth.isAuthenticated ? const HomeScreen(initialIndex: 0) : LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  late PageController _pageController;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ChallengesScreen(),
    const SubmissionsScreen(),
    const MyAccountScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Available Challenges',
    'Submissions',
    'My Account',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    print('Initial index: $_currentIndex'); // Debug initial index
  }

  void _onNavTap(int index) {
    if (index == 4) {
      _showMoreOptions(context);
    } else {
      print('Nav tapped: $index'); // Debug nav tap
      _pageController.jumpToPage(index);
    }
  }

  void _onPageChanged(int index) {
    print('Page changed to: $index, title: ${_titles[index]}'); // Debug page change
    setState(() {
      _currentIndex = index;
    });
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: FaIcon(FontAwesomeIcons.briefcase, size: 20),
                title: const Text('Jobs', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/jobs');
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
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: FaIcon(FontAwesomeIcons.signOutAlt, size: 20),
                title: const Text('Logout', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: _titles[_currentIndex]),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _screens,
        physics: const BouncingScrollPhysics(),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}