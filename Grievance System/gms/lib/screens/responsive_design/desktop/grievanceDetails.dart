import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/users/userDatabase.dart';
import 'package:gms/screens/database/grievanceDatabase.dart';
import 'package:gms/theme/themeData.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../database/grievance.dart';


class desktopGrievanceDetails extends StatefulWidget {
  int? id;
  String? role;

  desktopGrievanceDetails({super.key, required this.id, required this.role});

  @override
  State<desktopGrievanceDetails> createState() => _desktopGrievanceDetailsState();
}

class _desktopGrievanceDetailsState extends State<desktopGrievanceDetails> {
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
        leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back,color: Colors.white,)),
        title: Text("Grievance Details", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          width: 1200,
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(height: 20),
              Expanded(
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
                    } else if (grievance.status == 'Resolved' || grievance.status == 'Closed') {
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
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      grievance.title,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        _buildStatusChip(grievance.priority, priorityColor),
                                        SizedBox(width: 10),
                                        _buildStatusChip(grievance.status, statusColor),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
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
                                if (widget.role == "admin" || widget.role == "hr")
                                  _buildUpdateSection(grievance),
                                SizedBox(height: 20),

                                _buildTextField(feedback, "Feedback", Icons.feedback,
                                    maxLines: 5),
                                SizedBox(height: 20),

                                if (widget.role == "admin" || widget.role == "hr")
                                  _buildUpdateButton(),
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
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.secondaryColor,
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 0, 0),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEmployeeDetails(Grievance grievance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDetailRow("Name", grievance.my_name),
          _buildDetailRow("Employee ID", grievance.my_employee_id),
        ],
      ),
    );
  }

  Widget _buildAccusedDetails(Grievance grievance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDetailRow("Name", grievance.complain_against_name),
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedTo(Grievance grievance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 0, 0),
      child: Text(
        grievance.assignTo,
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFeedback(Grievance grievance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 0, 0),
      child: Text(
        grievance.feedback,
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildUpdateSection(Grievance grievance) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
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
    );
  }

  Widget _buildDropdownSection(String title, String? value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            color: AppColors.secondaryColor,
            fontWeight: FontWeight.bold
          ),
        ),
        SizedBox(height: 10),
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
    );
  }

  Widget _buildUpdateButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          selectedStatus ??= defaultStatus;
          selectedUserEmail ??= defaultEmail;
          selectedPriority ??= defaultPriority;
          try {
            grievanceDB.updateStatus(
              widget.id!,
              selectedUserEmail!,
              selectedStatus!,
              selectedPriority!,
              feedback.text,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Grievance Updated")),
            );
            Navigator.pop(context);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: $e")),
            );
          }
        },
        child: Text(
          "Update",
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Future<List<String>> fetchUsersEmails() async {
    final response = await Supabase.instance.client.from('users').select('email');
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