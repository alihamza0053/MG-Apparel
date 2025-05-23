import 'package:flutter/material.dart';

class Grievance {
  int? id;
  String title;
  String description;
  String my_name;
  String my_employee_id;
  String my_depart;
  String my_position;
  String complain_against_name;
  String complain_against_id;
  String complain_against_depart;
  String complain_against_position;
  String other;
  String category;
  String imgUrl;
  String assignTo;
  String status;
  String priority;
  String feedback;
  String updateAt;
  String? submittedBy;

  Grievance({
    this.id,
    required this.title,
    required this.description,
    required this.my_name,
    required this.my_employee_id,
    required this.my_depart,
    required this.my_position,
    required this.complain_against_name,
    required this.complain_against_id,
    required this.complain_against_depart,
    required this.complain_against_position,
    required this.other,
    required this.category,
    required this.imgUrl,
    required this.assignTo,
    required this.status,
    required this.priority,
    required this.feedback,
    required this.updateAt,
    required this.submittedBy,
  });

  factory Grievance.fromMap(Map<String, dynamic> map) {
    return Grievance(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      my_name: map['my_name'] as String,
      my_employee_id: map['my_employee_id'] as String,
      my_depart: map['my_depart'] as String,
      my_position: map['my_position'] as String,
      complain_against_name: map['complain_against_name'] as String,
      complain_against_id: map['complain_against_id'] as String,
      complain_against_depart: map['complain_against_depart'] as String,
      complain_against_position: map['complain_against_position'] as String,
      other: map['other'] as String,
      category: map['category'] as String,
      imgUrl: map['imgUrl'] as String,
      assignTo: map['assignTo'] as String,
      status: map['status'] as String,
      priority: map['priority'] as String,
      feedback: map['feedback'] as String,
      updateAt: map['updateAt'] as String,
      submittedBy: map['submittedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'my_name': my_name,
      'my_employee_id': my_employee_id,
      'my_depart': my_depart,
      'my_position': my_position,
      'complain_against_name': complain_against_name,
      'complain_against_id': complain_against_id,
      'complain_against_depart': complain_against_depart,
      'complain_against_position': complain_against_position,
      'other': other,
      'category': category,
      'imgUrl': imgUrl,
      'assignTo': assignTo,
      'status': status,
      'priority': priority,
      'feedback': feedback,
      'updateAt': updateAt,
      'submittedBy': submittedBy,
    };
  }
}