import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/auth/authService.dart';
import 'package:gms/theme/themeData.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../credentials/login.dart';
import '../database/grievance.dart';
import '../grievanceDetails.dart';
import '../newGrievance.dart';

class Employee extends StatefulWidget {
  const Employee({super.key});

  @override
  State<Employee> createState() => _EmployeeState();
}

class _EmployeeState extends State<Employee> {
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
              context, MaterialPageRoute(builder: (context) => NewGrievanceScreen()));
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(
        title: const Text("Dashboard",style: TextStyle(fontSize: 25),),
        actions: [
          GestureDetector(
            onTap: () {
              authService.signOut();
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => Login()));
            },

            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
              child: const Row(
                children: [Text("Logout", style: TextStyle(color: Colors.white),), Icon(Icons.logout,color: Colors.white,)],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(200, 20, 200, 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 900 ? 2 : 1; // Responsive columns

            return Column(
              children: [
                Text("All Grievances",style: TextStyle(fontSize: 30),),
                SizedBox(height: 50,),
                Expanded(
                  child: StreamBuilder(
                      stream: filterStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                  
                        final grievances = snapshot.data!;
                  
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 30,
                            mainAxisSpacing: 30,
                            childAspectRatio: 3.0, // Adjust card size
                          ),
                          itemCount: grievances.length,
                          itemBuilder: (context, index) {
                            final grievance = grievances[index];
                  
                            switch (grievance.status) {
                              case 'pending':
                                statusColor = Colors.orange;
                                break;
                              case 'in progress':
                                statusColor = Colors.indigo;
                                break;
                              case 'resolved':
                                statusColor = Colors.green;
                                break;
                              case 'closed':
                                statusColor = Colors.red;
                                break;
                            }
                            String formatDate(String isoString) {
                              DateTime dateTime = DateTime.parse(isoString); // Parse ISO string
                              return DateFormat('yyyy-MM-dd').format(dateTime); // Format as YYYY-MM-DD
                            }
                            String formattedDate = formatDate(grievance.updateAt);
                  
                  
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Grievancedetails(
                                            id: grievance.id, role: 'employee')));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    border: Border.all(width: 1, color: AppColors.primaryColor),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              grievance.title,
                                              style: TextStyle(
                                                  fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(width: 10,),
                                            Text(
                                              grievance.category,
                                              style: TextStyle(
                                                  fontSize: 12,color: AppColors.secondaryColor),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          color: statusColor,
                                          child: Text(
                                            grievance.status,
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      grievance.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w100,
                                          color: Color(0xffb8b8b8)),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Text("Assigned to: ", style: TextStyle(fontSize: 14)),
                                            SizedBox(width: 10,),
                                            Text(grievance.assignTo, style: const TextStyle(fontSize: 12,color: AppColors.secondaryColor))
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Text("Updated at: ", style: TextStyle(fontSize: 14)),
                                            SizedBox(width: 10,),
                                            Text(formattedDate, style: const TextStyle(fontSize: 12,color: AppColors.secondaryColor))
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
