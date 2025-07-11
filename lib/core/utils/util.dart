import 'package:employee_management/core/di/injectable_module.dart';
import 'package:flutter/material.dart';

TextTheme createTextTheme(
    BuildContext context, String bodyFontString, String displayFontString) {
  return Theme.of(context).textTheme;
}

String themedAsset(BuildContext context, String assetName) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return 'assets/images/${isDark ? 'dark' : 'light'}/$assetName';
}

void showGlobalSnackBar(String message) {
  final key = getIt<GlobalKey<ScaffoldMessengerState>>();
  key.currentState?.showSnackBar(
    SnackBar(content: Text(message)),
  );
}

String formatTime(String? time) {
  if (time == null || time.isEmpty) return '0hrs';
  final parts = time.split(':');
  if (parts.length != 3) return time;
  final hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts[1]) ?? 0;
  if (hours > 0 && minutes == 0) {
    return '$hours hrs';
  } else if (hours == 0 && minutes > 0) {
    return '$minutes Minutes';
  } else if (hours > 0 && minutes > 0) {
    return '$hours hrs $minutes Minutes';
  } else {
    return '0 Minutes';
  }
}

String getInitials(String? firstName, String? lastName) {
  String first = (firstName != null && firstName.isNotEmpty)
      ? firstName[0]
      : '';
  String last = (lastName != null && lastName.isNotEmpty) ? lastName[0] : '';
  return (first + last).toUpperCase();
}