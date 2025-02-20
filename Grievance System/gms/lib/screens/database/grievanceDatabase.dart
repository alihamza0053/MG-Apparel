import 'package:flutter/material.dart';
import 'package:gms/screens/credentials/auth/authService.dart';
import 'package:gms/screens/database/grievance.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GrievanceDB {
  //database
  final database = Supabase.instance.client.from('grievance');
  AuthService authService = AuthService();

  //create
  Future createGrievance(Grievance newGrievance) async {
    await database.insert(newGrievance.toMap());
  }

  // Read data from 'grievance' table and sort by ID Descending
  final stream = Supabase.instance.client
      .from('grievance')
      .stream(primaryKey: ['id']).map((data) {
    try {
      print("📡 Received Data from Supabase: $data"); // Debug log

      // Convert to List<Grievance> and sort by ID
      final grievances = data
          .map((grievanceMap) => Grievance.fromMap(grievanceMap))
          .toList()
        ..sort((b, a) => a.id!.compareTo(b.id!)); // Sort by ID (ascending)

      print("✅ Sorted Grievances: $grievances"); // Debug log
      return grievances;
    } catch (e) {
      print("❌ Error processing grievance data: $e");
      return [];
    }
  });

  // Read data from 'grievance' table and sort by ID Ascending
  final detailStream = Supabase.instance.client
      .from('grievance')
      .stream(primaryKey: ['id']).map((data) {
    try {
      print("📡 Received Data from Supabase: $data"); // Debug log

      // Convert to List<Grievance> and sort by ID
      final grievances = data
          .map((grievanceMap) => Grievance.fromMap(grievanceMap))
          .toList()
        ..sort((a, b) => a.id!.compareTo(b.id!)); // Sort by ID (ascending)

      print("✅ Sorted Grievances: $grievances"); // Debug log
      return grievances;
    } catch (e) {
      print("❌ Error processing grievance data: $e");
      return [];
    }
  });


  Stream<List<dynamic>> statusStream (String status){
    // Read data from 'grievance' table where status is 'pending' and sort by ID Ascending
    final statusStream = Supabase.instance.client
        .from('grievance')
        .stream(primaryKey: ['id'])
        .eq('status', status) // Filter grievances with status 'pending'
        .map((data) {
      try {
        print("📡 Received Data from Supabase: $data"); // Debug log

        // Convert to List<Grievance> and sort by ID
        final grievances = data
            .map((grievanceMap) => Grievance.fromMap(grievanceMap))
            .toList()
          ..sort((a, b) => a.id!.compareTo(b.id!)); // Sort by ID (ascending)

        print("✅ Sorted Grievances: $grievances"); // Debug log
        return grievances;
      } catch (e) {
        print("❌ Error processing grievance data: $e");
        return [];
      }
    });
    return statusStream;
  }




  //update whole grievance
  Future update(
      Grievance oldGrievancel,
      String title,
      String description,
      String my_name,
      String my_employee_id,
      String my_depart,
      String complain_against_name,
      String complain_against_id,
      String complain_against_depart,
      String other,
      String category,
      String imgUrl,
      String assignTo,
      String status,
      String updateAt,
      String submittedBy) async {
    await database.update({
      'title': title,
      'description': description,
      'my_name': my_name,
      'my_employee_id': my_employee_id,
      'my_depart': my_depart,
      'complain_against_name': complain_against_name,
      'complain_against_id': complain_against_id,
      'complain_against_depart': complain_against_depart,
      'other': other,
      'category': category,
      'imgUrl': imgUrl,
      'assignTo': assignTo,
      'status': status,
      'updateAt': updateAt,
      'submittedBy': submittedBy,
    }).eq('id', oldGrievancel.id!);
  }

  //update grievance status and assign person
  Future updateStatus(int id, String assignTo, String status, String priority,String feedback) async {

    //formating time
    TimeOfDay selectedTime = TimeOfDay(hour: 11, minute: 11);
    DateTime now = DateTime.now();
    DateTime combinedDateTime = DateTime(
        now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
    String timestamp = combinedDateTime.toIso8601String();

    await database.update({
      'assignTo': assignTo,
      'status': status,
      'priority': priority,
      'feedback':feedback,
      'updateAt': timestamp,
    }).eq('id', id);
  }

  //delete specific grievance
  Future delete(Grievance grievance) async {
    await database.delete().eq('id', grievance.id!);
  }
}
