import 'package:flutter/material.dart';

class AppColors {
  static const primaryColor = Color(0xFFFFFFFF);
  static const secondaryColor = Color(0xFFAFAAA4);
  static const accentColor = Color(0xFF33ACDF);
  static const textColor = Color(0xFF070707);
}

// app primary theme
ThemeData primaryTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),

  // Scaffold theme
  scaffoldBackgroundColor: AppColors.primaryColor,

  // Elevated Button Theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accentColor,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder()
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.accentColor,
            width: 2
          )
        ))
    )
  ),

  // Text Theme
  textTheme: const TextTheme(
    bodyMedium: TextStyle(
      color: Colors.black,
      fontSize: 16,
      letterSpacing: 1,
    ),
    headlineMedium: TextStyle(
      color: Colors.black,
      fontSize: 18,
      fontWeight: FontWeight.bold,
      letterSpacing: 1,
    ),
    titleMedium: TextStyle(
      color: Colors.black,
      fontSize: 18,
      letterSpacing: 1,
      fontWeight: FontWeight.bold,
    ),
    bodyLarge: TextStyle(
      color: Colors.black,
      fontSize: 18,
      letterSpacing: 1,
    ),
  ),

  // Input Theme
  inputDecorationTheme: InputDecorationTheme(
    fillColor: Colors.white,
    filled: true,
    labelStyle: const TextStyle(color: Colors.black),
    border: UnderlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: Colors.black,
      ),
    ),
    focusedBorder: UnderlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: Colors.black,
      ),
    ),
    enabledBorder: UnderlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: Colors.black,
      ),
    ),
    errorBorder: UnderlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: Colors.red,
      ),
    ),
  ),

  // icons
  iconTheme: const IconThemeData(
    color: Colors.white,
  ),

  //app bar
  appBarTheme: const AppBarTheme(
      elevation: 10,
      shadowColor: AppColors.primaryColor,
      color: AppColors.primaryColor,
      foregroundColor: AppColors.textColor,
      surfaceTintColor: Colors.transparent),
  cardTheme: CardTheme(
    color: AppColors.secondaryColor.withOpacity(0.8),
  ),

  //circular indicator
  progressIndicatorTheme:
  const ProgressIndicatorThemeData(color: AppColors.textColor),

  //floating action button
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.textColor,
    foregroundColor: AppColors.primaryColor,
  ),


);
