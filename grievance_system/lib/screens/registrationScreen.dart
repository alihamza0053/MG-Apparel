import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _departmentController = TextEditingController();
  String? _selectedRole;
  List<String> roles = ['Admin', 'HR', 'Employee'];

  // This function is for registration
  Future<void> _register() async {
    try {
      final response = await http.post(
        Uri.parse('https://gms.alihamza.me/gms/register.php'),
        headers: {
          'Content-Type': 'application/json', // Make sure content type is JSON
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'department': _departmentController.text.trim(),
          'role': _selectedRole, // Save selected role
        }),
      );
      print('Selected Role: $_selectedRole');
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == "true") {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Registration successful.")),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                Text("Registration failed: ${responseData['message']}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Error: $e"); // Log the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _departmentController,
              decoration: InputDecoration(labelText: 'Department'),
            ),
            // Role Radio Buttons
            Column(
              children: [
                Row(
                  children: roles.map((role) {
                    return Row(
                      children: [
                        Radio<String>(
                          value: role,
                          groupValue: _selectedRole,
                          onChanged: (String? value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                        ),
                        Text(role),
                      ],
                    );
                  }).toList(),
                )
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _register, child: Text('Register')),
          ],
        ),
      ),
    );
  }
}