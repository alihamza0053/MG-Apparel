import 'package:flutter/material.dart';

import '../credentials/login.dart';
import 'package:gms/screens/responsive_design/desktop/login.dart';


class ResponsiveLayout extends StatefulWidget {
  const ResponsiveLayout({super.key});

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint){
      if(constraint.maxWidth < 600){
        return Text("data");
      }else{
        return desktopLogin();
      }
    });
  }
}
