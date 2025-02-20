import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/auth/authGate.dart';
import 'package:gms/screens/credentials/login.dart';
import 'package:gms/screens/dashboard.dart';
import 'package:gms/screens/responsive_design/responsive/rLogin.dart';
import 'package:gms/screens/responsive_design/responsiveLayout.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {


  @override
  void initState() {
    Timer timer = Timer(Duration(milliseconds: 3000),(){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>rLogin()));
    } );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("GMS",style: TextStyle(fontSize: 50,fontWeight: FontWeight.w800),),
            Text("Grievance Management System",style: TextStyle(fontSize: 25,fontWeight: FontWeight.normal),),
          ],
        ),
      ),
    );
  }
}
