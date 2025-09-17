import 'dart:io';

import 'package:employee_management/core/di/injectable_module.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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

void showGlobalSnackBarOverlay(String message) {
  final overlay = getIt<GlobalKey<NavigatorState>>().currentState?.overlay;
  if (overlay == null) return;

  final entry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: 50,
      left: 10,
      right: 10,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 3), () => entry.remove());
}

void showGlobalSnackBarWithIcon(String message, {IconData? icon, Color? iconColor}) {
  final key = getIt<GlobalKey<ScaffoldMessengerState>>();
  key.currentState?.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor ?? Colors.white, size: 22),
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

String? formatDuration(String? durationStr) {
  if (durationStr == null || durationStr.isEmpty) return '--';
  try {
    if (durationStr.contains('.')) {
      durationStr = durationStr.split('.')[0];
    }

    final parts = durationStr.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = parts.length > 2 ? int.parse(parts[2]) : 0;

    String result = '';
    if (hours > 0) result += '${hours}h ';
    if (minutes > 0) result += '${minutes}m ';
    if (seconds > 0) result += '${seconds}s ';

    return result.trim();
  } catch (_) {
    return durationStr;
  }
}

String formatTime(String? time, {String? date}) {
  if (time == null || time.isEmpty) return '--:--';

  try {
    // Remove milliseconds if present
    final timeWithoutMillis = time.split('.')[0];

    // If date is provided, combine with time
    if (date != null) {
      return DateFormat('hh:mm a').format(DateTime.parse('${date}T$timeWithoutMillis'));
    }
    // For time-only strings (HH:mm:ss)
    else {
      return DateFormat('hh:mm a').format(DateFormat('HH:mm:ss').parse(timeWithoutMillis));
    }
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


Future<bool> checkInternet(BuildContext context) async {
  final connectivityResult = await Connectivity().checkConnectivity();

  if (connectivityResult == ConnectivityResult.none) {
    _showNoInternet(context);
    return false;
  }

  // Extra step: verify actual internet access
  try {
    final result = await InternetAddress.lookup('example.com');
    if (result.isEmpty || result[0].rawAddress.isEmpty) {
      _showNoInternet(context);
      return false;
    }
  } on SocketException {
    _showNoInternet(context);
    return false;
  }

  return true;
}

void _showNoInternet(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("No internet connection"),
      backgroundColor: Colors.red,
    ),
  );
}

Future<bool> showPunchConfirmationDialog(
    BuildContext context, {required bool isPunchOut,}) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),),
        backgroundColor: const Color(0xFFF5F7EC),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${isPunchOut ? 'Punch Out' : 'Punch In'} Confirmation!",
                style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,),
              ),
              const SizedBox(height: 12),
              Text(
                "Are you sure you want to ${isPunchOut
                    ? 'punch out'
                    : 'punch in'} for today?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      textStyle: const TextStyle(fontSize: 14),),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10,),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Yes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  ) ?? false;
}
/// ✅ New: Request Location Permission
Future<void> requestLocationPermission() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    await Geolocator.openLocationSettings();
    return;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    showGlobalSnackBarWithIcon("Location permission is required",
        icon: Icons.location_off, iconColor: Colors.red);
  }
}
