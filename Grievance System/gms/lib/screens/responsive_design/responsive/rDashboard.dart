import 'package:flutter/material.dart';
import 'package:gms/screens/responsive_design/desktop/admin/adminDashboard.dart';
import 'package:gms/screens/responsive_design/desktop/ceo/ceoDashboard.dart';
import 'package:gms/screens/responsive_design/desktop/employee/employeeDashboard.dart';
import 'package:gms/screens/responsive_design/desktop/hr/hrDashboard.dart';

import 'package:gms/screens/responsive_design/desktop/login.dart';
import 'package:gms/screens/responsive_design/mobile/employee/employeeDashboard.dart';

import '../mobile/admin/adminDashboard.dart';
import '../mobile/ceo/ceoDashboard.dart';
import '../mobile/hr/hrDashboard.dart';


class rDashboard extends StatefulWidget {
  String role;
  String email;
  rDashboard({super.key, required this.role, required this.email});

  @override
  State<rDashboard> createState() => _rDashboardState();
}

class _rDashboardState extends State<rDashboard> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint){
      if(constraint.maxWidth < 600){
        Widget screen = mobileEmployeeDashboard();

        if(widget.role == 'employee'){
          screen =  mobileEmployeeDashboard();
        }
        if(widget.role == 'hr'){
          screen = mobileHrDashboard();
        }
        if(widget.role == 'admin'){
          screen = mobileAdminDashboard();
        }

        if(widget.email == "ceo@mgapparel.com"){
          screen = mobileCeoDashboard();
        }



        return screen;
      }else{

        Widget screen = desktopEmployeeDashboard();

        if(widget.role == 'employee'){
          screen =  desktopEmployeeDashboard();
        }
        if(widget.role == 'hr'){
          screen = desktopHrDashboard();
        }
        if(widget.role == 'admin'){
          screen = desktopAdminDashboard();
        }

        if(widget.email == "ceo@mgapparel.com"){
          screen = desktopCeoDashboard();
        }

        return screen;
      }
    });
  }
}
