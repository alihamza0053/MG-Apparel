import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/users/userDatabase.dart';
import 'package:gms/screens/database/grievanceDatabase.dart';
import 'package:gms/theme/themeData.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';

import '../../../smtp/mailer.dart';
import '../../database/grievance.dart';

class desktopGrievanceDetails extends StatefulWidget {
  int? id;
  String? role;

  desktopGrievanceDetails({super.key, required this.id, required this.role});

  @override
  State<desktopGrievanceDetails> createState() =>
      _desktopGrievanceDetailsState();
}

class _desktopGrievanceDetailsState extends State<desktopGrievanceDetails> {
  final grievanceDB = GrievanceDB();
  final usersDB = UserDatabase();
  Color statusColor = Colors.orange;
  Color priorityColor = Colors.orange;
  String? selectedStatus;
  String? selectedEmail;
  String? selectedPriority;
  List<String> emailList = [];
  String? selectedUserEmail;
  String defaultStatus = '';
  String defaultEmail = '';
  String defaultPriority = '';
  TextEditingController feedback = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECEFF1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: AppColors.primaryColor),
        ),
        title: Text(
          "Grievance Details",
          style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
// Implement logout
            },
            icon: Icon(Icons.logout, color: AppColors.secondaryColor),
            label: Text(
              "Logout",
              style: TextStyle(color: AppColors.secondaryColor),
            ),
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: 1200,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Column(
            children: [
              SizedBox(height: 20),
              Expanded(
                child: StreamBuilder(
                  stream: grievanceDB.detailStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final grievances = snapshot.data!;

// Find grievance by ID safely
                    final grievance = grievances.firstWhere(
                      (g) => g.id == widget.id,
                    );

                    if (grievance == null) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 80,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "No Grievance Found",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "The requested grievance ID does not exist",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      );
                    }

                    if (grievance.status == 'Pending') {
                      statusColor = Colors.orange;
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

                    return ListView.builder(
                      itemCount: 1,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.grey.shade50],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        grievance.title,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        _buildStatusChip(
                                            grievance.priority, priorityColor),
                                        SizedBox(width: 10),
                                        _buildStatusChip(
                                            grievance.status, statusColor),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Divider(color: Colors.grey.shade200),
                                SizedBox(height: 10),
                                _buildSectionTitle("Description:"),
                                _buildSectionContent(grievance.description),
                                SizedBox(height: 20),
                                _buildSectionTitle("Employee Details:"),
                                _buildEmployeeDetails(grievance),
                                SizedBox(height: 20),
                                _buildSectionTitle("Accused Details:"),
                                _buildAccusedDetails(grievance),
                                SizedBox(height: 20),
                                _buildSectionTitle("Assigned to:"),
                                _buildAssignedTo(grievance),
                                SizedBox(height: 20),
                                _buildSectionTitle("Feedback:"),
                                _buildFeedback(grievance),
                                SizedBox(height: 30),
                                if (widget.role == "admin" ||
                                    widget.role == "hr")
                                  _buildUpdateSection(grievance),
                                SizedBox(height: 20),
                                _buildTextField(
                                    feedback, "Feedback", Icons.feedback,
                                    maxLines: 5),
                                SizedBox(height: 20),
                                if (widget.role == "admin" ||
                                    widget.role == "hr")
                                  _buildUpdateButton(grievance),
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

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        : Icons.archive,
            color: color,
            size: 16,
          ),
          SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 0, 0),
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
      padding: const EdgeInsets.fromLTRB(10, 10, 0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
              SizedBox(width: 5),
              Text(
                "Name: ",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                grievance.my_name,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(width: 40),
          Row(
            children: [
              Icon(Icons.badge, size: 16, color: Colors.grey[600]),
              SizedBox(width: 5),
              Text(
                "Employee ID: ",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                grievance.my_employee_id,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccusedDetails(Grievance grievance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
              SizedBox(width: 5),
              Text(
                "Name: ",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                grievance.complain_against_name,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(width: 40),
          Row(
            children: [
              Icon(Icons.badge, size: 16, color: Colors.grey[600]),
              SizedBox(width: 5),
              Text(
                "Employee ID: ",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                grievance.complain_against_id,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedTo(Grievance grievance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 0, 0),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
          SizedBox(width: 5),
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
      padding: const EdgeInsets.fromLTRB(10, 10, 0, 0),
      child: Text(
        grievance.feedback.isEmpty
            ? "No feedback provided"
            : grievance.feedback,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildUpdateSection(Grievance grievance) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  return CircularProgressIndicator();
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
      ),
    );
  }

  Widget _buildDropdownSection(String title, String? value, List<String> items,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                "Select $title",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              style: TextStyle(color: Colors.grey[800], fontSize: 14),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
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
                selectedUserEmail!.trim(),
                selectedStatus!.trim(),
                selectedPriority!.trim(),
                feedback.text.trim(),
              );

              print(
                  "check error: ${selectedPriority} ${selectedStatus} ${selectedUserEmail}");

//send email to employee
              sendEmail(grievance.submittedBy!, "Grievance Update",
                  "Hello,\nYour grievance titled '${grievance.title}' has been updated with following details.\n\nAssigned to: ${grievance.assignTo!}\nStatus: ${selectedStatus!}\nPriority: ${selectedPriority!}\nFeedback: ${feedback.text}\n\nIf you believe this change was made in error, or if you have any questions, please contact the administrator.\n\nThank you,\nMG Apparel Grievance");

//send email to assign person
              sendEmail(grievance.assignTo, "Grievance Assigned",
                  "Hello,\nA new grievance titled '${grievance.title}' has been assigned to you with following details.\n\nSubmitted by: ${selectedUserEmail}\nStatus: ${selectedStatus!}\nPriority: ${selectedPriority!}\nFeedback: ${feedback.text}\n\nIf you believe this assign was made in error, or if you have any questions, please contact the administrator.\n\nThank you,\nMG Apparel Grievance");

              Toastification().show(
                context: context,
                title: Text("Grievance Updated."),
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
              title: Text("Add Feedback!"),
              type: ToastificationType.warning,
              style: ToastificationStyle.flatColored,
              autoCloseDuration: const Duration(seconds: 5),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.update, color: Colors.white, size: 16),
            SizedBox(width: 5),
            Text(
              "Update",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
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
      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
      ),
    );
  }
}
