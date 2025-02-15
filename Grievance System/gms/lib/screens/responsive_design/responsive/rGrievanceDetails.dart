import 'package:flutter/material.dart';

import 'package:gms/screens/responsive_design/desktop/login.dart';


class rGrievanceDetails extends StatefulWidget {
  const rGrievanceDetails({super.key});

  @override
  State<rGrievanceDetails> createState() => _rGrievanceDetailsState();
}

class _rGrievanceDetailsState extends State<rGrievanceDetails> {
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
