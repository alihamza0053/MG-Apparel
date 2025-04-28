import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/auth/authService.dart';
import 'package:gms/screens/database/grievance.dart';
import 'package:gms/screens/database/grievanceDatabase.dart';
import 'package:gms/theme/themeData.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

import 'package:toastification/toastification.dart';

import '../../../smtp/mailer.dart';

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
      assignTo: 'not assigned yet',
      status: 'Pending',
      priority: 'Low',
      feedback: 'Pending',
      updateAt: timestamp,
      submittedBy: userEmail,
    );

    try {
      grievanceDB.createGrievance(newGrievance);
      // email, subject, description
      sendEmail("alihamza00053@gmail.com", "New Grievance Submitted", "Hello,\nA new grievance has been submitted. \n\nTitle: ${des.text}\nSubmitted by: ${userEmail!} \nDate: ${timestamp}\nCategory: ${selectedCategory}\n\nThank you,\nMG Apparel Grievance");

      Toastification().show(
        context: context,
        title: Text("Grievance Submitted."),
        type: ToastificationType.success,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: const Duration(seconds: 5),
      );

      Navigator.pop(context);
    } catch (e) {
      Toastification().show(
        context: context,
        title: Text("Error: $e"),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: const Duration(seconds: 5),
      );
    }
  }
  //submit data to end

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1), // Light gray background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(

            Icons.arrow_back,
            color: AppColors.primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          "New Grievance",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.close, color: AppColors.secondaryColor, size: 16),
            label: Text(
              "Close",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey.shade50],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Submit New Grievance",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(title, "Title", Icons.title),
                    const SizedBox(height: 12),
                    _buildTextField(des, "Description", Icons.description, maxLines: 5),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade200, thickness: 1),
                    const SizedBox(height: 20),
                    Text(
                      "Personal Info",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(my_name, "Name", Icons.person),
                    const SizedBox(height: 12),
                    _buildTextField(my_id, "Employee ID", Icons.assignment_ind),
                    const SizedBox(height: 12),
                    _buildTextField(my_depart, "Department", Icons.business),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade200, thickness: 1),
                    const SizedBox(height: 20),
                    Text(
                      "Complain Against",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(complain_against_name, "Name", Icons.person),
                    const SizedBox(height: 12),
                    _buildTextField(complain_against_id, "Employee ID (optional)", Icons.assignment_ind),
                    const SizedBox(height: 12),
                    _buildTextField(complain_against_depart, "Department", Icons.business),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade200, thickness: 1),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        hintText: "Select Category",
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        prefixIcon: Icon(Icons.category, size: 16, color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                      dropdownColor: Colors.white,
                      items: [
                        'Discrimination',
                        'Pay and Benefits',
                        'Work Conditions',
                        'Workplace Harassment',
                        'Others'
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCategory = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: pickAndUploadFile,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        side: BorderSide(color: AppColors.primaryColor, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attach_file, size: 16, color: AppColors.primaryColor),
                          const SizedBox(width: 5),
                          Text(
                            fileName == "" ? "Attach File" : fileName,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FloatingActionButton.extended(
                onPressed: () {
                  try {
                    if (fileName.isEmpty) {
                      newGrievance();
                    } else {
                      uploadFile(fileObj!);
                    }
                  } catch (e) {
                    Toastification().show(
                      context: context,
                      title: Text("Error: $e"),
                      type: ToastificationType.error,
                      style: ToastificationStyle.flatColored,
                      autoCloseDuration: const Duration(seconds: 5),
                    );
                  }
                },
                backgroundColor: AppColors.primaryColor,
                icon: const Icon(Icons.send, color: Colors.white, size: 16),
                label: const Text(
                  "Submit Grievance",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
        hintStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
        prefixIcon: Icon(icon, size: 16, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      ),
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[800],
      ),
    );
  }
}