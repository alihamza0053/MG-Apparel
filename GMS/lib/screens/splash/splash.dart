import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gms/screens/employee/eDashboard.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {

  @override
  void initState() {
    // TODO: implement initState
    Timer(Duration(seconds: 1,), (){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>EDashboard()));
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Splash"),
      ),
    );
  }
}
