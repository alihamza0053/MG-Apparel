import 'package:flutter/material.dart';

import 'package:gms/screens/responsive_design/desktop/login.dart';
import 'package:gms/screens/responsive_design/desktop/users.dart';
import 'package:gms/screens/responsive_design/mobile/users.dart';


class rUsers extends StatefulWidget {
  const rUsers({super.key});

  @override
  State<rUsers> createState() => _rUsersState();
}

class _rUsersState extends State<rUsers> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint){
      if(constraint.maxWidth < 600){
        return mobileUserData();
      }else{
        return desktopUserData();
      }
    });
  }
}
