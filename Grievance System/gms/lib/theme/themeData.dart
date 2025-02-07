import 'package:flutter/material.dart';

class AppColors {
  static const primaryColor = Color(0xFF2E5077);
  static const secondaryColor = Color(0xFF2A3335);
}

ThemeData themeData = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),

  //scaffold
  scaffoldBackgroundColor: AppColors.primaryColor,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primaryColor,
    centerTitle: true,
    titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
  ),

  //text
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
    bodySmall: TextStyle(color: Colors.white),
    headlineLarge: TextStyle(color: Colors.white),
    headlineMedium: TextStyle(color: Colors.white),
    headlineSmall: TextStyle(color: Colors.white),
    titleLarge: TextStyle(color: Colors.white),
    titleMedium: TextStyle(color: Colors.white),
    titleSmall: TextStyle(color: Colors.white),
  ),

  //input
  inputDecorationTheme: InputDecorationTheme(
    fillColor: AppColors.primaryColor,
    hintStyle: TextStyle(color: AppColors.secondaryColor),
    border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
    focusedBorder:
        UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
    enabledBorder:
        UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
    errorBorder:
        UnderlineInputBorder(borderSide: BorderSide(color: Colors.red)),
  ),

  //progress indicator
  progressIndicatorTheme: ProgressIndicatorThemeData(
    color: Colors.white,
  ),

  //floating action button
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.white,
    foregroundColor: AppColors.primaryColor,
  ),

  // icons
  iconTheme: const IconThemeData(
    color: Colors.white,
  ),

  //text button
  textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
    textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF2E5077),
    padding: EdgeInsets.all(20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero), // No border
  )),
);
