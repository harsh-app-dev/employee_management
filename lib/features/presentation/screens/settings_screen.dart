import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../state/getx/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          Obx(
            () => ListTile(
              leading: Icon(Icons.dark_mode),
              title: Text('Dark Mode'),
              trailing: Switch(
                value: themeController.themeMode.value == ThemeMode.dark,
                onChanged: (isDark) {
                  themeController.setThemeMode(
                    isDark ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
