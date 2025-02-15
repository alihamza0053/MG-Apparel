import 'package:flutter/material.dart';

import 'package:gms/screens/responsive_design/desktop/login.dart';
import 'package:gms/screens/responsive_design/mobile/newGrievance.dart';

import '../desktop/newGrievance.dart';


class rNewGrievance extends StatefulWidget {
  const rNewGrievance({super.key});

  @override
  State<rNewGrievance> createState() => _rNewGrievanceState();
}

class _rNewGrievanceState extends State<rNewGrievance> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint){
      if(constraint.maxWidth < 600){
        return mobileNewGrievance();
      }else{
        return desktopNewGrievance();
      }
    });
  }
}
