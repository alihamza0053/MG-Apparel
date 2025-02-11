import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/users/userDatabase.dart';

import '../../theme/themeData.dart';

class UserData extends StatefulWidget {
  const UserData({super.key});

  @override
  State<UserData> createState() => _UserDataState();
}

class _UserDataState extends State<UserData> {

  final usersDB = UserDatabase();
  Color roleColor = Colors.green;
  Map<int, String> selectedRoles = {};


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
        title: Text("Users", style: TextStyle(fontSize: 25)),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          Container(
            width: 500,
            child: Column(
              children: [
                SizedBox(height: 50,),
                Row(
                  children: [
                    SizedBox(width: 20,),
                    Text("Users With Role:", style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold)),
                  ],
                ),
                Expanded(
                  child: StreamBuilder(stream: usersDB.stream, builder: (context,snapshot){

                    if(!snapshot.hasData){
                      return Center(child: CircularProgressIndicator(),);
                    }
                    final users = snapshot.data!;
                    return ListView.builder(
                      itemCount: users.length,
                        itemBuilder: (context,index){

                        final singleUser = users[index];

                        if(singleUser.role == 'employee'){
                          roleColor = Colors.green;
                        }
                        if(singleUser.role == 'hr'){
                          roleColor = Colors.orange;
                        }
                        if(singleUser.role == 'admin'){
                          roleColor = Colors.red;
                        }
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                border: Border.all(width: 1, color: AppColors.primaryColor),
                                borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "Email:",
                                          style: TextStyle(
                                              fontSize: 16),
                                        ),
                                        SizedBox(width: 10,),
                                        Text(
                                          singleUser.email,
                                          style: TextStyle(
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                                      color: roleColor,
                                      child: Text(singleUser.role),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    DropdownButton<String>(
                                      dropdownColor: Colors.white,
                                      value: selectedRoles[singleUser.id] ?? singleUser.role,
                                      // Selected value
                                      hint: Text(
                                        singleUser.role,
                                        style: TextStyle(
                                            color: AppColors.primaryColor), // Hint text color
                                      ),
                                      style: TextStyle(color: Colors.white),
                                      // Selected item text color
                                      items: [
                                        'employee',
                                        'hr',
                                        'admin',
                                      ]
                                          .map((String status) => DropdownMenuItem<String>(
                                        value: status,
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                              color: AppColors.primaryColor), // Dropdown items text color
                                        ),
                                      ))
                                          .toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            selectedRoles[singleUser.id!] = newValue; // Update role for this user
                                          });
                                        }
                                      },
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // Get the selected role for this user, fallback to their existing role if not changed
                                        String updatedRole = selectedRoles[singleUser.id] ?? singleUser.role;

                                        try {
                                          usersDB.update(singleUser, updatedRole);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("User Role Updated")),
                                          );

                                          // Remove the user from the map to avoid keeping unnecessary data
                                          setState(() {
                                            selectedRoles.remove(singleUser.id);
                                          });

                                          Navigator.pop(context);
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Error: $e")),
                                          );
                                        }
                                      },
                                      child: Text(
                                        "Update",
                                        style: TextStyle(fontSize: 14,color: Colors.white),
                                      ),
                                    ),


                                  ],
                                )
                              ],
                            ),
                          ),
                        );

                    });
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
