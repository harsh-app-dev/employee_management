import 'package:employee_management/core/di/injectable_module.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

void showGlobalSnackBarWithIcon(String message, IconData icon, {Color? iconColor}) {
  final key = getIt<GlobalKey<ScaffoldMessengerState>>();
  key.currentState?.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: iconColor ?? Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

String formatDuration(String? durationStr) {
  if (durationStr == null || durationStr.isEmpty) return '--';
  try {
    final parts = durationStr.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    String result = '';
    if (hours > 0) result += '${hours}h ';
    if (minutes > 0) result += '${minutes}m ';
    return result.trim();
  } catch (_) {
    return durationStr;
  }
}

String formatTime(String? isoTime) {
  if (isoTime == null || isoTime.isEmpty) return '--:--';
  try {
    final dateTime = DateTime.parse(isoTime);
    return DateFormat('hh:mm a').format(dateTime);
  } catch (_) {
    return '--:--';
  }
}

String calculateWorkedTime(String? punchIn, String? punchOut) {
  if (punchIn == null || punchOut == null) return '--';
  try {
    final inTime = DateTime.parse(punchIn);
    final outTime = DateTime.parse(punchOut);
    final diff = outTime.difference(inTime);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;
    String result = '';
    if (hours > 0) result += '${hours}h ';
    if (minutes > 0) result += '${minutes}m ';
    if (seconds > 0 || (hours == 0 && minutes == 0)) result += '${seconds}s';
    return result.trim();
  } catch (_) {
    return '--';
  }
}

String getInitials(String? firstName, String? lastName) {
  String first = (firstName != null && firstName.isNotEmpty)
      ? firstName[0]
      : '';
  String last = (lastName != null && lastName.isNotEmpty) ? lastName[0] : '';
  return (first + last).toUpperCase();
}

String formatTimeSpent(String? time) {
  if (time == null || time.isEmpty) return '--:--';
  try {
    final t = time.split(':').map(int.parse).toList();
    final h = t[0], m = t[1];
    return h > 0 && m > 0 ? '${h}h ${m}m' : h > 0 ? '${h}h' : m > 0 ? '${m}m' : '<1m';
  } catch (_) {
    return '--:--';
  }
}

String getDeductionInitials(String type) {
  final t = type.trim().toLowerCase();
  if (t.contains('half')) return 'HD';
  if (t.contains('full')) return 'FD';
  if (t.contains('short')) return 'SL';
  return t.split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
}