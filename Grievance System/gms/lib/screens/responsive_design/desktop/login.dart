import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/auth/authService.dart';
import 'package:gms/screens/credentials/signUp.dart';
import 'package:gms/screens/responsive_design/desktop/admin/adminDashboard.dart';
import 'package:gms/screens/responsive_design/desktop/ceo/ceoDashboard.dart';
import 'package:gms/screens/responsive_design/desktop/employee/employeeDashboard.dart';
import 'package:gms/screens/responsive_design/desktop/hr/hrDashboard.dart';
import 'package:gms/screens/responsive_design/desktop/signup.dart';
import 'package:gms/screens/responsive_design/responsive/rSignup.dart';
import 'package:gms/theme/themeData.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:html' as html;

import '../responsive/rDashboard.dart';


class desktopLogin extends StatefulWidget {
  const desktopLogin({super.key});

  @override
  State<desktopLogin> createState() => _desktopLoginState();
}

class _desktopLoginState extends State<desktopLogin> {
  AuthService authService = AuthService();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  String role = "";
  Widget screen = desktopEmployeeDashboard();
  bool progressBar = false;



  @override
  void initState() {
    super.initState();
    fetchUserRole(); // Fetch user role when dashboard loads
  }



  //upload file
  void pickAndUploadFile() async {
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*,application/pdf'; // Allow images & PDFs
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        uploadFile(file);
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
          print("File uploaded successfully: ${jsonResponse['file_path']}");
        } else {
          print("Upload failed: ${jsonResponse['message']}");
        }
      } else {
        print("Server error: ${response.reasonPhrase}");
      }
    });
  }
  // upload file



  // Function to fetch user role from Supabase
  Future<void> fetchUserRole() async {
    try {
      SupabaseClient supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser; // Get logged-in user
      if (user == null) return;

      final response = await supabase
          .from('users') // Your users table
          .select('role') // Fetch only the role column
          .eq('email', user.email as Object) // Filter by user's email
          .maybeSingle(); // Get single result

      if (response != null && response['role'] != null) {
        setState(() {
          role = response['role']; // Set user role
        });
      }

      if(role == 'employee'){
        screen =  desktopEmployeeDashboard();
      }
      if(role == 'hr'){
        screen = desktopHrDashboard();
      }
      if(role == 'admin'){
        screen = desktopAdminDashboard();
      }

      if(role == "ceo"){
        screen = desktopCeoDashboard();
      }



      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>rDashboard(role: role, email: email.text)));



      print("🔹 User Role: $role"); // Debug log
    } catch (e) {
      print("❌ Error fetching user role: $e");
    }
  }

  void login() async{

    if(email.text.isEmpty || password.text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fill all the fields."),backgroundColor: Colors.red,));
    }else{
      setState(() {
        progressBar = true;
      });

      try{
        await authService.login(email.text.toLowerCase().trim(), password.text.toLowerCase().trim());
        fetchUserRole(); // Fetch user role when dashboard loads
      }on AuthException catch(e){
        setState(() {
          progressBar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error ${e.message}"),backgroundColor: Colors.red,));
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: progressBar ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            Text("Logging in....", style: TextStyle(fontSize: 18),)
          ],
        ) : Padding(
          padding: const EdgeInsets.all(18.0),
          child: Container(
            width:400,
            height: 400,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
                border:Border.all(width: 2, color: AppColors.primaryColor),
                borderRadius: BorderRadius.circular(10)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image(image: AssetImage("assets/images/logo.png"),width: 100,),
                SizedBox(
                  height: 10,
                ),
                Text("Login", style: TextStyle(fontSize: 30,fontWeight: FontWeight.w800),),
                SizedBox(
                  height: 20,
                ),
                //Text("Welcome Back", style: TextStyle(fontSize: 25),),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(hintText: "Email"),
                ),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Password",
                    counterText: "", // ✅ Hides the default character counter
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(onPressed: login, child: Text("Login",style: TextStyle(color: Colors.white),)),
                    GestureDetector(
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>rSignup()));
                      },
                      child: Container(
                        padding: EdgeInsets.fromLTRB(18, 10, 18, 10),
                        decoration: BoxDecoration(
                          border: Border.all(width: 1, color: AppColors.primaryColor),
                        ),
                        child: Text(
                          "SignUp",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
