import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/auth/authService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../credentials/login.dart';
import '../credentials/userData.dart';
import '../database/grievance.dart';
import '../grievanceDetails.dart';
import '../newGrievance.dart';

class hr extends StatefulWidget {
  const hr({super.key});

  @override
  State<hr> createState() => _hrState();
}

class _hrState extends State<hr> {
  Color statusColor = Colors.orangeAccent;
  String status = "Pending";
  AuthService authService = AuthService();
  String role = "hr";

  Stream<List<Grievance>>? filterStream;


  void initializeStream() {
    String? currentUserEmail = authService.getUserEmail();

    if (currentUserEmail != null) {
      setState(() {
        filterStream = Supabase.instance.client
            .from('grievance')
            .stream(primaryKey: ['id'])
            .eq('submittedBy', currentUserEmail) // Filter by logged-in user
            .map((data) {
          try {
            print("📡 Received Data from Supabase: $data"); // Debug log

            // Convert to List<Grievance> and sort by ID
            final grievances = data
                .map((grievanceMap) => Grievance.fromMap(grievanceMap))
                .toList()
              ..sort((a, b) => a.id!.compareTo(b.id!)); // Sort by ID

            print("✅ Sorted Grievances: $grievances"); // Debug log
            return grievances;
          } catch (e) {
            print("❌ Error processing grievance data: $e");
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

  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => NewGrievanceScreen()));
        },
        backgroundColor: Colors.blueAccent,
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      appBar: AppBar(
        title: Text("Dashboard"),
        actions: [
          GestureDetector(
            onTap: (){
              authService.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Login()));
            },
            child: Row(
              children: [
                Text("Logout"),
                Icon(Icons.logout),

              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder(stream: filterStream, builder: (context, snapshot){
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

              if(grievance.status == 'pending'){
                statusColor = Colors.orange;
              }
              if(grievance.status == 'in progress'){
                statusColor = Colors.indigo;
              }
              if(grievance.status == 'resolved'){
                statusColor = Colors.green;
              }
              if(grievance.status == 'closed'){
                statusColor = Colors.red;
              }
              return Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>Grievancedetails(id:grievance.id,role:'hr')));
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            border: Border.all(width: 1, color: Colors.white),
                            borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  grievance.title,
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                                  color: statusColor,
                                  child: Text(grievance.status),
                                )
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
                                )
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
    );
  }
}
