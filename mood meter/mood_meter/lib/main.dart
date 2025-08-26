import 'package:flutter/material.dart';
import 'package:mood_meter/screens/AdminLogin.dart';
import 'package:mood_meter/screens/userLogin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://tylrzxvbiklnnrqwixnv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5bHJ6eHZiaWtsbm5ycXdpeG52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ3MDA5NzYsImV4cCI6MjA2MDI3Njk3Nn0.OYo0M8NGTrXxMdnEeTm7U3DWnOXXcAYR3DFQnzbTudI',
  );
  runApp(App());
}


class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mood Meter',
      theme: ThemeData(fontFamily: "aptos",primaryColor: Color(0xFF2AABE2)),
      home: LoginScreen(),

    );
  }
}








