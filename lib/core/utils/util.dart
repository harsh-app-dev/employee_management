import 'package:employee_management/core/di/injectable_module.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme createTextTheme(
    BuildContext context, String bodyFontString, String displayFontString) {
  TextTheme baseTextTheme = Theme.of(context).textTheme;
  TextTheme bodyTextTheme = GoogleFonts.getTextTheme(bodyFontString, baseTextTheme);
  TextTheme displayTextTheme =
      GoogleFonts.getTextTheme(displayFontString, baseTextTheme);
  TextTheme textTheme = displayTextTheme.copyWith(
    bodyLarge: bodyTextTheme.bodyLarge,
    bodyMedium: bodyTextTheme.bodyMedium,
    bodySmall: bodyTextTheme.bodySmall,
    labelLarge: bodyTextTheme.labelLarge,
    labelMedium: bodyTextTheme.labelMedium,
    labelSmall: bodyTextTheme.labelSmall,
  );
  return textTheme;
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