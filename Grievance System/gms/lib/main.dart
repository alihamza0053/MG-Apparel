import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/auth/authGate.dart';
import 'package:gms/screens/credentials/login.dart';
import 'package:gms/screens/dashboard.dart';
import 'package:gms/screens/grievanceDetails.dart';
import 'package:gms/screens/newGrievance.dart';
import 'package:gms/screens/splash.dart';
import 'package:gms/smtp/mailer.dart';
import 'package:gms/theme/themeData.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async{
  await Supabase.initialize(
    url: 'https://gcjamumurtogzabawryn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdjamFtdW11cnRvZ3phYmF3cnluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg4Mzc4NDIsImV4cCI6MjA1NDQxMzg0Mn0.X0hN-3_JIJoIXgC0mcX3eHq8JuM5GYNbOPtQHEyBMdQ',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeData,
      home: Scaffold(
        body: SplashScreen(),
      ),
    );
  }
}

