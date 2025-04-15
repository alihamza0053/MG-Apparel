import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/users/userDatabase.dart';
import 'package:toastification/toastification.dart';

import '../../../smtp/mailer.dart';
import '../../../theme/themeData.dart';

class mobileUserData extends StatefulWidget {
  const mobileUserData({super.key});

  @override
  State<mobileUserData> createState() => _mobileUserDataState();
}

class _mobileUserDataState extends State<mobileUserData> {
  final usersDB = UserDatabase();
  Map<int, String> selectedRoles = {};

  Color getRoleColor(String role) {
    switch (role) {
      case 'hr':
        return Colors.orange;
      case 'admin':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text("All Users", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Users With Role:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: StreamBuilder(
                stream: usersDB.stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final users = snapshot.data!;
                  return ScrollConfiguration(
                    behavior: ScrollBehavior().copyWith(overscroll: false),

                    child: ListView.builder(

                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final singleUser = users[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Email:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 4),
                                        Text(singleUser.email, style: TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: getRoleColor(singleUser.role),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        singleUser.role,
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    DropdownButton<String>(
                                      dropdownColor: Colors.white,
                                      value: selectedRoles[singleUser.id] ?? singleUser.role,
                                      hint: Text(singleUser.role, style: TextStyle(color: AppColors.primaryColor)),
                                      style: TextStyle(color: Colors.black),
                                      items: ['employee', 'hr', 'admin']
                                          .map((String status) => DropdownMenuItem<String>(
                                        value: status,
                                        child: Text(
                                          status,
                                          style: TextStyle(color: AppColors.primaryColor),
                                        ),
                                      ))
                                          .toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            selectedRoles[singleUser.id!] = newValue;
                                          });
                                        }
                                      },
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        String updatedRole = selectedRoles[singleUser.id] ?? singleUser.role;
                                        try {
                                          usersDB.update(singleUser, updatedRole);

                                          // email, subject, description
                                          sendEmail(singleUser.email, "Role Update", "Hello,\nWe wanted to inform you that your role in the Grievance System has been updated.\n\nUPDATED ROLE: ${singleUser.role}\n\nIf you believe this change was made in error, or if you have any questions, please contact the administrator.\n\nThank you,\nMG Apparel Grievance");

                                          Toastification().show(
                                            context: context,
                                            title: Text("User Role Updated."),
                                            type: ToastificationType.success,
                                            style: ToastificationStyle.flatColored,
                                            autoCloseDuration: const Duration(seconds: 5),
                                          );

                                          setState(() {
                                            selectedRoles.remove(singleUser.id);
                                          });
                                        } catch (e) {
                                          Toastification().show(
                                            context: context,
                                            title: Text("Error: $e"),
                                            type: ToastificationType.error,
                                            style: ToastificationStyle.flatColored,
                                            autoCloseDuration: const Duration(seconds: 5),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryColor,
                                        shape: RoundedRectangleBorder(),
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      child: Text("Update", style: TextStyle(fontSize: 16, color: Colors.white,fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
