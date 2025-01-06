import 'package:flutter/material.dart';
import 'package:gms/screens/splash/splash.dart';
import 'package:gms/theme/themeData.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: primaryTheme,
      home: Scaffold(
        body: Splash(),
      ),
    );
  }
}
