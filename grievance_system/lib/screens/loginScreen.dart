import 'package:flutter/material.dart';
import 'package:grievance_system/components/neo_box.dart';
import 'package:grievance_system/screens/dashboard/dashboard.dart';
import 'package:grievance_system/screens/registrationScreen.dart';
import 'package:grievance_system/theme/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'dashboardScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  List<dynamic>? usersList;
  String? role;

  // Fetch users for the 'Assigned To' dropdown
  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('https://groundup.pk/gms/get_users.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          usersList = data['data'];

        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading users list.')),
          );

        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users list.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _login() async {
    await _fetchUsers();

    try {
      final response = await http.post(
        Uri.parse("https://groundup.pk/gms/login.php"),
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success']) {
          // Correct loop condition to iterate through usersList
          for (var i = 0; i < usersList!.length; i++) {

            // Check if the email matches the user's email
            if (usersList?[i]['email'] == _emailController.text) {
              role = usersList?[i]['role'];
              print("Role: ${usersList?[i]['role']}");
              // You can handle the user-specific logic here
            }
          }
          print(response.body);


          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Login successful $role")),
          );

          // Save the login status
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setBool('isLoggedIn', true);
          prefs.setString('userEmail', _emailController.text);
          prefs.setString('role', role!);



          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Dashboard()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Login failed: ${responseData['message']}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.accentColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10)
            ),
            width: 350,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text("GMS Login",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                  SizedBox(height: 20,),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                  SizedBox(height: 20,),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(onPressed: _login, child: Text('Login',)),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RegistrationScreen()),
                        ),
                        child: Text('Register', style: TextStyle(color: Colors.black),),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ),
        ],
      )
    );
  }
}
