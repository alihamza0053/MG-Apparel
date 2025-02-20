import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/auth/authService.dart';
import 'package:gms/screens/responsive_design/mobile/login.dart';
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

class mobileEmployeeDashboard extends StatefulWidget {
  const mobileEmployeeDashboard({super.key});

  @override
  State<mobileEmployeeDashboard> createState() => _mobileEmployeeDashboardState();
}

class _mobileEmployeeDashboardState extends State<mobileEmployeeDashboard> {
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
        backgroundColor: Colors.blueAccent,
        child: Text("Add",style: TextStyle(color: Colors.white),),
      ),
      appBar: AppBar(
        leading: SizedBox(),
        title: const Text("Dashboard",style: TextStyle(fontSize: 20),),
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
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Image(image: AssetImage("assets/images/logo.png"),width: 80,),
            Text("All Grievances", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder(
                  stream: filterStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final grievances = snapshot.data!;

                    return ListView.builder(
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

                        String formatDate(String isoString) {
                          DateTime dateTime = DateTime.parse(isoString);
                          return DateFormat('yyyy-MM-dd').format(dateTime);
                        }

                        String formattedDate = formatDate(grievance.updateAt);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => rGrievanceDetails(
                                        id: grievance.id, role: 'employee')));
                          },
                          child: Card(
                            margin: EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          grievance.title,
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          grievance.status,
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                      )
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    grievance.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Assigned to: ${grievance.assignTo}", style: TextStyle(fontSize: 12)),
                                      Text("Updated at: $formattedDate", style: TextStyle(fontSize: 12))
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
