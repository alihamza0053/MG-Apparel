import 'package:flutter/material.dart';
import 'package:grievance_system/screens/dashboard/closedGrievance.dart';
import 'package:grievance_system/screens/dashboard/inProgressGrievance.dart';
import 'package:grievance_system/screens/dashboard/pendingGrievance.dart';
import 'package:grievance_system/screens/dashboard/resolvedGrievance.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../loginScreen.dart';
import '../newGrievanceScreen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {

  // Handle logout
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userEmail'); // Remove user email from SharedPreferences
    await prefs.remove('isLoggedIn');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()), // Navigate back to LoginPage
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Dashboard"),
          actions: [
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Coming Soon"))),
            ),
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout, // Call logout method when logout icon is pressed
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                text: "Pending",
              ),
              Tab(
                text: "In Progress",
              ),
              Tab(
                text: "Resolved",
              ),
              Tab(
                text: "Closed",
              )
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            // Navigate to the NewGrievanceScreen and wait for a result
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => NewGrievanceScreen()), // Navigate to NewGrievanceScreen
            );
            // If grievance is submitted, refresh the list
            if (result == true) {
              // Data will refresh automatically because of StreamBuilder
            }
          },
          child: Icon(Icons.add),
        ),

        body: TabBarView(
        children: [
          pendingGrievance(),
          inProgressGrievance(),
          resolvedGrievance(),
          closedGrievance(),
        ]),
      ),
    );
  }
}
