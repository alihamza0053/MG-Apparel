import 'package:flutter/material.dart';

import 'package:gms/screens/responsive_design/desktop/login.dart';
import 'package:gms/screens/responsive_design/mobile/login.dart';


class rLogin extends StatefulWidget {
  const rLogin({super.key});

  @override
  State<rLogin> createState() => _rLoginState();
}

class _rLoginState extends State<rLogin> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint){
      if(constraint.maxWidth < 600){
        return mobileLogin();
      }else{
        return desktopLogin();
      }
    });
  }
}
