import 'package:flutter/material.dart';

class EDashboard extends StatefulWidget {
  const EDashboard({super.key});

  @override
  State<EDashboard> createState() => _EDashboardState();
}

class _EDashboardState extends State<EDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: (){
        
      }),
      body: Column(
        children: [
          SizedBox(height: 100,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("Name"),
              Icon(Icons.notifications,)
            ],
          )
        ],
      ),
    );
  }
}
