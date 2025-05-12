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
  Map<int, String> selectedRoles = {};
  String? selectedFilterRole;

  Color getRoleColor(String role) {
    switch (role) {
      case 'hr':
        return Colors.blue;
      case 'admin':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1), // Light gray background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          "All Users",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          width: 800,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Users With Role",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedFilterRole,
                decoration: InputDecoration(
                  labelText: "Filter by Role",
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(
                    Icons.filter_list,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryColor),
                  ),
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text("All"),
                  ),
                  ...['employee', 'hr', 'admin'].map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    selectedFilterRole = newValue;
                  });
                },
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.grey.shade200, thickness: 1),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder(
                  stream: usersDB.stream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.hourglass_empty,
                              size: 80,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Loading Users...",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Please wait while we fetch the data.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    final users = snapshot.data!;
                    final filteredUsers = selectedFilterRole == null
                        ? users
                        : users.where((user) => user.role == selectedFilterRole).toList();
                    if (filteredUsers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 80,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              selectedFilterRole == null
                                  ? "No Users Found"
                                  : "No $selectedFilterRole Users Found",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              selectedFilterRole == null
                                  ? "There are no registered users yet."
                                  : "There are no users with the role '$selectedFilterRole' yet.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final singleUser = filteredUsers[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.grey.shade50],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Email",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          singleUser.email,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: getRoleColor(singleUser.role).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          singleUser.role == 'hr'
                                              ? Icons.support_agent
                                              : singleUser.role == 'admin'
                                              ? Icons.admin_panel_settings
                                              : Icons.person,
                                          size: 16,
                                          color: getRoleColor(singleUser.role),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          singleUser.role,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: getRoleColor(singleUser.role),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedRoles[singleUser.id] ?? singleUser.role,
                                      hint: Text(
                                        singleUser.role,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                      ),
                                      dropdownColor: Colors.white,
                                      items: ['employee', 'hr', 'admin'].map((String status) {
                                        return DropdownMenuItem<String>(
                                          value: status,
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            selectedRoles[singleUser.id!] = newValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      String updatedRole = selectedRoles[singleUser.id] ?? singleUser.role;
                                      try {
                                        usersDB.update(singleUser, updatedRole);
                                        // email, subject, description
                                        sendEmail(
                                            singleUser.email,
                                            "Role Update",
                                            "Hello,\nWe wanted to inform you that your role in the Grievance System has been updated.\n\nUPDATED ROLE: ${updatedRole}\n\nIf you believe this change was made in error, or if you have any questions, please contact the administrator.\n\nThank you,\nMG Apparel Grievance");
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
                                        Navigator.pop(context);
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
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.update,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 5),
                                        Text("Update"),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
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