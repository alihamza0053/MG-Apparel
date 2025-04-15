import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/users/userDatabase.dart';
import 'package:toastification/toastification.dart';

import '../../../smtp/mailer.dart';
import '../../../theme/themeData.dart';

class desktopUserData extends StatefulWidget {
  const desktopUserData({super.key});

  @override
  State<desktopUserData> createState() => _desktopUserDataState();
}

class _desktopUserDataState extends State<desktopUserData> {
  final usersDB = UserDatabase();
  Color roleColor = Colors.green;
  Map<int, String> selectedRoles = {};

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
        title: Text("All Users", style: TextStyle(fontSize: 25)),
      ),
      body: Center(
        child: Container(
          width: 800,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Users With Role:", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Expanded(
                child: StreamBuilder(
                  stream: usersDB.stream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final users = snapshot.data!;
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final singleUser = users[index];
                        if (singleUser.role == 'employee') {
                          roleColor = Colors.green;
                        } else if (singleUser.role == 'hr') {
                          roleColor = Colors.orange;
                        } else if (singleUser.role == 'admin') {
                          roleColor = Colors.red;
                        }
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 10),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Email: ${singleUser.email}", style: TextStyle(fontSize: 16)),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: roleColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(singleUser.role, style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    DropdownButton<String>(
                                      dropdownColor: Colors.white,
                                      value: selectedRoles[singleUser.id] ?? singleUser.role,
                                      hint: Text(
                                        singleUser.role,
                                        style: TextStyle(color: AppColors.primaryColor),
                                      ),
                                      style: TextStyle(color: AppColors.primaryColor),
                                      items: ['employee', 'hr', 'admin']
                                          .map((String status) => DropdownMenuItem<String>(
                                        value: status,
                                        child: Text(status, style: TextStyle(color: AppColors.primaryColor)),
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
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
