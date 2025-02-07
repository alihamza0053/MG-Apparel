import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  //login
  Future<AuthResponse> login(String email, String password) async {
    return await supabase.auth
        .signInWithPassword(email: email, password: password);
  }

  //signup
  Future<AuthResponse> signUp(String email, String password) async {
    return await supabase.auth.signUp(email: email, password: password);
  }

  //sign out
  Future<void> signOut() async {
    return await supabase.auth.signOut();
  }

  //get email
  String? getUserEmail() {
    final session = supabase.auth.currentSession;
    final user = session?.user;
    return user!.email;
  }
}
