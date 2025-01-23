import 'package:flutter/material.dart';

class DisplayLogin extends StatefulWidget {
  const DisplayLogin({super.key});

  @override
  State<DisplayLogin> createState() => _DisplayLoginState();
}

class _DisplayLoginState extends State<DisplayLogin> {
  TextEditingController _loginController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("Display"),
              Icon(Icons.verified_user)
            ],
          ),

          Text("Welcome Back", style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
          SizedBox(height: 10,),
          Container(
            width: 350,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Login"),
                TextField(
                  controller: _loginController,
                  decoration: InputDecoration(
                    hintText: "Email"
                  ),
                )
              ],
            ),
          )

        ],
      )),
    );
  }
}
