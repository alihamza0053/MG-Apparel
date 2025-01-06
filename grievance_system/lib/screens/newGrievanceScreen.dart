import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';



class NewGrievanceScreen extends StatefulWidget {
  @override
  _NewGrievanceScreenState createState() => _NewGrievanceScreenState();
}

class _NewGrievanceScreenState extends State<NewGrievanceScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String userEmail = "";

  @override
  void initState() {
    _loadUserEmail();
    super.initState();
  }

  // Load the user email from SharedPreferences
  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail') ?? '';
    });

  }
  Future<void> _submitGrievance() async {
    try {
      final response = await http.post(
        Uri.parse("https://gms.alihamza.me/gms/submit_grievance.php"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'status': 'Pending',
          'submittedBy': userEmail,
          'assignedTo': "Not Assigned",
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Grievance submitted successfully')),
          );
          Navigator.pop(context, true); // Return true to indicate submission success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${responseData['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Grievance')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _submitGrievance, child: Text('Submit')),
          ],
        ),
      ),
    );
  }
}
