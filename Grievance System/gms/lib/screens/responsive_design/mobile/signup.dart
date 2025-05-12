import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/auth/authService.dart';
import 'package:gms/screens/credentials/login.dart';
import 'package:gms/screens/credentials/users/user.dart';
import 'package:gms/screens/credentials/users/userDatabase.dart';
import 'package:gms/screens/dashboard.dart';
import 'package:gms/screens/employee/employee.dart';
import 'package:gms/screens/responsive_design/mobile/login.dart';
import 'package:gms/screens/responsive_design/responsive/rLogin.dart';
import 'package:gms/smtp/mailer.dart';
import 'package:gms/theme/themeData.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';


class mobileSignup extends StatefulWidget {
  const mobileSignup({super.key});

  @override
  State<mobileSignup> createState() => _mobileSignupState();
}

class _mobileSignupState extends State<mobileSignup> {
  final users = UserDatabase();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  AuthService authService = AuthService();
  bool progressBar = false;

  void signUp() async{

    if(email.text.isEmpty || password.text.isEmpty){
      Toastification().show(
        context: context,
        title: Text("Fill all the fields."),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: const Duration(seconds: 5),
      );
    }else{
      setState(() {
        progressBar= true;
      });
      try{
        await authService.signUp(email.text.toLowerCase().trim(), password.text.toLowerCase().trim());
        createUser();
      }on AuthException catch(e){
        setState(() {
          progressBar = false;
        });
        Toastification().show(
          context: context,
          title: Text("Error ${e.message}"),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 5),
        );
      }
    }

  }

  void createUser() async{

    final newUser;

    if(email.text == "ceo@mgapparel.com"){
      newUser = Users(email: email.text.toLowerCase().trim(), role: "admin");
    }else{
      newUser = Users(email: email.text.toLowerCase().trim(), role: "employee");
    }

    try{
      users.createUser(newUser);
      Toastification().show(
        context: context,
        title: Text("Account Created."),
        type: ToastificationType.success,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: const Duration(seconds: 5),
      );
      sendEmail("${email.text}", "Account Created for GMS", "Hello,\nYour account has been created. \n\nYour login credentials are as following:\nEmail: ${email.text}\nPassword: ${password.text} \nPlease remember your password.\n\nThank you,\nMG Apparel Grievance");
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>rLogin()));
    }catch(e){
      Toastification().show(
        context: context,
        title: Text("Error $e"),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: const Duration(seconds: 5),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      Center(
        child: progressBar ?
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            Text("Creating New Account....", style: TextStyle(fontSize: 18),)
          ],
        )
            : Padding(
          padding: const EdgeInsets.all(18.0),
          child: Container(
            width:400,
            height: 400,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
                border:Border.all(width: 2, color: AppColors.primaryColor),
                borderRadius: BorderRadius.circular(10)
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image(image: AssetImage("assets/images/logo.png"),width: 100,),
                SizedBox(
                  height: 10,
                ),

                Text("Create New Account", style: TextStyle(fontSize: 30,fontWeight: FontWeight.w800),),
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
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>rLogin()));
                      },
                      child: Container(
                        padding: EdgeInsets.fromLTRB(24, 10, 24, 10),
                        decoration: BoxDecoration(
                          border: Border.all(width: 1, color: AppColors.primaryColor),),
                        child: Text("Login", style: TextStyle(fontSize: 18),),
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
