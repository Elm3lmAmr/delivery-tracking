import 'package:flutter/material.dart';

// Edara navy palette matching the web dashboard
const kBg = Color(0xFF0A1628);
const kSurface = Color(0xFF0B1F3A);
const kSurface2 = Color(0xFF142B4F);
const kBorder = Color(0xFF1F3557);
const kText = Color(0xFFE6ECF5);
const kText2 = Color(0xFFB5C1D6);
const kMuted = Color(0xFF8A9BB8);
const kAccent = Color(0xFF4DA3FF);
const kOk = Color(0xFF2ECC71);
const kWarn = Color(0xFFF4B942);
const kCrit = Color(0xFFE74C3C);

ThemeData buildEdaraTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBg,
    primaryColor: kAccent,
    colorScheme: const ColorScheme.dark(
      primary: kAccent,
      onPrimary: kBg,
      surface: kSurface,
      onSurface: kText,
      error: kCrit,
    ),
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: kSurface,
      foregroundColor: kText,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kAccent,
        foregroundColor: kBg,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kAccent, width: 1.5),
      ),
    ),
  );
}
