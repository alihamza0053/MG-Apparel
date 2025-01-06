import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


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
  bool isAdmin = false;
  bool isAssigned = false;
  List<String> usersList = [];

  @override
  void initState() {
    super.initState();
    _fetchGrievance();
    _fetchUsers();
    _checkUserRole();
  }

  // Fetch grievance data using grievance_details.php
  Future<void> _fetchGrievance() async {
    try {
      final response = await http.post(
        Uri.parse('https://gms.alihamza.me/grievance_details.php'),
        body: {'id': widget.grievanceId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            grievanceData = data['data'];
            selectedStatus = grievanceData!['status'];
            selectedAssignee = grievanceData!['assignedTo'] ?? null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Grievance not found.')),
          );
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
      final response = await http.get(Uri.parse('https://gms.alihamza.me/get_users.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
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
          print(response.body);
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

  // Check if the current user is admin or assigned to the grievance
  Future<void> _checkUserRole() async {
    final currentUserEmail = 'alihamza00053@gmail.com'; // Replace with actual user email if needed
    setState(() {
      isAdmin = currentUserEmail == 'alihamza00053@gmail.com'; // Replace with actual admin check
      isAssigned = grievanceData?['assignedTo']?.trim() == currentUserEmail.trim();
    });
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
            Text('Status: ${grievanceData!['status']}'),
            SizedBox(height: 10),
            Text('Submission Date: ${grievanceData!['submissionDate']}'),
            SizedBox(height: 10),
            Text('Assigned To: ${grievanceData!['assignedTo'] ?? 'Not assigned yet'}'),
            SizedBox(height: 10),
            Text('Last Updated: ${grievanceData!['lastUpdatedDate']}'),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}