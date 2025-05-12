import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/auth/authService.dart';
import 'package:gms/screens/credentials/login.dart';
import 'package:gms/screens/credentials/users/user.dart';
import 'package:gms/screens/credentials/users/userDatabase.dart';
import 'package:gms/screens/dashboard.dart';
import 'package:gms/screens/employee/employee.dart';
import 'package:gms/screens/responsive_design/desktop/login.dart';
import 'package:gms/screens/responsive_design/responsive/rLogin.dart';
import 'package:gms/theme/themeData.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';

import '../../../smtp/mailer.dart';

class desktopSignup extends StatefulWidget {
  const desktopSignup({super.key});

  @override
  State<desktopSignup> createState() => _desktopSignupState();
}

class _desktopSignupState extends State<desktopSignup> {
  final users = UserDatabase();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  AuthService authService = AuthService();
  bool progressBar = false;

  void signUp() async {
    if (email.text.isEmpty || password.text.isEmpty) {
      Toastification().show(
        context: context,
        title: Text("Fill all the fields."),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: const Duration(seconds: 5),
      );
    } else {
      setState(() {
        progressBar = true;
      });
      try {
        await authService.signUp(email.text.toLowerCase().trim(),
            password.text.toLowerCase().trim());
        createUser();
      } on AuthException catch (e) {
        setState(() {
          progressBar = false;
        });
        Toastification().show(
          context: context,
          title: Text("Error: ${e.message}"),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 5),
        );
      }
    }
  }

  void createUser() async {
    final newUser;

    if (email.text == "ceo@mgapparel.com") {
      newUser = Users(email: email.text.toLowerCase().trim(), role: "admin");
    } else {
      newUser = Users(email: email.text.toLowerCase().trim(), role: "employee");
    }
    try {
      users.createUser(newUser);
      Toastification().show(
        context: context,
        title: Text("Account Created."),
        type: ToastificationType.success,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: const Duration(seconds: 5),
      );
      sendEmail("${email.text}", "Account Created for GMS", "Hello,\nYour account has been created. \n\nYour login credentials are as following:\nEmail: ${email.text}\nPassword: ${password.text} \nPlease remember your password.\n\nThank you,\nMG Apparel Grievance");

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => rLogin()));
    } catch (e) {
      Toastification().show(
        context: context,
        title: Text("Error: $e"),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: const Duration(seconds: 5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECEFF1),
      body: Center(
        child: progressBar
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 80,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Creating New Account",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Please wait...",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              )
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: 400,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.grey.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image(
                          image: AssetImage("assets/images/logo.png"),
                          width: 100,
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Create New Account",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                          decoration: InputDecoration(
                            hintText: "Email",
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            prefixIcon: Icon(
                              Icons.email,
                              color: Colors.grey[600],
                              size: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: AppColors.primaryColor),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: password,
                          obscureText: true,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                          decoration: InputDecoration(
                            hintText: "Password",
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            prefixIcon: Icon(
                              Icons.lock,
                              color: Colors.grey[600],
                              size: 16,
                            ),
                            counterText: "",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: AppColors.primaryColor),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              onPressed: signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_add,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    "Sign Up",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => rLogin(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.secondaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.secondaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
