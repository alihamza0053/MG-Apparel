import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/auth/authService.dart';
import 'package:gms/screens/responsive_design/desktop/login.dart';
import 'package:gms/screens/responsive_design/responsive/rGrievanceDetails.dart';
import 'package:gms/screens/responsive_design/responsive/rLogin.dart';
import 'package:gms/screens/responsive_design/responsive/rNewGrievance.dart';
import 'package:gms/theme/themeData.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../database/grievance.dart';
import '../../../grievanceDetails.dart';
import '../../../newGrievance.dart';
import '../grievanceDetails.dart';
import '../newGrievance.dart';

class desktopEmployeeDashboard extends StatefulWidget {
  const desktopEmployeeDashboard({super.key});

  @override
  State<desktopEmployeeDashboard> createState() => _desktopEmployeeDashboardState();
}

class _desktopEmployeeDashboardState extends State<desktopEmployeeDashboard> {
  Color statusColor = Colors.orangeAccent;
  AuthService authService = AuthService();
  Stream<List<Grievance>>? filterStream;

  void initializeStream() {
    String? currentUserEmail = authService.getUserEmail();

    if (currentUserEmail != null) {
      setState(() {
        filterStream = Supabase.instance.client
            .from('grievance')
            .stream(primaryKey: ['id'])
            .eq('submittedBy', currentUserEmail)
            .map((data) {
          try {
            return data.map((grievanceMap) => Grievance.fromMap(grievanceMap)).toList()
              ..sort((a, b) => a.id!.compareTo(b.id!));
          } catch (e) {
            return [];
          }
        });
      });
    }
  }

  @override
  void initState() {
    initializeStream();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => rNewGrievance()));
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              onPressed: () {
                authService.signOut();
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => rLogin()));
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text("Logout", style: TextStyle(color: Colors.white,fontSize: 14)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryColor),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("All Grievances", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder(
                stream: filterStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final grievances = snapshot.data!;
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 3.0,
                    ),
                    itemCount: grievances.length,
                    itemBuilder: (context, index) {
                      final grievance = grievances[index];

                      switch (grievance.status) {
                        case 'Pending':
                          statusColor = Colors.red;
                          break;
                        case 'In Progress':
                          statusColor = Colors.blue;
                          break;
                        case 'Resolved':
                        case 'Closed':
                          statusColor = Colors.green;
                          break;
                      }

                      String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(grievance.updateAt));

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => rGrievanceDetails(id: grievance.id, role: 'employee'),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        grievance.title,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        grievance.status,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  grievance.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Assigned to: ${grievance.assignTo}", style: const TextStyle(fontSize: 14)),
                                    Text("Updated: $formattedDate", style: const TextStyle(fontSize: 14, color: Colors.blueGrey)),
                                  ],
                                ),
                              ],
                            ),
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
    );
  }
}
