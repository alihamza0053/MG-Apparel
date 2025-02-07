import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/auth/authGate.dart';
import 'package:gms/screens/credentials/login.dart';
import 'package:gms/screens/dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {


  @override
  void initState() {
    Timer timer = Timer(Duration(milliseconds: 100),(){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Login()));
    } );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("GMS"),
      ),
    );
  }
}
