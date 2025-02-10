import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/auth/authService.dart';
import 'package:gms/screens/database/grievance.dart';
import 'package:gms/screens/database/grievanceDatabase.dart';
import 'package:gms/theme/themeData.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewGrievanceScreen extends StatefulWidget {
  const NewGrievanceScreen({super.key});

  @override
  State<NewGrievanceScreen> createState() => _NewGrievanceScreenState();
}

class _NewGrievanceScreenState extends State<NewGrievanceScreen> {
  AuthService authService = AuthService();
  final grievanceDB = GrievanceDB();
  TextEditingController title = TextEditingController();
  TextEditingController des = TextEditingController();
  TextEditingController other = TextEditingController();
  String imgUrl = "";
  String? selectedCategory;
  SupabaseClient supabaseClient = Supabase.instance.client;
  String? userEmail = "";

  @override
  void initState() {
   userEmail =  supabaseClient.auth.currentUser?.email;
    super.initState();
  }


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
        title: Text("New Grievance"),
      ),
      body: Center(
        child: Container(
          width: 800,
          height: 500,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
              border: Border.all(width: 1, color: AppColors.primaryColor),
              borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: [
              SizedBox(
                height: 20,
              ),
              TextField(
                controller: title,
                decoration: InputDecoration(hintText: "Title"),
              ),
              SizedBox(
                height: 20,
              ),
              TextField(
                controller: des,
                maxLines: 5,
                decoration: InputDecoration(hintText: "Description"),
              ),
              SizedBox(
                height: 20,
              ),
              TextField(
                controller: other,
                decoration: InputDecoration(
                  hintText: "Other",
                ),
              ),
              SizedBox(
                height: 20,
              ),
              DropdownButton<String>(
                dropdownColor: AppColors.primaryColor,
                value: selectedCategory,
                // Selected value
                hint: Text(
                  "Select Category",
                  style: TextStyle(
                      color: AppColors.secondaryColor), // Hint text color
                ),
                style: TextStyle(color: Colors.white),
                // Selected item text color
                items: [
                  'Discrimination',
                  'Pay and Benefits',
                  'Work Conditions',
                  'Workplace Harassment',
                  'Others'
                ]
                    .map((String status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(
                            status,
                            style: TextStyle(
                                color: Colors.white), // Dropdown items text color
                          ),
                        ))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue; // Update selected value
                  });
                },
              ),
              SizedBox(
                height: 20,
              ),
              TextButton(
                  onPressed: () {
                    TimeOfDay selectedTime = TimeOfDay(hour: 11, minute: 11);
                    DateTime now = DateTime.now();
                    DateTime combinedDateTime = DateTime(now.year, now.month,
                        now.day, selectedTime.hour, selectedTime.minute);

                    // Send this `combinedDateTime.toIso8601String()` to Supabase
                    String timestamp = combinedDateTime.toIso8601String();

                    final newGrievance = Grievance(
                      title: title.text,
                      description: des.text,
                      other: other.text,
                      category: selectedCategory!,
                      imgUrl: imgUrl,
                      assignTo: '',
                      status: 'pending',
                      updateAt: timestamp,
                      submittedBy: userEmail,
                    );
                    try {
                      grievanceDB.createGrievance(newGrievance);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Grievance Submitted")));
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                  child: Text("Submit",style: TextStyle(color: Colors.white),))
            ],
          ),
        ),
      ),
    );
  }
}
