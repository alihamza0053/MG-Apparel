import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/auth/authService.dart';
import 'package:gms/screens/database/grievance.dart';
import 'package:gms/screens/database/grievanceDatabase.dart';
import 'package:gms/smtp/mailer.dart';
import 'package:gms/theme/themeData.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

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
      assignTo: '',
      status: 'Pending',
      priority: 'Low',
      feedback: 'Pending',
      updateAt: timestamp,
      submittedBy: userEmail,
    );

    try {
      grievanceDB.createGrievance(newGrievance);
      sendEmail(
          userEmail!,
          "New Grievance Submitted",
          "Submitted by: ${userEmail!} \nTitle: ${des.text} \nDescription: ${des.text}");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Grievance Submitted")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text("New Grievance"),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 100, 0, 100),
          child: Container(
            width: 800,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
                border: Border.all(width: 1, color: AppColors.primaryColor),
                borderRadius: BorderRadius.circular(10)),
            child: ListView(
              children: [
                SizedBox(height: 20),
                Center(
                    child: Text(
                      "Submit New Grievance",
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    )),
                SizedBox(height: 20),
                TextField(
                  controller: title,
                  decoration: InputDecoration(hintText: "Title"),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: des,
                  maxLines: 5,
                  decoration: InputDecoration(hintText: "Description"),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      "Personal Info:",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ],
                ),
                TextField(
                  controller: my_name,
                  decoration: InputDecoration(hintText: "Name"),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: my_id,
                  decoration: InputDecoration(hintText: "Employee ID"),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: my_depart,
                  decoration: InputDecoration(hintText: "Department"),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: my_position,
                  decoration: InputDecoration(hintText: "Position Title"),
                ),
                SizedBox(height: 30),
                Row(
                  children: [
                    Text(
                      "Complain Against:",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ],
                ),
                ...accusedPersons.asMap().entries.map((entry) {
                  int index = entry.key;
                  var controllers = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Person ${index + 1}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: controllers['name']!,
                        decoration: InputDecoration(hintText: "Name"),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: controllers['id']!,
                        decoration:
                        InputDecoration(hintText: "Employee ID (optional)"),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: controllers['depart']!,
                        decoration: InputDecoration(hintText: "Department"),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: controllers['position']!,
                        decoration: InputDecoration(hintText: "Position Title"),
                      ),
                      if (accusedPersons.length > 1) ...[
                        SizedBox(height: 12),
                        TextButton(
                          onPressed: () => removeAccusedPerson(index),
                          child: Text(
                            "Remove Person",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                      SizedBox(height: 20),
                    ],
                  );
                }).toList(),
                TextButton(
                  onPressed: addAccusedPerson,
                  child: Text(
                    "Add Another Person",
                    style: TextStyle(color: AppColors.primaryColor),
                  ),
                ),
                SizedBox(height: 20),
                DropdownButton<String>(
                  dropdownColor: AppColors.primaryColor,
                  value: selectedCategory,
                  hint: Text(
                    "Select Category",
                    style: TextStyle(color: AppColors.secondaryColor),
                  ),
                  style: TextStyle(color: Colors.black),
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
                      style: TextStyle(color: Colors.black),
                    ),
                  ))
                      .toList(),
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
                TextButton(
                  onPressed: pickAndUploadFile,
                  child: Text(
                    fileName == "" ? "Attach File" : fileName,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    try {
                      if (fileName.isEmpty) {
                        newGrievance();
                      } else {
                        uploadFile(fileObj!);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e")));
                    }
                  },
                  child: Text(
                    "Submit",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}