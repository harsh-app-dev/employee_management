import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../state/getx/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkTheme = false;
  String _selectedLanguage = 'English';
  bool _notificationsEnabled = false;

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text('English'),
                value: 'English',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: Text('Hindi'),
                value: 'Hindi',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
              // Add more languages as needed
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final ThemeController themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.language),
            title: Text('Language'),
            subtitle: Text(_selectedLanguage),
            onTap: _showLanguageDialog,
          ),
          Obx(() =>
              ListTile(
                leading: Icon(Icons.dark_mode),
                title: Text('Dark Mode'),
                trailing: Switch(
                    value: themeController.themeMode.value == ThemeMode.dark,
                    onChanged: (isDark) {
                      themeController.setThemeMode(
                          isDark ? ThemeMode.dark : ThemeMode.light
                      );
                    }),
              )),
          SwitchListTile(
            secondary: Icon(Icons.notifications_active),
            title: Text('Notification Permission'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              // Add logic to request/revoke notification permission if needed
            },
          ),
        ],
      ),
    );
  }
} 