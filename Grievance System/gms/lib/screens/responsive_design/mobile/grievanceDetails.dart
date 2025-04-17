import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/users/userDatabase.dart';
import 'package:gms/screens/database/grievanceDatabase.dart';
import 'package:gms/theme/themeData.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';

import '../../../smtp/mailer.dart';
import '../../database/grievance.dart';

class mobileGrievanceDetails extends StatefulWidget {
  int? id;
  String? role;

  mobileGrievanceDetails({super.key, required this.id, required this.role});

  @override
  State<mobileGrievanceDetails> createState() => _mobileGrievanceDetailsState();
}

class _mobileGrievanceDetailsState extends State<mobileGrievanceDetails> {
  final grievanceDB = GrievanceDB();
  final usersDB = UserDatabase();
  Color statusColor = Colors.orangeAccent;
  Color priorityColor = Colors.orange;
  String? selectedStatus;
  String? selectedEmail;
  String? selectedPriority;
  List<String> emailList = [];
  String? selectedUserEmail; // Selected email
  String defaultStatus = '';
  String defaultEmail = '';
  String defaultPriority = '';
  TextEditingController feedback = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            )),
        title: Text("Grievance Details", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: StreamBuilder(
          stream: grievanceDB.detailStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            final grievances = snapshot.data!;

            // Find grievance by ID safely
            final grievance = grievances.firstWhere(
              (g) => g.id == widget.id,
            );

            if (grievance == null) {
              return Center(
                child: Text("No record found for ID ${widget.id}"),
              );
            }

            if (grievance.status == 'Pending') {
              statusColor = Colors.red;
            } else if (grievance.status == 'In Progress') {
              statusColor = Colors.blue;
            } else if (grievance.status == 'Resolved' ||
                grievance.status == 'Closed') {
              statusColor = Colors.green;
            }
            if (grievance.priority == 'Low') {
              priorityColor = Colors.orange;
            }
            if (grievance.priority == 'High') {
              priorityColor = Colors.red;
            }
            defaultStatus = grievance.status;
            defaultEmail = grievance.assignTo;
            defaultPriority = grievance.priority;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Status Chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        grievance.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _buildStatusChip(grievance.priority, priorityColor),
                        SizedBox(width: 8),
                        _buildStatusChip(grievance.status, statusColor),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Description Section
                _buildSectionTitle("Description:"),
                _buildSectionContent(grievance.description),
                SizedBox(height: 20),

                // Employee Details Section
                _buildSectionTitle("Employee Details:"),
                _buildEmployeeDetails(grievance),
                SizedBox(height: 20),

                // Accused Details Section
                _buildSectionTitle("Accused Details:"),
                _buildAccusedDetails(grievance),
                SizedBox(height: 20),

                // Assigned To Section
                _buildSectionTitle("Assigned to:"),
                _buildAssignedTo(grievance),
                SizedBox(height: 20),

                // Feedback Section
                _buildSectionTitle("Feedback:"),
                _buildFeedback(grievance),
                SizedBox(height: 20),

                // Update Section (for admin/hr)
                if (widget.role == "admin" || widget.role == "hr")
                  _buildUpdateSection(grievance),
                SizedBox(height: 20),

                _buildTextField(feedback, "Feedback", Icons.feedback,
                    maxLines: 5),

                SizedBox(height: 20),
                // Update Button (for admin/hr)
                if (widget.role == "admin" || widget.role == "hr")
                  _buildUpdateButton(grievance),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.secondaryColor,
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 0, 0),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEmployeeDetails(Grievance grievance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow("Name", grievance.my_name),
          SizedBox(height: 8),
          _buildDetailRow("Employee ID", grievance.my_employee_id),
        ],
      ),
    );
  }

  Widget _buildAccusedDetails(Grievance grievance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow("Name", grievance.complain_against_name),
          SizedBox(height: 8),
          _buildDetailRow("Employee ID", grievance.complain_against_id),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedTo(Grievance grievance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 0, 0),
      child: Text(
        grievance.assignTo,
        style: TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFeedback(Grievance grievance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 0, 0),
      child: Text(
        grievance.feedback,
        style: TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildUpdateSection(Grievance grievance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.role == "admin" || widget.role == "hr")
          _buildDropdownSection(
            "Update Status:",
            selectedStatus,
            ['Pending', 'In Progress', 'Resolved', 'Closed'],
            (newValue) {
              setState(() {
                selectedStatus = newValue;
              });
            },
          ),
        if (widget.role == "admin")
          _buildDropdownSection(
            "Update Priority:",
            selectedPriority,
            ['Low', 'High'],
            (newValue) {
              setState(() {
                selectedPriority = newValue;
              });
            },
          ),
        if (widget.role == "admin")
          FutureBuilder<List<String>>(
            future: fetchUsersEmails(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return CircularProgressIndicator();
              }
              final userEmails = snapshot.data!;
              return _buildDropdownSection(
                "Update Assign Person:",
                selectedUserEmail,
                userEmails,
                (newValue) {
                  setState(() {
                    selectedUserEmail = newValue;
                  });
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildDropdownSection(String title, String? value, List<String> items,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          DropdownButton<String>(
            value: value,
            hint: Text(
              "Select $title",
              style: TextStyle(color: AppColors.primaryColor),
            ),
            style: TextStyle(color: Colors.black),
            dropdownColor: AppColors.primaryColor,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(color: Colors.black),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }


  Widget _buildUpdateButton(Grievance grievance) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          selectedStatus ??= defaultStatus;
          selectedUserEmail ??= defaultEmail;
          selectedPriority ??= defaultPriority;
          if (feedback.text.isNotEmpty) {
            try {
              grievanceDB.updateStatus(
                widget.id!,
                selectedUserEmail!,
                selectedStatus!,
                selectedPriority!,
                feedback.text,
              );

              //send email to employee
              sendEmail(grievance.submittedBy!,"Grievance Update","Hello,\nYour grievance titled '${grievance.title}' has been updated with following details.\n\nAssigned to: ${grievance.assignTo!}\nStatus: ${selectedStatus!}\nPriority: ${selectedPriority!}\nFeedback: ${feedback.text}\n\nIf you believe this change was made in error, or if you have any questions, please contact the administrator.\n\nThank you,\nMG Apparel Grievance");


              //send email to assign person
              sendEmail(grievance.assignTo,"Grievance Assigned","Hello,\nA new grievance titled '${grievance.title}' has been assigned to you with following details.\n\nSubmitted by: ${selectedUserEmail}\nStatus: ${selectedStatus!}\nPriority: ${selectedPriority!}\nFeedback: ${feedback.text}\n\nIf you believe this assign was made in error, or if you have any questions, please contact the administrator.\n\nThank you,\nMG Apparel Grievance");


              Toastification().show(
                context: context,
                title: Text("Grievance Updated"),
                type: ToastificationType.success,
                style: ToastificationStyle.flatColored,
                autoCloseDuration: const Duration(seconds: 5),
              );

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
          } else {
            Toastification().show(
              context: context,
              title: Text("Add Feedback!!"),
              type: ToastificationType.warning,
              style: ToastificationStyle.flatColored,
              autoCloseDuration: const Duration(seconds: 5),
            );

          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          "Update",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<List<String>> fetchUsersEmails() async {
    final response =
        await Supabase.instance.client.from('users').select('email');
    if (response.isEmpty) return [];
    return response.map<String>((row) => row['email'] as String).toList();
  }

  Widget _buildTextField(
      TextEditingController controller, String hintText, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
