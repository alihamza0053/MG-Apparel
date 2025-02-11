import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, int>> getGrievanceCounts({DateTime? selectedDate, String? category, String? department}) async {
    try {
      var query = _supabase
          .from('grievances')
          .select('status, count:status');
      // ✅ Filter by Month (Using DateTime)
      if (selectedDate != null) {
        String timestamp = selectedDate.toIso8601String(); // Convert DateTime to Supabase format
        query = query.gte('created_at', timestamp); // Filter grievances on or after this date
      }

      // ✅ Filter by Category
      if (category != null) {
        query = query.eq('category', category);
      }

      // ✅ Filter by Department
      if (department != null) {
        query = query.eq('department', department);
      }

      // ✅ Execute Query
      final List<dynamic> response = await query;

      // ✅ Initialize Map for Storing Count Data
      Map<String, int> grievanceCounts = {
        "Pending": 0,
        "In Progress": 0,
        "Resolved": 0,
        "Closed": 0,
      };

      for (var item in response) {
        String status = item['status'] ?? "Unknown"; // Ensure status is a String
        int count = int.tryParse(item['count'].toString()) ?? 0; // Convert count to int

        if (grievanceCounts.containsKey(status)) {
          grievanceCounts[status] = count;
        }
      }

      return grievanceCounts;
    } catch (e) {
      print("❌ Error fetching grievance data: $e");
      return {"Pending": 0, "In Progress": 0, "Resolved": 0, "Closed": 0};
    }
  }




}

