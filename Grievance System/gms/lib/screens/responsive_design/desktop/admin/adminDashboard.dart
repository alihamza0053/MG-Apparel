import 'package:flutter/material.dart';
import 'package:gms/screens/chart/GrievanceChart.dart';
import 'package:gms/screens/chart/desktopChart.dart';
import 'package:gms/screens/chart/mobileChart.dart';
import 'package:gms/screens/credentials/auth/authService.dart';
import 'package:gms/screens/credentials/login.dart';
import 'package:gms/screens/credentials/users/userDatabase.dart';
import 'package:gms/screens/database/grievanceDatabase.dart';
import 'package:gms/screens/grievanceDetails.dart';
import 'package:gms/screens/newGrievance.dart';
import 'package:gms/screens/responsive_design/responsive/rGrievanceDetails.dart';
import 'package:gms/screens/responsive_design/responsive/rNewGrievance.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../theme/themeData.dart';
import '../../responsive/rLogin.dart';
import '../../responsive/rUsers.dart';

class desktopAdminDashboard extends StatefulWidget {
  const desktopAdminDashboard({super.key});

  @override
  State<desktopAdminDashboard> createState() => _desktopAdminDashboardState();
}

class _desktopAdminDashboardState extends State<desktopAdminDashboard> {
  final grievanceDB = GrievanceDB();
  final usersDB = UserDatabase();
  Color statusColor = Colors.red;
  Color priorityColor = Colors.orange;
  AuthService authService = AuthService();
  String role = "hr";

  @override
  void initState() {
    super.initState();
    fetchUserRole();
  }

  Future<void> fetchUserRole() async {
    try {
      SupabaseClient supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('users')
          .select('role')
          .eq('email', user.email as Object)
          .maybeSingle();

      if (response != null && response['role'] != null) {
        setState(() {
          role = response['role'];
        });
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECEFF1),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Grievance Overview",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(child: desktopGrievanceChart()),
                        SizedBox(height: 12),
                        // Grievances List
                        Container(
                          padding: EdgeInsets.all(10),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              "Grievances",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildGrievanceList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => rNewGrievance()));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 5),
            Text(
              "Add Grievance",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.black87,
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Image(
            image: AssetImage("assets/images/logo.png"),
            width: 100,
          ),
          SizedBox(height: 12),
          Text(
            "Admin Dashboard",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          _buildSidebarButton("Users", Icons.supervised_user_circle_outlined, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => rUsers()));
          }),
          _buildSidebarButton("Logout", Icons.logout, () {
            authService.signOut();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => rLogin()));
          }),
        ],
      ),
    );
  }

  Widget _buildSidebarButton(String title, IconData icon, VoidCallback onPressed) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 20),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      hoverColor: Colors.white.withOpacity(0.1),
      onTap: onPressed,
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Grievances",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGrievanceList() {
    return Expanded(
      child: StreamBuilder(
        stream: grievanceDB.stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.hourglass_empty,
                  size: 80,
                  color: Colors.grey.shade600,
                ),
                SizedBox(height: 10),
                Text(
                  "Loading Grievances",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Please wait...",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            );
          }

          final grievances = snapshot.data!;

          return ListView.builder(
            itemCount: grievances.length,
            itemBuilder: (context, index) {
              final grievance = grievances[index];

              // Set status and priority colors
              statusColor = _getStatusColor(grievance.status);
              priorityColor = _getPriorityColor(grievance.priority);
              return Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.grey.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grievance.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        grievance.category,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryColor,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        grievance.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: priorityColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  grievance.priority,
                                  style: TextStyle(
                                    color: priorityColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  grievance.status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) => rGrievanceDetails(id: grievance.id, role: 'admin'),
                              ));
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.secondaryColor,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "View Details",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String priority, String status) {
    Color getStatusColor(String status) {
      switch (status) {
        case 'Pending': return Colors.red;
        case 'In Progress': return Colors.blue;
        case 'Resolved': return Colors.green;
        case 'Closed': return Colors.green;
        default: return Colors.grey;
      }
    }
    return Row(
      children: [
        Chip(label: Text(priority), backgroundColor: Colors.orange),
        SizedBox(width: 10),
        Chip(label: Text(status), backgroundColor: getStatusColor(status)),
      ],
    );
  }

  // Helper function to get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.red;
      case 'In Progress':
        return Colors.blue;
      case 'Resolved':
      case 'Closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Helper function to get priority color
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.orange;
      case 'High':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}