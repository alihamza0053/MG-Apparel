import 'package:flutter/material.dart';
import 'package:grievance_system/screens/dashboard/dashboard.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'fileViewerScreen.dart';


class GrievanceDetailsScreen extends StatefulWidget {
  final String grievanceId;

  GrievanceDetailsScreen({required this.grievanceId});

  @override
  _GrievanceDetailsScreenState createState() => _GrievanceDetailsScreenState();
}

class _GrievanceDetailsScreenState extends State<GrievanceDetailsScreen> {
  Map<String, dynamic>? grievanceData;
  String? selectedStatus;
  String? selectedAssignee;
  String role = "";
  bool isAssigned = false;
  List<String> usersList = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _role();
    _fetchGrievance();
  }

  // is admin SharedPreferences
  Future<void> _role() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role') ?? "";
    });
  }
  // Fetch grievance data using grievance_details.php
  Future<void> _fetchGrievance() async {
    try {
      final response = await http.post(
        Uri.parse('https://groundup.pk/gms/grievance_details.php'),
        body: {'id': widget.grievanceId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          print(data['data']);
          setState(() {
            grievanceData = data['data'];
            selectedStatus = grievanceData!['status'];
            selectedAssignee = grievanceData!['assigned_to'];
            print(grievanceData!['assigned_to']);
          });

        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Grievance not found.')),
          );

          print(response.body);
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading grievance details.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Fetch users for the 'Assigned To' dropdown
  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('https://groundup.pk/gms/get_users.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          print(data['data']);
          setState(() {
            usersList = List<String>.from(data['data'].map((user) => user['email']));
          });
          if (selectedAssignee == null && usersList.isNotEmpty) {
            selectedAssignee = usersList[0]; // Default to first user if no assignee
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading users list1.')),
          );
          print(usersList);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users list.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // // Check if the current user is admin or assigned to the grievance
  // Future<void> _checkUserRole() async {
  //   final currentUserEmail = 'alihamza00053@gmail.com'; // Replace with actual user email if needed
  //   setState(() {
  //     isAdmin = currentUserEmail == 'alihamza00053@gmail.com'; // Replace with actual admin check
  //     isAssigned = grievanceData?['assignedTo']?.trim() == currentUserEmail.trim();
  //   });
  // }

  Future<bool> updateGrievance(String grievanceId, String assignedTo, String status) async {
    try {
      final response = await http.post(
        Uri.parse('https://groundup.pk/gms/update_grievance.php'),
        body: {
          'grievanceId': grievanceId,
          'assignedTo': assignedTo,
          'status': status,
        },
      );

      print(response.body); // Log the server's response for debugging.

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Dashboard()));
        return data['success'] ?? false;
      } else {
        print("HTTP Error: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Exception occurred: $e");
      return false;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Grievance Details')),
      body: grievanceData == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title: ${grievanceData!['title']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Description: ${grievanceData!['description']}'),

            SizedBox(height: 10),
            Text('Category: ${grievanceData!['category']}'),

            SizedBox(height: 10),
            role=="hr" || role=="admin" ?
            Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Status: ',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(width: 10),
                    // Status dropdown
                    DropdownButton<String>(
                      value: selectedStatus,
                      items: ['Pending', 'In Progress', 'Resolved', 'Closed']
                          .map((status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      ))
                          .toList(),
                      onChanged: (newStatus) {
                        if (newStatus != null) {
                          setState(() {
                            selectedStatus = newStatus;
                          });
                        }
                      },
                    ),
                  ],
                ),
                role == "admin" ?
                Row(
                  children: [
                    Text(
                      'Assigned To: ',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(width: 10),
                    DropdownButton<String>(
                      value: usersList.contains(selectedAssignee) ? selectedAssignee : null,
                      hint: Text('Select Assignee'),
                      items: usersList
                          .map((assigned) => DropdownMenuItem<String>(
                        value: assigned,
                        child: Text(assigned),
                      ))
                          .toList(),
                      onChanged: (newAssign) {
                        if (newAssign != null) {
                          setState(() {
                            selectedAssignee = newAssign;
                          });
                        }
                      },
                    ),
                  ],
                ) : SizedBox(),

              ],
            ) :
            Text('Status: ${grievanceData!['status']}'),
            SizedBox(height: 10),
            Text('Submission Date: ${grievanceData!['created_at']}'),
            SizedBox(height: 10),
            Text('Assigned To: ${grievanceData!['assigned_to'] ?? 'Not assigned yet'}'),
            SizedBox(height: 10),
            Text('Last Updated: ${grievanceData!['updated_at']}'),
            SizedBox(height: 20),

            if (grievanceData?['file_url'] != null)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FileViewerScreen(fileUrl: grievanceData!['file_path']),
                    ),
                  );
                },
                child: Text(
                  'File: Click to View',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            if (role=="admin" || role == "hr")
              ElevatedButton(onPressed: (){
                updateGrievance(widget.grievanceId ,selectedAssignee.toString(), selectedStatus.toString());
              }, child: Text("Update")),
          ],
        ),
      ),
    );
  }
}