import 'package:flutter/material.dart';
import 'package:gms/screens/loginScreen.dart';
import 'package:gms/screens/usersScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'grievanceDetailsScreen.dart';
import 'newGrievanceScreen.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Stream<List<Map<String, dynamic>>> _grievancesStream;
  String userEmail = '';
  String role = '';
  final SupabaseClient supabase = Supabase.instance.client;


  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _grievancesStream = fetchGrievancesStream();
  }

  Future<void> _loadUserDetails() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final userData = await supabase.from('users').select().eq('email', "alihamza00053@gmail.com").single();
      setState(() {
        userEmail = user.email ?? '';
        role = userData['role'] ?? '';
      });
    }
  }

  Stream<List<Map<String, dynamic>>> fetchGrievancesStream() async* {
    while (true) {
      final response = await supabase.from('grievances').select();
      yield List<Map<String, dynamic>>.from(response);
      await Future.delayed(Duration(seconds: 5));
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
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
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Coming Soon"))),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          role == 'admin'
              ? ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Usersscreen()));
            },
            child: Text("Users"),
          )
              : SizedBox(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _grievancesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final allGrievances = snapshot.data ?? [];
                final grievances = role == 'admin'
                    ? allGrievances
                    : allGrievances.where((grievance) {
                  final assignedTo = grievance['assigned_to'] ?? '';
                  final submittedBy = grievance['submitted_by'] ?? '';
                  return assignedTo == userEmail || submittedBy == userEmail;
                }).toList();
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Grievancedetailsscreen(
                                  grievanceId: grievance['id']),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NewGrievanceScreen()),
          );
          if (result == true) {
            // Data will refresh automatically because of StreamBuilder
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
