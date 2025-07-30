import 'package:employee_management/features/presentation/screens/main_screen.dart';
import 'package:flutter/material.dart';
import '../../features/data/models/floor/profile_data.dart';
import '../../features/presentation/screens/history_screen.dart';
import '../../features/presentation/screens/profile_screen.dart';
import 'package:employee_management/core/di/injectable_module.dart';
import 'package:employee_management/features/presentation/state/profile_controller.dart';
import 'package:employee_management/core/utils/util.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/presentation/screens/settings_screen.dart';

class AppSideDrawer extends StatefulWidget {
  @override
  State<AppSideDrawer> createState() => _AppSideDrawerState();
}

class _AppSideDrawerState extends State<AppSideDrawer> {
  final ProfileController _profileController = getIt<ProfileController>();
  Profile? _localProfile;

  @override
  void initState() {
    super.initState();
    _loadLocalProfile();
  }

  Future<void> _loadLocalProfile() async {
    final profiles = await _profileController.profileDao.getAllProfiles();
    setState(() {
      _localProfile = profiles.isNotEmpty ? profiles.first : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24.0, bottom: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ProfileScreen()),
                        );
                      },
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white,
                        child: Text(
                          _localProfile != null
                              ? getInitials(_localProfile!.first_name, _localProfile!.last_name)
                              : '?',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0, bottom: 10.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ProfileScreen()),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _localProfile != null
                                ? ('${_localProfile!.first_name} ${_localProfile!.last_name}').trim()
                                : '--',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (_localProfile?.email != null && _localProfile!.email.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                _localProfile!.email,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: Icon(Icons.dashboard, size: 24),
                  title: Text('Dashboard'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => MainScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.history, size: 24),
                  title: Text('History'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => HistoryScreen()));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings, size: 24),
                  title: Text('Settings'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => SettingsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.support_agent, size: 24),
                  title: Text('Help & Support'),
                  onTap: () {
                    // Add navigation or support logic here
                  },
                ),
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined, size: 24),
                  title: Text('Privacy Policy'),
                  onTap: () async {
                    final url = Uri.parse('https://sparkbrains.in/privacy-policy/');
                    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open the Privacy Policy.')),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.info_outline, size: 24),
                  title: Text('About'),
                  onTap: () async {
                    final url = Uri.parse('https://sparkbrains.in/about-us/');
                    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open the About page.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(indent: 16, endIndent: 16, height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.logout),
                label: Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await _profileController.logout();
                  getIt<GlobalKey<NavigatorState>>().currentState
                      ?.pushNamedAndRemoveUntil('/login', (route) => false);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
