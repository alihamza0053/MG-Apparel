import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/auth/authService.dart';
import 'package:gms/screens/database/grievance.dart';
import 'package:gms/screens/database/grievanceDatabase.dart';
import 'package:gms/theme/themeData.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

class mobileNewGrievance extends StatefulWidget {
  const mobileNewGrievance({super.key});

  @override
  State<mobileNewGrievance> createState() => _mobileNewGrievanceState();
}

class _mobileNewGrievanceState extends State<mobileNewGrievance> {
  AuthService authService = AuthService();
  final grievanceDB = GrievanceDB();
  TextEditingController title = TextEditingController();
  TextEditingController des = TextEditingController();
  TextEditingController my_name = TextEditingController();
  TextEditingController my_id = TextEditingController();
  TextEditingController my_depart = TextEditingController();
  TextEditingController complain_against_name = TextEditingController();
  TextEditingController complain_against_id = TextEditingController();
  TextEditingController complain_against_depart = TextEditingController();
  TextEditingController other = TextEditingController();
  String imgUrl = "";
  String? selectedCategory;
  SupabaseClient supabaseClient = Supabase.instance.client;
  String? userEmail = "";
  String fileName = "";
  html.File? fileObj;
  String filePath = "";

  @override
  void initState() {
    userEmail = supabaseClient.auth.currentUser?.email;
    super.initState();
  }

  //upload file start
  void pickAndUploadFile() async {
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*,application/pdf'; // Allow images & PDFs
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        fileObj = file;
        setState(() {
          fileName = file.name;
          print(file.name);
        });
      }
    });
  }

  Future<void> uploadFile(html.File file) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);

    reader.onLoadEnd.listen((event) async {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("https://groundup.pk/gms/upload_image.php"), // Change to your PHP API
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file', // Must match the PHP $_FILES['file'] key
          reader.result as List<int>,
          filename: file.name,
        ),
      );

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseData);
        if (jsonResponse['success']) {
          imgUrl = "https://groundup.pk/gms/${jsonResponse['file_path']}";
          newGrievance();
          print("File uploaded successfully: ${jsonResponse['file_path']}");
        } else {
          print("Upload failed: ${jsonResponse['message']}");
        }
      } else {
        print("Server error: ${response.reasonPhrase}");
      }
    });
  }
  // upload file end

  //submit data to supabase start
  Future<void> newGrievance() async {
    TimeOfDay selectedTime = TimeOfDay(hour: 11, minute: 11);
    DateTime now = DateTime.now();
    DateTime combinedDateTime = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);

    // Send this `combinedDateTime.toIso8601String()` to Supabase
    String timestamp = combinedDateTime.toIso8601String();

    final newGrievance = Grievance(
      title: title.text,
      description: des.text,
      my_name: my_name.text,
      my_employee_id: my_id.text,
      my_depart: my_depart.text,
      complain_against_name: complain_against_name.text,
      complain_against_id: complain_against_id.text,
      complain_against_depart: complain_against_depart.text,
      other: "",
      category: selectedCategory!,
      imgUrl: imgUrl,
      assignTo: '',
      status: 'Pending',
      priority: 'Low',
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
  }

  //submit data to end

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        "Submit New Grievance",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildTextField(title, "Title", Icons.title),
                      SizedBox(height: 20),
                      _buildTextField(des, "Description", Icons.description, maxLines: 5),
                      SizedBox(height: 20),
                      Text(
                        "Personal Info:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildTextField(my_name, "Name", Icons.person),
                      SizedBox(height: 10),
                      _buildTextField(my_id, "Employee ID", Icons.assignment_ind),
                      SizedBox(height: 10),
                      _buildTextField(my_depart, "Department", Icons.business),
                      SizedBox(height: 20),
                      Text(
                        "Complain Against:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildTextField(complain_against_name, "Name", Icons.person),
                      SizedBox(height: 10),
                      _buildTextField(complain_against_id, "Employee ID (optional)", Icons.assignment_ind),
                      SizedBox(height: 10),
                      _buildTextField(complain_against_depart, "Department", Icons.business),
                      SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: "Select Category",
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: [
                          'Discrimination',
                          'Pay and Benefits',
                          'Work Conditions',
                          'Workplace Harassment',
                          'Others'
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedCategory = newValue;
                          });
                        },
                      ),
                      SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: pickAndUploadFile,
                        child: Text(fileName == "" ? "Attach File" : fileName),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              FloatingActionButton.extended(
                onPressed: () {
                  try {
                    uploadFile(fileObj!);
                  } catch (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
                icon: Icon(Icons.send),
                label: Text("Submit"),
                backgroundColor: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}