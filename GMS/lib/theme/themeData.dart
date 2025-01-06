import 'package:flutter/material.dart';

//colors used in app
class AppColors{
  static const primaryColor = Color(0xFF000814);
  static const secondaryColor  = Color(0xFF001d3d);
  static const accentColor  = Color(0xFF31572c);
  static const textColor  = Color(0xFFFFFFFF);
}

ThemeData primaryTheme = ThemeData(

  //colorScheme
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),

  //Scaffold
  scaffoldBackgroundColor: AppColors.primaryColor,

  //Elevated Button
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.secondaryColor,
      foregroundColor: AppColors.textColor
    )
  ),

  //Text colors
  textTheme: const TextTheme(
    bodyMedium: TextStyle(
      color: AppColors.textColor,
      fontSize: 16,
      letterSpacing: 1,
    ),
    headlineMedium: TextStyle(
      color: AppColors.textColor,
      fontSize: 18,
      fontWeight: FontWeight.bold,
      letterSpacing: 1,
    ),
    titleMedium: TextStyle(
      color: AppColors.textColor,
      fontSize: 18,
      letterSpacing: 1,
      fontWeight: FontWeight.bold,
    ),
    bodyLarge: TextStyle(
      color: AppColors.textColor,
      fontSize: 18,
      letterSpacing: 1,
    ),
  ),

  //Input colors
  inputDecorationTheme: InputDecorationTheme(
    fillColor: AppColors.textColor,
    filled: true,
    labelStyle: const TextStyle(color: AppColors.textColor),
    border: UnderlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: AppColors.accentColor,
      ),
    ),
    focusedBorder: UnderlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: AppColors.textColor,
      ),
    ),
    enabledBorder: UnderlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: AppColors.textColor,
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