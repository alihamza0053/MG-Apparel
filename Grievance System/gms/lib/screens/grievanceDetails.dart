import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/users/userDatabase.dart';
import 'package:gms/screens/database/grievanceDatabase.dart';
import 'package:gms/theme/themeData.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Grievancedetails extends StatefulWidget {
  int? id;
  String? role;

  Grievancedetails({super.key, required this.id, required this.role});

  @override
  State<Grievancedetails> createState() => _GrievancedetailsState();
}

class _GrievancedetailsState extends State<Grievancedetails> {
  final grievanceDB = GrievanceDB();
  final usersDB = UserDatabase();
  Color statusColor = Colors.orangeAccent;
  String? selectedStatus;
  String? selectedEmail;
  List<String> emailList = [];
  String? selectedUserEmail; // Selected email
  String defaultStatus = '';
  String defaultEmail = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
        ),
        title: Text("Grievance Details"),
      ),
      body: StreamBuilder(
          stream: grievanceDB.stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            final grievances = snapshot.data!;

            return ListView.builder(
                itemCount: 1,
                itemBuilder: (context, index) {
                  final grievance = grievances[widget.id! - 1];

                  if (grievance.status == 'pending') {
                    statusColor = Colors.orange;
                  }
                  if (grievance.status == 'in progress') {
                    statusColor = Colors.indigo;
                  }
                  if (grievance.status == 'resolved') {
                    statusColor = Colors.green;
                  }
                  if (grievance.status == 'closed') {
                    statusColor = Colors.red;
                  }

                  defaultStatus = grievance.status;
                  defaultEmail = grievance.assignTo;

                  return Padding(
                    padding: EdgeInsets.all(18),
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
                          "Description:",
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                          child: Text(
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            grievance.description,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w100,
                                color: Color(0xffb8b8b8)),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          "Other Details:",
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                          child: Text(
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            grievance.other,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w100,
                                color: Color(0xffb8b8b8)),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Assigned to: ",
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                          child: Text(
                            grievance.assignTo,
                            style: TextStyle(
                                fontSize: 16, color: Color(0xffb8b8b8)),
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        widget.role == "admin" || widget.role == "hr"?
                        Column(
                          children: [
                            Text(
                              "Update Status: ",
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: DropdownButton<String>(
                                dropdownColor: AppColors.primaryColor,
                                value: selectedStatus,
                                // Selected value
                                hint: Text(
                                  grievance.status,
                                  style: TextStyle(
                                      color: Colors.white), // Hint text color
                                ),
                                style: TextStyle(color: Colors.white),
                                // Selected item text color
                                items: [
                                  'pending',
                                  'in progress',
                                  'resolved',
                                  'closed',
                                ]
                                    .map((String status) => DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                        color: Colors
                                            .white), // Dropdown items text color
                                  ),
                                ))
                                    .toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedStatus =
                                        newValue; // Update selected value
                                  });
                                },
                              ),
                            ),
                          ],
                        ) : SizedBox(),

                        widget.role == "admin"?
                        Column(
                          children: [
                            SizedBox(
                              height: 15,
                            ),
                            Text(
                              "Update Assign Person: ",
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            // Fetch and Show Users in Dropdown
                            FutureBuilder<List<String>>(
                              future: fetchUsersEmails(), // Fetch emails
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return CircularProgressIndicator();
                                }

                                final userEmails = snapshot.data!;

                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                  child: DropdownButton<String>(
                                    dropdownColor: AppColors.primaryColor,
                                    value: selectedUserEmail,
                                    hint: Text(
                                      "Select Email to Assign",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: TextStyle(color: Colors.white),
                                    items: userEmails.map<DropdownMenuItem<String>>(
                                            (String email) {
                                          return DropdownMenuItem<String>(
                                            value: email,
                                            child: Text(
                                              email,
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedUserEmail = newValue;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ) : SizedBox(),



                        TextButton(
                            onPressed: () {
                              selectedStatus ??= defaultStatus;
                              selectedUserEmail ??= defaultEmail;
                              try{
                                grievanceDB.updateStatus(widget.id!, selectedUserEmail!, selectedStatus!);
                                print("${widget.id!}, ${selectedUserEmail!}, ${selectedStatus!}");
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Grievance Updated")));
                                Navigator.pop(context);
                              }catch(e){
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                              }
                            },
                            child: Text("Update"))
                      ],
                    ),
                  );
                });
          }),
    );
  }

  /// Fetch all user emails from the Supabase `users` table
  Future<List<String>> fetchUsersEmails() async {
    final response =
        await Supabase.instance.client.from('users').select('email');

    if (response.isEmpty) return [];

    return response.map<String>((row) => row['email'] as String).toList();
  }
}
