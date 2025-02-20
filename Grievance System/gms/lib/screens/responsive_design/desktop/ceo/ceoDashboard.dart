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

class desktopCeoDashboard extends StatefulWidget {
  const desktopCeoDashboard({super.key});

  @override
  State<desktopCeoDashboard> createState() => _desktopCeoDashboardState();
}

class _desktopCeoDashboardState extends State<desktopCeoDashboard> {
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
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Grievance Overview",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(child: desktopGrievanceChart()),
                        SizedBox(height: 10),
                        // Grievances List
                        Container(
                          padding: EdgeInsets.all(10),
                          width: double.infinity,
                          color: AppColors.primaryColor,
                          child: Center(
                            child: Text(
                              "Grievances",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
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

    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.black87,
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Image(image: AssetImage("assets/images/logo.png"),width: 150,),
          Text("CEO Dashboard", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
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
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: TextStyle(color: Colors.white)),
      onTap: onPressed,
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Grievances", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildGrievanceList() {
    return Expanded(
      child: StreamBuilder(
        stream: grievanceDB.stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
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
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  contentPadding: EdgeInsets.all(15),
                  title: Text(grievance.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(grievance.category, style: TextStyle(color: AppColors.secondaryColor)),
                      SizedBox(height: 5),
                      Text(grievance.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: priorityColor,
                                  borderRadius:
                                  BorderRadius.circular(4),
                                ),
                                child: Text(
                                  grievance.priority,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12),
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius:
                                  BorderRadius.circular(4),
                                ),
                                child: Text(
                                  grievance.status,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12),
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
                            style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.black54)),
                            child: Text("View Details", style: TextStyle(color: Colors.white, fontSize: 14)),
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
