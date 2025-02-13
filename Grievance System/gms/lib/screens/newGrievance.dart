import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/auth/authService.dart';
import 'package:gms/screens/database/grievance.dart';
import 'package:gms/screens/database/grievanceDatabase.dart';
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
   userEmail =  supabaseClient.auth.currentUser?.email;
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
  Future<void> newGrievance() async{
    TimeOfDay selectedTime = TimeOfDay(hour: 11, minute: 11);
    DateTime now = DateTime.now();
    DateTime combinedDateTime = DateTime(now.year, now.month,
        now.day, selectedTime.hour, selectedTime.minute);

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
      status: 'pending',
      updateAt: timestamp,
      submittedBy: userEmail,
    );

    try{
      grievanceDB.createGrievance(newGrievance);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Grievance Submitted")));
      Navigator.pop(context);
    }catch(e){
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
        title: Text("New Grievance",),
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
                SizedBox(
                  height: 20,
                ),
                Center(child: Text("Submit New Grievance",style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold))),
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
                Row(
                  children: [
                    Text("Personal Info:",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                  ],
                ),
                TextField(
                  controller: my_name,
                  decoration: InputDecoration(hintText: "Name"),
                ),
                SizedBox(width: 50,),
                TextField(
                  controller: my_id,
                  decoration: InputDecoration(hintText: "Employee ID"),
                ),

                SizedBox(
                  height: 20,
                ),
                TextField(
                  controller: my_depart,
                  decoration: InputDecoration(hintText: "Department"),
                ),
                SizedBox(
                  height: 30,
                ),
                Row(
                  children: [
                    Text("Complain Against:",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                  ],
                ),
                TextField(
                  controller: complain_against_name,
                  decoration: InputDecoration(hintText: "Name"),
                ),
                SizedBox(width: 50,),
                TextField(
                  controller: complain_against_id,
                  decoration: InputDecoration(hintText: "Employee ID (optional)"),
                ),

                SizedBox(
                  height: 20,
                ),
                TextField(
                  controller: complain_against_depart,
                  decoration: InputDecoration(hintText: "Department"),
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
                  style: TextStyle(color: Colors.black),
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
                                  color: Colors.black), // Dropdown items text color
                            ),
                          ))
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCategory = newValue; // Update selected value
                    });
                  },
                ),


                TextButton(
                  onPressed: pickAndUploadFile,
                  child: Text(fileName == "" ? "Attach File": fileName,style: TextStyle(color: Colors.white),),),

                SizedBox(
                  height: 20,
                ),
                TextButton(
                    onPressed: () {
                      try {
                        uploadFile(fileObj!);
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
      ),
    );
  }
}
