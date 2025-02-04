import 'package:flutter/material.dart';
import 'package:gms/screens/loginScreen.dart';
import 'package:gms/screens/splashScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://hwjpzigmxxytlftypzgu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh3anB6aWdteHh5dGxmdHlwemd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzUwMzQzNjYsImV4cCI6MjA1MDYxMDM2Nn0.t8JtJiBlNQEnbPz4L5PpgnOTChN3-VXfYcDIBZsq5y8',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grievance Management System',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: LoginScreen(),
    );
  }
}
