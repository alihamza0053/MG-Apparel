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
import 'package:gms/smtp/mailer.dart';
import 'package:gms/theme/themeData.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:toastification/toastification.dart';
import 'dart:html' as html;

import '../../../login session/device_info.dart';
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

      if (role == 'employee') {
        screen = desktopEmployeeDashboard();
      }
      if (role == 'hr') {
        screen = desktopHrDashboard();
      }
      if (role == 'admin') {
        screen = desktopAdminDashboard();
      }

      if (role == "ceo") {
        screen = desktopCeoDashboard();
      }

      sendEmail("${email.text}", "New login for GMS", "Hello,\n\nNew login has been tracked on ${ip} ip address. \nIf it's not you immediately contact admin.\n\nThank you,\nMG Apparel Grievance");
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => rDashboard(role: role, email: email.text)));
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
          autoCloseDuration: const Duration(seconds: 5),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECEFF1),
      body: Center(
        child: progressBar
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 80,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Logging In",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Please wait...",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              )
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: 400,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.grey.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image(
                          image: AssetImage("assets/images/logo.png"),
                          width: 100,
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                          decoration: InputDecoration(
                            hintText: "Email",
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            prefixIcon: Icon(
                              Icons.email,
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
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: password,
                          obscureText: true,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                          decoration: InputDecoration(
                            hintText: "Password",
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            prefixIcon: Icon(
                              Icons.lock,
                              color: Colors.grey[600],
                              size: 16,
                            ),
                            counterText: "",
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
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              onPressed: login,
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
                                    Icons.login,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    "Login",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => rSignup(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.secondaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.secondaryColor,
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
      ),
    );
  }
}
