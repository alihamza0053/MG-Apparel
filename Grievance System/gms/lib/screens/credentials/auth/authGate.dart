import 'package:flutter/material.dart';
import 'package:gms/screens/admin/admin.dart';
import 'package:gms/screens/credentials/login.dart';
import 'package:gms/screens/dashboard.dart';
import 'package:gms/screens/employee/employee.dart';
import 'package:gms/screens/hr/hr.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {

  String role = "hr";


  @override
  void initState() {
    super.initState();
    fetchUserRole(); // Fetch user role when dashboard loads
  }

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

      print("🔹 User Role: $role"); // Debug log
    } catch (e) {
      print("❌ Error fetching user role: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(stream: Supabase.instance.client.auth.onAuthStateChange, builder: (context,snapshot){
      if(snapshot.connectionState == ConnectionState.waiting){
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final sesson = snapshot.hasData ? snapshot.data!.session : null;

      if(sesson != null) {

        if(role == 'employee'){
          return Employee();
        }
        if(role == 'hr'){
          return hr();
        }
        if(role == 'admin'){
          return DashboardScreen();

        }
        return Employee();

      }else{
        return Login();
      }
    });
  }
}
