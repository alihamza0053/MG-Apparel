import 'package:flutter/material.dart';
import 'package:gms/screens/responsive_design/desktop/grievanceDetails.dart';

import 'package:gms/screens/responsive_design/desktop/login.dart';
import 'package:gms/screens/responsive_design/mobile/grievanceDetails.dart';


class rGrievanceDetails extends StatefulWidget {
  int? id;
  String? role;
  rGrievanceDetails({super.key, required this.id, required this.role});

  @override
  State<rGrievanceDetails> createState() => _rGrievanceDetailsState();
}

class _rGrievanceDetailsState extends State<rGrievanceDetails> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint){
      if(constraint.maxWidth < 600){
        return mobileGrievanceDetails(id: widget.id, role: widget.role);
      }else{
        return desktopGrievanceDetails(id: widget.id, role: widget.role);
      }
    });
  }
}
