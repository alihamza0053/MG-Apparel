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
  String? _selectedFilter = "All";
  final List<String> _filterOptions = ["All", "Pending", "In Progress", "Resolved", "Closed"];

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
              ..sort((a, b) => b.updateAt.compareTo(a.updateAt));
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
      backgroundColor: Color(0xFFECEFF1),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => rNewGrievance()));
        },
        backgroundColor: AppColors.primaryColor,
        label: const Text("New Grievance", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset("assets/images/logo.png"),
        ),
        title: const Text("Employee Dashboard",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor
            )
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextButton.icon(
              onPressed: () {
                authService.signOut();
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => rLogin()));
              },
              icon: const Icon(Icons.logout, size: 20),
              label: const Text("Logout", style: TextStyle(fontSize: 14)),
              style: TextButton.styleFrom(foregroundColor: AppColors.secondaryColor),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "My Grievances",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Track and manage all your submitted grievances",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        hint: const Text("Filter by status"),
                        items: _filterOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedFilter = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder(
                stream: filterStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                      ),
                    );
                  }

                  List<Grievance> grievances = snapshot.data!;

                  if (_selectedFilter != "All") {
                    grievances = grievances.where((g) => g.status == _selectedFilter).toList();
                  }

                  if (grievances.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 20),
                          Text(
                            "No grievances found",
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Click on 'New Grievance' to submit a new request",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 2.0,
                    ),
                    itemCount: grievances.length,
                    itemBuilder: (context, index) {
                      final grievance = grievances[index];

                      IconData statusIcon;
                      switch (grievance.status) {
                        case 'Pending':
                          statusColor = Colors.orange;
                          statusIcon = Icons.hourglass_empty;
                          break;
                        case 'In Progress':
                          statusColor = Colors.blue;
                          statusIcon = Icons.autorenew;
                          break;
                        case 'Resolved':
                          statusColor = Colors.green;
                          statusIcon = Icons.check_circle;
                          break;
                        case 'Closed':
                          statusColor = Colors.grey;
                          statusIcon = Icons.archive;
                          break;
                        default:
                          statusColor = Colors.orange;
                          statusIcon = Icons.help_outline;
                      }

                      String formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(grievance.updateAt));

                      // Split semicolon-separated accused data
                      final accusedNames = grievance.complain_against_name.split(';');
                      final accusedDisplay = accusedNames.length > 1
                          ? "${accusedNames[0]} +${accusedNames.length - 1} others"
                          : accusedNames[0];

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
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.white, Colors.grey.shade50],
                              ),
                            ),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(statusIcon, color: statusColor, size: 16),
                                          const SizedBox(width: 5),
                                          Text(
                                            grievance.status,
                                            style: TextStyle(color: statusColor, fontWeight: FontWeight.w500, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Complainant: ${grievance.my_name} (${grievance.my_position})",
                                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Against: $accusedDisplay",
                                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  grievance.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.3),
                                ),
                                const Spacer(),
                                Container(
                                  height: 1,
                                  color: Colors.grey.shade200,
                                  margin: EdgeInsets.symmetric(vertical: 10),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 5),
                                        Text(
                                            "Assigned: ${grievance.assignTo.isEmpty ? 'Unassigned' : grievance.assignTo}",
                                            style: TextStyle(fontSize: 13, color: Colors.grey[700])
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 5),
                                        Text(
                                            formattedDate,
                                            style: TextStyle(fontSize: 13, color: Colors.grey[700])
                                        ),
                                      ],
                                    ),
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