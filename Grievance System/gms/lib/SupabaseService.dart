import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Fetches grievance counts by status, optionally filtered by month
  Future<Map<String, int>> getGrievanceCounts({int? month}) async {
    try {
      final now = DateTime.now();
      final int year = now.year;

      // Get start and end of the selected month
      final String startOfMonth = DateTime(year, month ?? now.month, 1).toIso8601String();
      final String endOfMonth = DateTime(year, (month ?? now.month) + 1, 1).toIso8601String();

      print("Fetching data from $startOfMonth to $endOfMonth");

      // Fetch grievances with the applied filter
      var response = await supabase
          .from('grievance')
          .select('status, created_at')
          .gte('created_at', startOfMonth)
          .lt('created_at', endOfMonth);

      print("Fetched Data: $response"); // Debugging Output

      // Initialize counts for each status
      Map<String, int> data = {
        "pending": 0,
        "in progress": 0,
        "resolved": 0,
        "closed": 0
      };

      for (var row in response) {
        String status = row['status'];
        if (data.containsKey(status)) {
          data[status] = (data[status] ?? 0) + 1;
        }
      }

      print("Processed Grievance Counts: $data");
      return data;

    } catch (e) {
      print("Error fetching grievance counts: $e");
      return {"Pending": 0, "In Progress": 0, "Resolved": 0, "Closed": 0};
    }
  }
}
