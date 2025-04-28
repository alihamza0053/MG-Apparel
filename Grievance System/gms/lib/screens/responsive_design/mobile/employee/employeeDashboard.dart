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
      backgroundColor: const Color(0xFFECEFF1), // Light gray background
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => rNewGrievance()));
        },
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white, size: 16),
        label: const Text(
          "Add Grievance",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox(),
        title: Text(
          "Dashboard",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              authService.signOut();
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => rLogin()));
            },
            icon: Icon(Icons.logout, color: AppColors.secondaryColor, size: 16),
            label: Text(
              "Logout",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                "assets/images/logo.png",
                width: 80,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "All Grievances",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade200, thickness: 1),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder(
                  stream: filterStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.hourglass_empty,
                              size: 80,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Loading Grievances...",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Please wait while we fetch your grievances.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final grievances = snapshot.data!;

                    if (grievances.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 80,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "No Grievances Found",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "You haven't submitted any grievances yet.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: grievances.length,
                      itemBuilder: (context, index) {
                        final grievance = grievances[index];

                        switch (grievance.status) {
                          case 'Pending':
                            statusColor = Colors.orange;
                            break;
                          case 'In Progress':
                            statusColor = Colors.blue;
                            break;
                          case 'Resolved':
                            statusColor = Colors.green;
                            break;
                          case 'Closed':
                            statusColor = Colors.grey;
                            break;
                        }

                        String formatDate(String isoString) {
                          DateTime dateTime = DateTime.parse(isoString);
                          return DateFormat('MMM dd, yyyy').format(dateTime);
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
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.grey.shade50],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        grievance.title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            grievance.status == 'Pending'
                                                ? Icons.hourglass_empty
                                                : grievance.status == 'In Progress'
                                                ? Icons.autorenew
                                                : grievance.status == 'Resolved'
                                                ? Icons.check_circle
                                                : Icons.archive,
                                            size: 16,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            grievance.status,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: statusColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  grievance.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              "Assigned to: ${grievance.assignTo}",
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "Updated: $formattedDate",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
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