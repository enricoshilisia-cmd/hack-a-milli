import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({Key? key}) : super(key: key);

  void _onNavTap(BuildContext context, int index) {
    if (index == 4) {
      _showMoreOptions(context);
    } else {
      String route;
      switch (index) {
        case 0:
          route = '/dashboard';
          break;
        case 1:
          route = '/challenges';
          break;
        case 2:
          route = '/submissions';
          break;
        case 3:
          route = '/my_account';
          break;
        default:
          return;
      }
      Navigator.pushReplacementNamed(context, route);
    }
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
                  // Already on JobsScreen, no action needed
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
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: const CustomAppBar(title: 'Jobs'),
      body: Center(
        child: Text(
          'No jobs posted yet',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.grey,
            fontSize: 16,
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 4, // Highlight "More" item
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }
}