import 'package:flutter/material.dart';

class Users {
  int? id;
  String email;
  String role;

  Users(
      {this.id,
        required this.email,
        required this.role,

      });

  //convert to grievance

  factory Users.fromMap(Map<String, dynamic> map) {
    return Users(
      id: map['id'] as int,
      email: map['email'] as String,
      role: map['role'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,

    };
  }
}
