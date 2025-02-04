import 'package:flutter/material.dart';
import 'package:gms/screens/loginScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  List<String> roles = ['HR', 'Employee'];

  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> _register() async {
    try {
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {

        await supabase.from('users').insert({
          'email': _emailController.text.trim(),
          'department': _departmentController.text.trim(),
          'role': _selectedRole,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration successful. Please check your email to verify your account.")),
        );
        Navigator.pop(context);
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
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(),
          Container(
            width: 500,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10)
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text("GMS Registration",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
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
                  SizedBox(height: 20,),
                  TextField(
                    controller: _departmentController,
                    decoration: InputDecoration(labelText: 'Department'),
                  ),
                  SizedBox(height: 20,),
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
                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                        ),
                        child: Text('    Login    ', style: TextStyle(color: Colors.black),),
                      ),
                      ElevatedButton(onPressed: _register, child: Text('Register',)),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
