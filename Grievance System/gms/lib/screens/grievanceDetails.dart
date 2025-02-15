import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/users/userDatabase.dart';
import 'package:gms/screens/database/grievanceDatabase.dart';
import 'package:gms/theme/themeData.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'database/grievance.dart';

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
  Color priorityColor = Colors.orange;
  String? selectedStatus;
  String? selectedEmail;
  String? selectedPriority;
  List<String> emailList = [];
  String? selectedUserEmail; // Selected email
  String defaultStatus = '';
  String defaultEmail = '';
  String defaultPriority = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: SizedBox(),
        title: Text("Grievance Details"),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: 100,
            ),
            Expanded(
              child: SizedBox(
                width: 700,
                child: Column(
                  children: [
                    Expanded(
                      child: StreamBuilder(
                          stream: grievanceDB.detailStream,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final grievances = snapshot.data!;

                            // Find grievance by ID safely
                            final grievance = grievances.firstWhere(
                              (g) => g.id == widget.id,
                            );

                            if (grievance == null) {
                              return Center(
                                child:
                                    Text("No record found for ID ${widget.id}"),
                              );
                            }

                            print("widget.id: ${widget.id}");

                            if (grievance.status == 'Pending') {
                              statusColor = Colors.red;
                            } else if (grievance.status == 'In Progress') {
                              statusColor = Colors.orange;
                            } else if (grievance.status == 'Resolved' ||
                                grievance.status == 'Closed') {
                              statusColor = Colors.green;
                            }
                            if (grievance.priority == 'Low') {
                              priorityColor = Colors.orange;
                            }
                            if (grievance.priority == 'High') {
                              priorityColor = Colors.red;
                            }
                            defaultStatus = grievance.status;
                            defaultEmail = grievance.assignTo;
                            defaultPriority = grievance.priority;

                            return ListView.builder(
                                itemCount: 1,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: EdgeInsets.all(18),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  width: 1,
                                                  color:
                                                      AppColors.primaryColor),
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                grievance.title,
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.bold),
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
                                        ),
                                        SizedBox(
                                          height: 25,
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  width: 1,
                                                  color:
                                                      AppColors.primaryColor),
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(),
                                              Text(
                                                "Description:",
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color: AppColors
                                                        .secondaryColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        10, 0, 0, 0),
                                                child: Text(
                                                  grievance.description,
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w100,
                                                      color: Colors.black),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: 25,
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  width: 1,
                                                  color:
                                                      AppColors.primaryColor),
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Employee Details: ",
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color: AppColors
                                                        .secondaryColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        10, 0, 0, 0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "Name: ",
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              color:
                                                                  Colors.black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        Text(
                                                          grievance.my_name,
                                                          style: TextStyle(
                                                              fontSize: 16,
                                                              color:
                                                                  Colors.black),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "Employee ID: ",
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              color:
                                                                  Colors.black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        Text(
                                                          grievance
                                                              .my_employee_id,
                                                          style: TextStyle(
                                                              fontSize: 16,
                                                              color:
                                                                  Colors.black),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: 25,
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  width: 1,
                                                  color:
                                                      AppColors.primaryColor),
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Accused Details: ",
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color: AppColors
                                                        .secondaryColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        10, 0, 0, 0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "Name: ",
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              color:
                                                                  Colors.black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        Text(
                                                          grievance
                                                              .complain_against_name,
                                                          style: TextStyle(
                                                              fontSize: 16,
                                                              color:
                                                                  Colors.black),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "Employee ID: ",
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              color:
                                                                  Colors.black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        Text(
                                                          grievance
                                                              .complain_against_id,
                                                          style: TextStyle(
                                                              fontSize: 16,
                                                              color:
                                                                  Colors.black),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: 25,
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  width: 1,
                                                  color:
                                                      AppColors.primaryColor),
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                          child: Row(
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Assigned to: ",
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        color: AppColors
                                                            .secondaryColor,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  SizedBox(
                                                    height: 10,
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .fromLTRB(10, 0, 0, 0),
                                                    child: Text(
                                                      grievance.assignTo,
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          color: Colors.black),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: 25,
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  width: 1,
                                                  color:
                                                      AppColors.primaryColor),
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              widget.role == "admin" ||
                                                      widget.role == "hr"
                                                  ? Column(
                                                      children: [
                                                        Text(
                                                          "Update Status: ",
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            color: AppColors
                                                                .secondaryColor,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          height: 10,
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .fromLTRB(
                                                                  10, 0, 0, 0),
                                                          child: DropdownButton<
                                                              String>(
                                                            dropdownColor:
                                                                AppColors
                                                                    .primaryColor,
                                                            value:
                                                                selectedStatus,
                                                            // Selected value
                                                            hint: Text(
                                                              "Select Status",
                                                              style: TextStyle(
                                                                  color: AppColors
                                                                      .primaryColor), // Hint text color
                                                            ),
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black),
                                                            // Selected item text color
                                                            items: [
                                                              'Pending',
                                                              'In Progress',
                                                              'Resolved',
                                                              'Closed',
                                                            ]
                                                                .map((String
                                                                        status) =>
                                                                    DropdownMenuItem<
                                                                        String>(
                                                                      value:
                                                                          status,
                                                                      child:
                                                                          Text(
                                                                        status,
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.black), // Dropdown items text color
                                                                      ),
                                                                    ))
                                                                .toList(),
                                                            onChanged: (String?
                                                                newValue) {
                                                              setState(() {
                                                                selectedStatus =
                                                                    newValue; // Update selected value
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : SizedBox(),
                                              widget.role == "admin"
                                                  ? Column(
                                                    children: [
                                                      Column(
                                                        children: [
                                                          Text(
                                                            "Update Priority: ",
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              color: AppColors
                                                                  .secondaryColor,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height: 10,
                                                          ),
                                                          Padding(
                                                            padding:
                                                            const EdgeInsets
                                                                .fromLTRB(
                                                                10, 0, 0, 0),
                                                            child: DropdownButton<
                                                                String>(
                                                              dropdownColor:
                                                              AppColors
                                                                  .primaryColor,
                                                              value:
                                                              selectedPriority,
                                                              // Selected value
                                                              hint: Text(
                                                                "Select Priority",
                                                                style: TextStyle(
                                                                    color: AppColors
                                                                        .primaryColor), // Hint text color
                                                              ),
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .black),
                                                              // Selected item text color
                                                              items: [
                                                                'Low',
                                                                'High',
                                                              ]
                                                                  .map((String
                                                              status) =>
                                                                  DropdownMenuItem<
                                                                      String>(
                                                                    value:
                                                                    status,
                                                                    child:
                                                                    Text(
                                                                      status,
                                                                      style: TextStyle(
                                                                          color:
                                                                          Colors.black), // Dropdown items text color
                                                                    ),
                                                                  ))
                                                                  .toList(),
                                                              onChanged: (String?
                                                              newValue) {
                                                                setState(() {
                                                                  selectedPriority =
                                                                      newValue; // Update selected value
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),


                                                      Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            SizedBox(
                                                              height: 15,
                                                            ),

                                                            Text(
                                                              "Update Assign Person: ",
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                color: AppColors
                                                                    .secondaryColor,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              height: 10,
                                                            ),
                                                            // Fetch and Show Users in Dropdown
                                                            FutureBuilder<
                                                                List<String>>(
                                                              future:
                                                                  fetchUsersEmails(),
                                                              // Fetch emails
                                                              builder: (context,
                                                                  snapshot) {
                                                                if (!snapshot
                                                                    .hasData) {
                                                                  return CircularProgressIndicator();
                                                                }

                                                                final userEmails =
                                                                    snapshot.data!;

                                                                return Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .fromLTRB(
                                                                          10,
                                                                          0,
                                                                          0,
                                                                          0),
                                                                  child:
                                                                      DropdownButton<
                                                                          String>(
                                                                    dropdownColor:
                                                                        AppColors
                                                                            .primaryColor,
                                                                    value:
                                                                        selectedUserEmail,
                                                                    hint: Text(
                                                                      "Select Email to Assign",
                                                                      style: TextStyle(
                                                                          color: AppColors
                                                                              .primaryColor),
                                                                    ),
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black),
                                                                    items: userEmails.map<
                                                                        DropdownMenuItem<
                                                                            String>>((String
                                                                        email) {
                                                                      return DropdownMenuItem<
                                                                          String>(
                                                                        value:
                                                                            email,
                                                                        child: Text(
                                                                          email,
                                                                          style: TextStyle(
                                                                              color:
                                                                                  Colors.black),
                                                                        ),
                                                                      );
                                                                    }).toList(),
                                                                    onChanged: (String?
                                                                        newValue) {
                                                                      setState(() {
                                                                        selectedUserEmail =
                                                                            newValue;
                                                                      });
                                                                    },
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                    ],
                                                  )
                                                  : SizedBox(),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: 40,
                                        ),
                                        widget.role == "admin" ||
                                                widget.role == "hr"
                                            ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  TextButton(
                                                      onPressed: () {
                                                        selectedStatus ??=
                                                            defaultStatus;
                                                        selectedUserEmail ??=
                                                            defaultEmail;
                                                        selectedPriority ??= defaultPriority;
                                                        try {
                                                          grievanceDB.updateStatus(
                                                              widget.id!,
                                                              selectedUserEmail!,
                                                              selectedStatus!,
                                                              selectedPriority!);
                                                          print(
                                                              "${widget.id!}, ${selectedUserEmail!}, ${selectedStatus!}");
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(SnackBar(
                                                                  content: Text(
                                                                      "Grievance Updated")));
                                                          Navigator.pop(
                                                              context);
                                                        } catch (e) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(SnackBar(
                                                                  content: Text(
                                                                      "Error: $e")));
                                                        }
                                                      },
                                                      child: Text(
                                                        "Update",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      )),
                                                ],
                                              )
                                            : SizedBox(),
                                      ],
                                    ),
                                  );
                                });
                          }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
