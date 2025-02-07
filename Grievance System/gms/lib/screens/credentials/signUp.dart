import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/auth/authService.dart';
import 'package:gms/screens/credentials/login.dart';
import 'package:gms/screens/credentials/users/user.dart';
import 'package:gms/screens/credentials/users/userDatabase.dart';
import 'package:gms/screens/dashboard.dart';
import 'package:gms/screens/employee/employee.dart';
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
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back), color: Colors.white,),
        title: Text("Login"),
      ),
      body:
      Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                TextButton(onPressed: signUp, child: Text("SignUp")),
                GestureDetector(
                  onTap: (){
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Login()));
                  },
                  child: Container(
                    padding: EdgeInsets.fromLTRB(24, 10, 24, 10),
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Colors.white),),
                    child: Text("Login", style: TextStyle(fontSize: 16),),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
