import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/auth/authService.dart';
import 'package:gms/screens/credentials/signUp.dart';
import 'package:gms/screens/employee/employee.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dashboard.dart';
import '../hr/hr.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  AuthService authService = AuthService();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  String role = "";
  Widget screen = Employee();



  @override
  void initState() {
    super.initState();
    fetchUserRole(); // Fetch user role when dashboard loads
  }

  // Function to fetch user role from Supabase
  Future<void> fetchUserRole() async {
    try {
      SupabaseClient supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser; // Get logged-in user
      if (user == null) return;

      final response = await supabase
          .from('users') // Your users table
          .select('role') // Fetch only the role column
          .eq('email', user.email as Object) // Filter by user's email
          .maybeSingle(); // Get single result

      if (response != null && response['role'] != null) {
        setState(() {
          role = response['role']; // Set user role
        });
      }

      if(role == 'employee'){
        screen =  Employee();
      }
      if(role == 'hr'){
        screen = hr();
      }
      if(role == 'admin'){
        screen = DashboardScreen();
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>screen));



      print("🔹 User Role: $role"); // Debug log
    } catch (e) {
      print("❌ Error fetching user role: $e");
    }
  }

void login() async{

  try{
    await authService.login(email.text, password.text);
    fetchUserRole(); // Fetch user role when dashboard loads
  }on AuthException catch(e){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error ${e.message}")));
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
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
        ),
        title: Text("Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //Text("Welcome Back", style: TextStyle(fontSize: 25),),
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
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(onPressed: login, child: Text("Login")),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => SignUp()));
                  },
                  child: Container(
                    padding: EdgeInsets.fromLTRB(18, 10, 18, 10),
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Colors.white),
                    ),
                    child: Text(
                      "SignUp",
                      style: TextStyle(fontSize: 16),
                    ),
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
