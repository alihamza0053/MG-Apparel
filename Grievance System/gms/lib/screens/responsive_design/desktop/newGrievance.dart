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

class desktopNewGrievance extends StatefulWidget {
  const desktopNewGrievance({super.key});

  @override
  State<desktopNewGrievance> createState() => _desktopNewGrievanceState();
}

class _desktopNewGrievanceState extends State<desktopNewGrievance> {
  AuthService authService = AuthService();
  final grievanceDB = GrievanceDB();
  TextEditingController title = TextEditingController();
  TextEditingController des = TextEditingController();
  TextEditingController my_name = TextEditingController();
  TextEditingController my_id = TextEditingController();
  TextEditingController my_depart = TextEditingController();
  TextEditingController my_position = TextEditingController();
  List<Map<String, TextEditingController>> accusedPersons = [
    {
      'name': TextEditingController(),
      'id': TextEditingController(),
      'depart': TextEditingController(),
      'position': TextEditingController(),
    }
  ];
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

  void addAccusedPerson() {
    setState(() {
      accusedPersons.add({
        'name': TextEditingController(),
        'id': TextEditingController(),
        'depart': TextEditingController(),
        'position': TextEditingController(),
      });
    });
  }

  void removeAccusedPerson(int index) {
    setState(() {
      accusedPersons.removeAt(index);
    });
  }

  void pickAndUploadFile() async {
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*,application/pdf';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        fileObj = file;
        setState(() {
          fileName = file.name;
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
        Uri.parse("https://groundup.pk/gms/upload_image.php"),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
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
        } else {
          print("Upload failed: ${jsonResponse['message']}");
        }
      } else {
        print("Server error: ${response.reasonPhrase}");
      }
    });
  }

  Future<void> newGrievance() async {
    TimeOfDay selectedTime = TimeOfDay(hour: 11, minute: 11);
    DateTime now = DateTime.now();
    DateTime combinedDateTime = DateTime(
        now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);

    String timestamp = combinedDateTime.toIso8601String();

    final newGrievance = Grievance(
      title: title.text,
      description: des.text,
      my_name: my_name.text,
      my_employee_id: my_id.text,
      my_depart: my_depart.text,
      my_position: my_position.text,
      complain_against_name: accusedPersons.map((p) => p['name']!.text).join(';'),
      complain_against_id: accusedPersons.map((p) => p['id']!.text).join(';'),
      complain_against_depart: accusedPersons.map((p) => p['depart']!.text).join(';'),
      complain_against_position: accusedPersons.map((p) => p['position']!.text).join(';'),
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

      sendEmail(
          "alihamza00053@gmail.com",
          "New Grievance Submitted",
          "Hello,\nA new grievance has been submitted. \n\nTitle: ${des.text}\nSubmitted by: ${userEmail!} \nDate: ${timestamp}\nCategory: ${selectedCategory}\n\n Thank you,\nMG Apparel Grievance");

      Toastification().show(
        context: context,
        title: Text("Grievance Submitted"),
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

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Color(0xFFECEFF1),
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
      ),
      body: Center(
        child: Container(
          width: isDesktop ? 800 : double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.grey.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          "Submit New Grievance",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildTextField(title, "Title", Icons.title),
                        SizedBox(height: 12),
                        _buildTextField(des, "Description", Icons.description,
                            maxLines: 5),
                        SizedBox(height: 20),
                        Text(
                          "Personal Info",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        SizedBox(height: 12),
                        if (isDesktop)
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                    my_name, "Name", Icons.person),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                    my_id, "Employee ID", Icons.assignment_ind),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _buildTextField(my_name, "Name", Icons.person),
                              SizedBox(height: 12),
                              _buildTextField(
                                  my_id, "Employee ID", Icons.assignment_ind),
                            ],
                          ),
                        SizedBox(height: 12),
                        if (isDesktop)
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                    my_depart, "Department", Icons.business),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                    my_position, "Position Title", Icons.work),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _buildTextField(
                                  my_depart, "Department", Icons.business),
                              SizedBox(height: 12),
                              _buildTextField(
                                  my_position, "Position Title", Icons.work),
                            ],
                          ),
                        SizedBox(height: 20),
                        Text(
                          "Complain Against",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        SizedBox(height: 12),
                        ...accusedPersons.asMap().entries.map((entry) {
                          int index = entry.key;
                          var controllers = entry.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text(
                                  "Person ${index + 1}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        if (isDesktop)
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildTextField(
                                                    controllers['name']!,
                                                    "Name",
                                                    Icons.person),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: _buildTextField(
                                                    controllers['id']!,
                                                    "Employee ID (optional)",
                                                    Icons.assignment_ind),
                                              ),
                                            ],
                                          )
                                        else
                                          Column(
                                            children: [
                                              _buildTextField(
                                                  controllers['name']!,
                                                  "Name",
                                                  Icons.person),
                                              SizedBox(height: 12),
                                              _buildTextField(
                                                  controllers['id']!,
                                                  "Employee ID (optional)",
                                                  Icons.assignment_ind),
                                            ],
                                          ),
                                        SizedBox(height: 12),
                                        if (isDesktop)
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildTextField(
                                                    controllers['depart']!,
                                                    "Department",
                                                    Icons.business),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: _buildTextField(
                                                    controllers['position']!,
                                                    "Position Title",
                                                    Icons.work),
                                              ),
                                            ],
                                          )
                                        else
                                          Column(
                                            children: [
                                              _buildTextField(
                                                  controllers['depart']!,
                                                  "Department",
                                                  Icons.business),
                                              SizedBox(height: 12),
                                              _buildTextField(
                                                  controllers['position']!,
                                                  "Position Title",
                                                  Icons.work),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (accusedPersons.length > 1)
                                    Padding(
                                      padding: EdgeInsets.only(left: 10, top: 10),
                                      child: IconButton(
                                        onPressed: () => removeAccusedPerson(index),
                                        icon: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          padding: EdgeInsets.all(8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          shadowColor: Colors.grey.withOpacity(0.3),
                                          elevation: 2,
                                        ),
                                        tooltip: "Remove Person",
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 12),
                            ],
                          );
                        }).toList(),
                        ElevatedButton(
                          onPressed: addAccusedPerson,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_add,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Add Another Person",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: InputDecoration(
                            labelText: "Select Category",
                            labelStyle: TextStyle(color: Colors.grey[600]),
                            prefixIcon: Icon(
                              Icons.category,
                              color: Colors.grey[600],
                              size: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                              BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                              BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                              BorderSide(color: AppColors.primaryColor),
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                          items: [
                            'Discrimination',
                            'Pay and Benefits',
                            'Work Conditions',
                            'Workplace Harassment',
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCategory = newValue;
                            });
                          },
                        ),
                        SizedBox(height: 20),
                        Text(
                          "File Attachment: Please attach any relevant evidence or information to support your complaint.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.secondaryColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: GestureDetector(
                            onTap: pickAndUploadFile,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  color: AppColors.secondaryColor,
                                  size: 16,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  fileName == "" ? "Attach File" : fileName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 5),
                              Text(
                                "Submit",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hintText, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[800],
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(
          icon,
          color: Colors.grey[600],
          size: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
      ),
    );
  }
}