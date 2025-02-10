import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/auth/authService.dart';
import 'package:gms/screens/credentials/login.dart';
import 'package:gms/screens/credentials/users/user.dart';
import 'package:gms/screens/credentials/users/userDatabase.dart';
import 'package:gms/screens/dashboard.dart';
import 'package:gms/screens/employee/employee.dart';
import 'package:gms/theme/themeData.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final users = UserDatabase();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  AuthService authService = AuthService();

  void signUp() async{
    try{
      await authService.signUp(email.text, password.text);
      createUser();
  }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error $e")));
    }
}

void createUser() async{
    final newUser = Users(email: email.text, role: "hr");
    try{
      users.createUser(newUser);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Account Created")));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Employee()));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error $e")));
    }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      Center(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Container(
            width:400,
            height: 350,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
                border:Border.all(width: 2, color: AppColors.primaryColor),
                borderRadius: BorderRadius.circular(10)
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Image(image: AssetImage("assets/images/logo.png"),width: 100,),

                Text("Create New Account", style: TextStyle(fontSize: 30),),
                SizedBox(
                  height: 20,
                ),
                //Text("Create New Account", style: TextStyle(fontSize: 20),),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(hintText: "Email"),

                ),
                TextField(

                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Password",
                    counterText: "", // ✅ Hides the default character counter
                  ),
                ),
                SizedBox(height: 20,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(onPressed: signUp, child: Text("SignUp",style: TextStyle(color: Colors.white),)),
                    GestureDetector(
                      onTap: (){
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Login()));
                      },
                      child: Container(
                        padding: EdgeInsets.fromLTRB(24, 10, 24, 10),
                        decoration: BoxDecoration(
                          border: Border.all(width: 1, color: AppColors.primaryColor),),
                        child: Text("Login", style: TextStyle(fontSize: 16),),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
