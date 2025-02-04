import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../grievanceDetailsScreen.dart';
import '../usersScreen.dart';


class pendingGrievance extends StatefulWidget {
  const pendingGrievance({super.key});

  @override
  State<pendingGrievance> createState() => _pendingGrievanceState();
}

class _pendingGrievanceState extends State<pendingGrievance> {
  final StreamController<List<Map<String, dynamic>>> _grievancesController = StreamController.broadcast();
  String userEmail = ''; // Default value to avoid initialization issues
  String role = '';      // Default value to avoid initialization issues
  Timer? _timer;


  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _startFetchingGrievances();
    fetchGrievancesStream();
  }


  void _startFetchingGrievances() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) async {
      final response = await http.get(Uri.parse('https://groundup.pk/gms/get_grievances.php'));

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> grievances =
        List<Map<String, dynamic>>.from(json.decode(response.body)['data']);


        // Filter and add grievances to the stream
        _grievancesController.add(
          grievances.where((grievance) => grievance['status'] == 'Pending').toList(),
        );
      } else {
        print('Failed to load grievances');
      }
    });
  }
  //user details
  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail') ?? '';
      role = prefs.getString('role') ?? '';
    });
  }


  // Stream that listens for grievance updates
  Stream<List<Map<String, dynamic>>> fetchGrievancesStream() async* {
    while (true) {
      final response = await http
          .get(Uri.parse('https://groundup.pk/gms/get_grievances.php'));

      print('Content-Length: ${response.headers['content-length']}');
      if (response.statusCode == 200) {
        List<Map<String, dynamic>> grievances =
        List<Map<String, dynamic>>.from(json.decode(response.body)['data']);
        print("all grievance");
        print(grievances);
        yield grievances; // Yield data whenever there's a new grievance
      } else {
        throw Exception('Failed to load grievances');
      }


      await Future.delayed(Duration(seconds: 5)); // Re-fetch every 5 seconds
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [

          // Show "Users" button only for admin role
          role == 'admin'
              ? ElevatedButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => UsersScreen()));
            },
            child: Text("Users"),
          )
              : SizedBox(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _grievancesController.stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                // Fetch grievances data
                final allGrievances = snapshot.data ?? [];

                // Apply filtering logic
                final grievances = role == 'admin'
                    ? allGrievances.where((grievance) => grievance['status'] == 'Pending').toList() // Show only pending grievances for admin
                    : allGrievances.where((grievance) {
                  final assignedTo = grievance['assigned_to'] ?? '';
                  final submittedBy = grievance['submitted_by'] ?? '';
                  return (assignedTo == userEmail || submittedBy == userEmail) &&
                      (grievance['status'] == 'Pending'); // Filter by pending status
                }).toList();
                print(grievances);
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
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GrievanceDetailsScreen(
                                  grievanceId: grievance[
                                  'id']), // Navigate to grievance details
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
