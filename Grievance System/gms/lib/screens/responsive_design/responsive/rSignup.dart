import 'package:flutter/material.dart';

import 'package:gms/screens/responsive_design/desktop/login.dart';
import 'package:gms/screens/responsive_design/desktop/signup.dart';
import 'package:gms/screens/responsive_design/mobile/signup.dart';


class rSignup extends StatefulWidget {
  const rSignup({super.key});

  @override
  State<rSignup> createState() => _rSignupState();
}

class _rSignupState extends State<rSignup> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint){
      if(constraint.maxWidth < 600){
        return desktopSignup();
      }else{
        return desktopSignup();
      }
    });
  }
}
