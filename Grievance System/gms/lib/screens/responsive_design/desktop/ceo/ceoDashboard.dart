import 'package:flutter/material.dart';
import 'package:gms/screens/chart/GrievanceChart.dart';
import 'package:gms/screens/credentials/auth/authService.dart';
import 'package:gms/screens/credentials/login.dart';
import 'package:gms/screens/credentials/userData.dart';
import 'package:gms/screens/credentials/users/userDatabase.dart';
import 'package:gms/screens/database/grievanceDatabase.dart';
import 'package:gms/screens/grievanceDetails.dart';
import 'package:gms/screens/newGrievance.dart';
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
  String priority = "Low";
  String status = "Pending";
  AuthService authService = AuthService();
  String role = "hr";


  @override
  void initState() {
    super.initState();
    fetchUserRole(); // Fetch user role when dashboard loads
  }

  // Function to fetch user role from Supabase
  Future<void> fetchUserRole() async {
    try {
      SupabaseClient supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser; // Get logged-in user
      if (user == null) return;

      final response = await supabase
          .from('users') // Your users table
          .select('role') // Fetch only the role column
          .eq('email', user.email as Object) // Filter by user's email
          .maybeSingle(); // Get single result

      if (response != null && response['role'] != null) {
        setState(() {
          role = response['role']; // Set user role
        });
      }

      print("🔹 User Role: $role"); // Debug log
    } catch (e) {
      print("❌ Error fetching user role: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(

          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => rNewGrievance()));
          },
          backgroundColor: Colors.blueAccent,
          child: Text("Add",style: TextStyle(color: Colors.white),)
      ),
      appBar: AppBar(
        title: Text("Dashboard", style: TextStyle(fontSize: 25),),
        actions: [
          IconButton(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context)=> rUsers()));
          }, icon: Icon(Icons.supervised_user_circle_outlined, color: Colors.white, size: 30,)),
          GestureDetector(
            onTap: (){
              authService.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>rLogin()));
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: Row(
                children: [
                  Text("Logout", style: TextStyle(color: Colors.white),),
                  Icon(Icons.logout,color: Colors.white),

                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(50),
        child: Column(
          children: [
            Expanded(child: GrievanceChart()),
            SizedBox(height: 10,),
            Row(
              children: [
                SizedBox(width: 20,),
                Text("Grievances",style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),
              ],
            ),
            Expanded(
              child: StreamBuilder(stream: grievanceDB.stream, builder: (context, snapshot){
                print("connection");
                print(snapshot.error);
                //loading
                if(!snapshot.hasData){
                  return Center(child: CircularProgressIndicator(),);
                }

                final  grievances = snapshot.data!;
                print(grievances);

                return ListView.builder(
                    itemCount: grievances.length,
                    itemBuilder: (context,index){
                      final grievance = grievances[index];

                      if(grievance.status == 'Pending'){
                        statusColor = Colors.red;
                      }
                      if(grievance.status == 'In Progress'){
                        statusColor = Colors.blue;
                      }
                      if(grievance.status == 'Resolved'){
                        statusColor = Colors.green;
                      }
                      if(grievance.status == 'Closed'){
                        statusColor = Colors.green;
                      }
                      if(grievance.priority == 'Low'){
                        priorityColor = Colors.orange;
                      }
                      if(grievance.priority == 'High'){
                        priorityColor = Colors.red;
                      }
                      return Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context)=>Grievancedetails(id:grievance.id,role:'admin')));
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    border: Border.all(width: 1, color: AppColors.primaryColor),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                                              color: priorityColor,
                                              child: Text(grievance.priority,style: TextStyle(color: Colors.white),),
                                            ),
                                            SizedBox(width: 10,),
                                            Container(
                                              padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                                              color: statusColor,
                                              child: Text(grievance.status,style: TextStyle(color: Colors.white),),
                                            ),
                                          ],
                                        ),

                                      ],
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      grievance.description,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w100,
                                          color: Color(0xffb8b8b8)),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              "Assigned to: ",
                                              style: TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              grievance.assignTo,
                                              style: TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),

                                        TextButton(
                                            style: ButtonStyle(
                                              backgroundColor: MaterialStateProperty.all(Colors.black54),

                                            ),
                                            onPressed: (){
                                              Navigator.push(context, MaterialPageRoute(builder: (context)=>Grievancedetails(id:grievance.id,role:'admin')));
                                              print("grievance.id");
                                              print(grievance.id);
                                            }, child: Text("View Details",style: TextStyle(color: Colors.white,fontSize: 12),)),
                                      ],

                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    });
              }),
            ),
          ],
        ),
      ),
    );
  }
}
