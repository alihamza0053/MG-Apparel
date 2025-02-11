import 'package:flutter/material.dart';

class AppColors {
  static const primaryColor = Color(0xFF32ABDF);
  static const secondaryColor = Color(0xFF454D50);
}

ThemeData themeData = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),

  fontFamily: 'aptos',

  //scaffold
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primaryColor,
    centerTitle: true,
    titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
  ),

  //text
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.black,fontWeight: FontWeight.w800),
    bodyMedium: TextStyle(color: Colors.black,fontWeight: FontWeight.normal),
    bodySmall: TextStyle(color: Colors.black,fontWeight: FontWeight.w200),
    headlineLarge: TextStyle(color: Colors.black,fontWeight: FontWeight.w800),
    headlineMedium: TextStyle(color: Colors.black,fontWeight: FontWeight.normal),
    headlineSmall: TextStyle(color: Colors.black,fontWeight: FontWeight.w200),
    titleLarge: TextStyle(color: Colors.black,fontWeight: FontWeight.w800),
    titleMedium: TextStyle(color: Colors.black,fontWeight: FontWeight.normal),
    titleSmall: TextStyle(color: Colors.black,fontWeight: FontWeight.w200),
  ),

  //input
  inputDecorationTheme: InputDecorationTheme(
    fillColor: AppColors.primaryColor,
    hintStyle: TextStyle(color: AppColors.secondaryColor),
    border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryColor)),
    focusedBorder:
        UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryColor)),
    enabledBorder:
        UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryColor)),
    errorBorder:
        UnderlineInputBorder(borderSide: BorderSide(color: Colors.red)),
  ),

  //progress indicator
  progressIndicatorTheme: ProgressIndicatorThemeData(
    color: AppColors.primaryColor,
  ),

  //floating action button
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.primaryColor,
    foregroundColor: Colors.black,
  ),

  // icons
  iconTheme: const IconThemeData(
    color: AppColors.primaryColor,
  ),

  //text button
  textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
    textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    backgroundColor: AppColors.primaryColor,
    foregroundColor: Color(0xFF2E5077),
    padding: EdgeInsets.all(20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero), // No border
  )),
);
