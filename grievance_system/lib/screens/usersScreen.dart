import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late Stream<List<Map<String, dynamic>>> userData;
  List<String> usersList = ["Admin", "HR", "Employee"];
  bool isLoading = false;

  @override
  void initState() {
    userData = fetchUsersData();
    super.initState();
  }

  // Fetch all users with their roles
  Stream<List<Map<String, dynamic>>> fetchUsersData() async* {
    while (true) {
      final response = await http.get(
        Uri.parse('https://gms.alihamza.me/gms/get_users.php'),
      );

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> users =
        List<Map<String, dynamic>>.from(json.decode(response.body)['data']);
        yield users; // Yield data whenever there's a new user
      } else {
        throw Exception('Failed to load users');
      }

      await Future.delayed(
        Duration(seconds: 5),
      ); // Re-fetch every 5 seconds to check for new data
    }
  }

  // Update role in the database
  Future<void> updateUserRole(String email, String newRole) async {
    try {
      final response = await http.post(
        Uri.parse('https://gms.alihamza.me/gms/update_user_role.php'),
        body: {
          'email': email,
          'role': newRole,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            isLoading = false;
          });
          print("Role updated successfully for $email");
        } else {
          print("Failed to update role: ${data['error']}");
        }
      } else {
        print("Failed to update role. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error updating role: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  StreamBuilder<List<Map<String, dynamic>>>(
        stream: userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];
          var selectedRole;

          return isLoading ? Center(child: CircularProgressIndicator(),) : ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              selectedRole = user['role'];

              return Card(
                child: ListTile(
                  title: Text(
                    'Email: ${user['email'] ?? 'No Email'}',
                  ),
                  subtitle: Text(
                    'Role: ${user['role'] ?? 'No Role'}',
                  ),
                  trailing: DropdownButton<String>(
                    value: usersList.contains(selectedRole) ? selectedRole : null,
                    hint: Text('Select Role'),
                    items: usersList
                        .map((role) => DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    ))
                        .toList(),
                    onChanged: (newRole) async {
                      if (newRole != null) {
                        setState(() {
                          isLoading = true;
                          selectedRole = newRole;
                        });
                        await updateUserRole(user['email'], newRole);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
