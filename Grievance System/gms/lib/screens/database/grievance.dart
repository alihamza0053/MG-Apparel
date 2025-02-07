import 'package:flutter/material.dart';

class Grievance {
  int? id;
  String title;
  String description;
  String other;
  String category;
  String imgUrl;
  String assignTo;
  String status;
  String updateAt;
  String? submittedBy;

  Grievance(
      {this.id,
      required this.title,
      required this.description,
      required this.other,
      required this.category,
      required this.imgUrl,
      required this.assignTo,
      required this.status,
      required this.updateAt,
      required this.submittedBy,
      });

  //convert to grievance

  factory Grievance.fromMap(Map<String, dynamic> map) {
    return Grievance(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      other: map['other'] as String,
      category: map['category'] as String,
      imgUrl: map['imgUrl'] as String,
      assignTo: map['assignTo'] as String,
      status: map['status'] as String,
      updateAt: map['updateAt'] as String,
      submittedBy: map['submittedBy'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'other': other,
      'category': category,
      'imgUrl': imgUrl,
      'assignTo':assignTo,
      'status':status,
      'updateAt':updateAt,
      'submittedBy':submittedBy,
    };
  }
}
