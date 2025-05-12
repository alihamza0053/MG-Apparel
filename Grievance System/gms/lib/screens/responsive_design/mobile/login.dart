import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/auth/authService.dart';
import 'package:gms/screens/credentials/signUp.dart';
import 'package:gms/screens/employee/employee.dart';
import 'package:gms/screens/responsive_design/mobile/admin/adminDashboard.dart';
import 'package:gms/screens/responsive_design/mobile/ceo/ceoDashboard.dart';
import 'package:gms/screens/responsive_design/mobile/employee/employeeDashboard.dart';
import 'package:gms/screens/responsive_design/mobile/hr/hrDashboard.dart';
import 'package:gms/screens/responsive_design/mobile/signup.dart';
import 'package:gms/screens/responsive_design/responsive/rDashboard.dart';
import 'package:gms/screens/responsive_design/responsive/rSignup.dart';
import 'package:gms/theme/themeData.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:html' as html;

import 'package:toastification/toastification.dart';

import '../../../login session/device_info.dart';
import '../../../smtp/mailer.dart';

class mobileLogin extends StatefulWidget {
  const mobileLogin({super.key});

  @override
  State<mobileLogin> createState() => _mobileLoginState();
}

class _mobileLoginState extends State<mobileLogin> {
  AuthService authService = AuthService();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  String role = "";
  bool progressBar = false;
  String ip = "";

  @override
  void initState() {
    super.initState();
    fetchUserRole(); // Fetch user role when dashboard loads
    sendLoginEmail();
  }

  Future<void> sendLoginEmail() async {
    final info = await getLoginInfo();
    print("""📍 IP Address: ${info['ip']}
🌐 Browser: ${info['browser']}
📌 Location: ${info['location']}""");
    ip = info['ip']!;
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
        Uri.parse(
            "https://groundup.pk/gms/upload_image.php"), // Change to your PHP API
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
      sendEmail("${email.text}", "New login for GMS", "Hello,\n\nNew login has been tracked on ${ip} ip address. \nIf it's not you immediately contact admin.\n\nThank you,\nMG Apparel Grievance");
      Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (context) => rDashboard(role: role, email: email.text)));


      print("🔹 User Role: $role"); // Debug log
    } catch (e) {
      print("❌ Error fetching user role: $e");
    }
  }

  void login() async {
    if (email.text.isEmpty || password.text.isEmpty) {
      Toastification().show(
        context: context,
        title: Text("Fill all the fields."),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: const Duration(seconds: 5),
      );
    } else {
      setState(() {
        progressBar = true;
      });

      try {
        await authService.login(email.text.toLowerCase().trim(),
            password.text.toLowerCase().trim());
        fetchUserRole(); // Fetch user role when dashboard loads
      } on AuthException catch (e) {
        setState(() {
          progressBar = false;
        });
        Toastification().show(
            context: context,
            title: Text("Error ${e.message}"),
            type: ToastificationType.error,
            style: ToastificationStyle.flatColored,
            autoCloseDuration: const Duration(seconds: 5)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1), // Light gray background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Image.asset(
            "assets/images/logo.png",
            width: 40,
          ),
        ),
        title: Text(
          "Login",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const rSignup()));
            },
            icon: Icon(
                Icons.person_add, color: AppColors.secondaryColor, size: 16),
            label: Text(
              "SignUp",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: progressBar
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryColor),
            const SizedBox(height: 10),
            Text(
              "Logging in....",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        )
            : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
          child: Container(
            width: 400,
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
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/logo.png",
                  width: 100,
                ),
                const SizedBox(height: 10),
                Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Email",
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: Colors.grey.shade300, width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 12),
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Password",
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: Colors.grey.shade300, width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 12),
                    counterText: "",
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text("Login"),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (
                                context) => const rSignup()));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                              width: 1, color: AppColors.primaryColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "SignUp",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}