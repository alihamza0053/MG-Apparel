import 'package:flutter/material.dart';
import 'package:grievance_system/screens/loginScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'grievanceDetailsScreen.dart';
import 'newGrievanceScreen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Stream<List<Map<String, dynamic>>> _grievancesStream;
  late String userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail(); // Load the user's email from SharedPreferences
    _grievancesStream = fetchGrievancesStream();
  }

  // Load the user email from SharedPreferences
  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail') ?? '';
    });
  }

  // Stream that listens for grievance updates
  Stream<List<Map<String, dynamic>>> fetchGrievancesStream() async* {
    while (true) {
      final response = await http
          .get(Uri.parse('https://gms.alihamza.me/get_grievances.php'));

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> grievances =
            List<Map<String, dynamic>>.from(json.decode(response.body)['data']);
        yield grievances; // Yield data whenever there's a new grievance
      } else {
        throw Exception('Failed to load grievances');
      }

      await Future.delayed(Duration(
          seconds: 5)); // Re-fetch every 5 seconds to check for new data
    }
  }

  // Handle logout
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userEmail'); // Remove user email from SharedPreferences
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => LoginScreen()), // Navigate back to LoginPage
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => LoginScreen()), // Navigate to LoginPage
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed:
                _logout, // Call logout method when logout icon is pressed
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _grievancesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final grievances = snapshot.data ?? [];

          return ListView.builder(
            itemCount: grievances.length,
            itemBuilder: (context, index) {
              final grievance = grievances[index];
              return Card(
                child: ListTile(
                  title: Text(grievance['title'] ?? 'No Title'),
                  subtitle: Text(
                    'Status: ${grievance['status'] ?? 'No Status'}\nSubmitted By: ${grievance['submitted_by'] ?? 'Unknown'}',
                  ),
                  trailing: Text(
                    'Assigned To: ${grievance['assigned_to'] ?? 'Not Assigned'}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GrievanceDetailsScreen(
                          grievanceId:
                              grievance['id']), // Navigate to grievance details
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to the NewGrievanceScreen and wait for a result
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    NewGrievanceScreen()), // Navigate to NewGrievanceScreen
          );
          // If grievance is submitted, refresh the list
          if (result == true) {
            // Data will refresh automatically because of StreamBuilder
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
