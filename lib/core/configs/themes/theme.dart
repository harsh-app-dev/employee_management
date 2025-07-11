import 'package:employee_management/core/utils/util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light([BuildContext? context]) {
    return _themeData(_lightScheme, context);
  }

  static ThemeData dark([BuildContext? context]) {
    return _themeData(_darkScheme, context);
  }

  static final ColorScheme _lightScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xff3a693b),
    surfaceTint: Color(0xff3a693b),
    onPrimary: Color(0xffffffff),
    primaryContainer: Color(0xffbbf0b5),
    onPrimaryContainer: Color(0xff225025),
    secondary: Color(0xff52634f),
    onSecondary: Color(0xffffffff),
    secondaryContainer: Color(0xffd5e8cf),
    onSecondaryContainer: Color(0xff3b4b39),
    tertiary: Color(0xff39656b),
    onTertiary: Color(0xffffffff),
    tertiaryContainer: Color(0xffbcebf1),
    onTertiaryContainer: Color(0xff1f4d53),
    error: Color(0xffba1a1a),
    onError: Color(0xffffffff),
    errorContainer: Color(0xffffdad6),
    onErrorContainer: Color(0xff93000a),
    surface: Color(0xfff7fbf1),
    onSurface: Color(0xff181d17),
    onSurfaceVariant: Color(0xff424940),
    outline: Color(0xff72796f),
    outlineVariant: Color(0xffc2c9bd),
    shadow: Color(0xff000000),
    scrim: Color(0xff000000),
    inverseSurface: Color(0xff2d322c),
    inversePrimary: Color(0xffa0d49b),
    primaryFixed: Color(0xffbbf0b5),
    onPrimaryFixed: Color(0xff002105),
    primaryFixedDim: Color(0xffa0d49b),
    onPrimaryFixedVariant: Color(0xff225025),
    secondaryFixed: Color(0xffd5e8cf),
    onSecondaryFixed: Color(0xff101f10),
    secondaryFixedDim: Color(0xffb9ccb4),
    onSecondaryFixedVariant: Color(0xff3b4b39),
    tertiaryFixed: Color(0xffbcebf1),
    onTertiaryFixed: Color(0xff001f23),
    tertiaryFixedDim: Color(0xffa1ced5),
    onTertiaryFixedVariant: Color(0xff1f4d53),
    surfaceDim: Color(0xffd7dbd2),
    surfaceBright: Color(0xfff7fbf1),
    surfaceContainerLowest: Color(0xffffffff),
    surfaceContainerLow: Color(0xfff1f5ec),
    surfaceContainer: Color(0xffebefe6),
    surfaceContainerHigh: Color(0xffe6e9e0),
    surfaceContainerHighest: Color(0xffe0e4db),
  );

  static final ColorScheme _darkScheme = const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xff3a693b),
    surfaceTint: Color(0xff3a693b),
    onPrimary: Color(0xffffffff),
    primaryContainer: Color(0xffbbf0b5),
    onPrimaryContainer: Color(0xff225025),
    secondary: Color(0xff52634f),
    onSecondary: Color(0xffffffff),
    secondaryContainer: Color(0xffd5e8cf),
    onSecondaryContainer: Color(0xff3b4b39),
    tertiary: Color(0xff39656b),
    onTertiary: Color(0xffffffff),
    tertiaryContainer: Color(0xffbcebf1),
    onTertiaryContainer: Color(0xff1f4d53),
    error: Color(0xffba1a1a),
    onError: Color(0xffffffff),
    errorContainer: Color(0xffffdad6),
    onErrorContainer: Color(0xff93000a),
    surface: Color(0xfff7fbf1),
    onSurface: Color(0xff181d17),
    onSurfaceVariant: Color(0xff424940),
    outline: Color(0xff72796f),
    outlineVariant: Color(0xffc2c9bd),
    shadow: Color(0xff000000),
    scrim: Color(0xff000000),
    inverseSurface: Color(0xff2d322c),
    inversePrimary: Color(0xffa0d49b),
    primaryFixed: Color(0xffbbf0b5),
    onPrimaryFixed: Color(0xff002105),
    primaryFixedDim: Color(0xffa0d49b),
    onPrimaryFixedVariant: Color(0xff225025),
    secondaryFixed: Color(0xffd5e8cf),
    onSecondaryFixed: Color(0xff101f10),
    secondaryFixedDim: Color(0xffb9ccb4),
    onSecondaryFixedVariant: Color(0xff3b4b39),
    tertiaryFixed: Color(0xffbcebf1),
    onTertiaryFixed: Color(0xff001f23),
    tertiaryFixedDim: Color(0xffa1ced5),
    onTertiaryFixedVariant: Color(0xff1f4d53),
  );

  static ThemeData _themeData(ColorScheme scheme, BuildContext? context) {
    final textTheme = context != null
        ? createTextTheme(context, 'Poppins', 'Poppins')
        : GoogleFonts.poppinsTextTheme();

    final bodyTextTheme = GoogleFonts.getTextTheme('Poppins', textTheme);
    final displayTextTheme = GoogleFonts.getTextTheme('Poppins', textTheme);

    final mergedTextTheme = displayTextTheme.copyWith(
      bodyLarge: bodyTextTheme.bodyLarge,
      bodyMedium: bodyTextTheme.bodyMedium,
      bodySmall: bodyTextTheme.bodySmall,
      labelLarge: bodyTextTheme.labelLarge,
      labelMedium: bodyTextTheme.labelMedium,
      labelSmall: bodyTextTheme.labelSmall,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      textTheme: mergedTextTheme,
    );
  }
}
