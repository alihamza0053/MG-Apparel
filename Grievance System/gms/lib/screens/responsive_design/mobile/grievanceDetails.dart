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
          "Grievance Details",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.close, color: AppColors.secondaryColor, size: 16),
            label: Text(
              "Close",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: StreamBuilder(
          stream: grievanceDB.detailStream,
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
                      "Loading Grievance...",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Please wait while we fetch the details.",
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

            final grievances = snapshot.data!;

            // Find grievance by ID safely
            final grievance = grievances.firstWhere(
                  (g) => g.id == widget.id,
            );

            if (grievance == null) {
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
                      "No Grievance Found",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "No record found for ID ${widget.id}.",
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

            if (grievance.status == 'Pending') {
              statusColor = Colors.orange;
            } else if (grievance.status == 'In Progress') {
              statusColor = Colors.blue;
            } else if (grievance.status == 'Resolved') {
              statusColor = Colors.green;
            } else if (grievance.status == 'Closed') {
              statusColor = Colors.grey;
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

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
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
                  // Title and Status Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          grievance.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(
                        children: [
                          _buildStatusChip(grievance.priority, priorityColor),
                          const SizedBox(width: 8),
                          _buildStatusChip(grievance.status, statusColor),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade200, thickness: 1),

                  // Description Section
                  _buildSectionTitle("Description"),
                  _buildSectionContent(grievance.description),
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade200, thickness: 1),

                  // Employee Details Section
                  _buildSectionTitle("Employee Details"),
                  _buildEmployeeDetails(grievance),
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade200, thickness: 1),

                  // Accused Details Section
                  _buildSectionTitle("Accused Details"),
                  _buildAccusedDetails(grievance),
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade200, thickness: 1),

                  // Assigned To Section
                  _buildSectionTitle("Assigned to"),
                  _buildAssignedTo(grievance),
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade200, thickness: 1),

                  // Feedback Section
                  _buildSectionTitle("Feedback"),
                  _buildFeedback(grievance),
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade200, thickness: 1),

                  // Update Section (for admin/hr)
                  if (widget.role == "admin" || widget.role == "hr")
                    _buildUpdateSection(grievance),
                  if (widget.role == "admin" || widget.role == "hr")
                    const SizedBox(height: 20),
                  if (widget.role == "admin" || widget.role == "hr")
                    Divider(color: Colors.grey.shade200, thickness: 1),

                  _buildTextField(feedback, "Feedback", Icons.feedback, maxLines: 5),

                  const SizedBox(height: 20),
                  // Update Button (for admin/hr)
                  if (widget.role == "admin" || widget.role == "hr")
                    _buildUpdateButton(grievance),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == 'Pending'
                ? Icons.hourglass_empty
                : label == 'In Progress'
                ? Icons.autorenew
                : label == 'Resolved'
                ? Icons.check_circle
                : label == 'Closed'
                ? Icons.archive
                : Icons.priority_high,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      "$title:",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildEmployeeDetails(Grievance grievance) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow("Name", grievance.my_name, Icons.person_outline),
          const SizedBox(height: 12),
          _buildDetailRow("Employee ID", grievance.my_employee_id, Icons.badge),
        ],
      ),
    );
  }

  Widget _buildAccusedDetails(Grievance grievance) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow("Name", grievance.complain_against_name, Icons.person_outline),
          const SizedBox(height: 12),
          _buildDetailRow("Employee ID", grievance.complain_against_id, Icons.badge),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$label:",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedTo(Grievance grievance) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 5),
          Text(
            grievance.assignTo,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback(Grievance grievance) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        grievance.feedback,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[800],
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
            "Update Status",
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
            "Update Priority",
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
                return CircularProgressIndicator(color: AppColors.primaryColor);
              }
              final userEmails = snapshot.data!;
              return _buildDropdownSection(
                "Update Assign Person",
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title:",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                "Select $title",
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
              isExpanded: true,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              borderRadius: BorderRadius.circular(8),
            ),
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
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        child: const Text("Update"),
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
        hintStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
        prefixIcon: Icon(icon, size: 16, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      ),
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[800],
      ),
    );
  }
}