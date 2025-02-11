import 'dart:io';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';

class GrievanceChart extends StatefulWidget {
  @override
  _GrievanceChartState createState() => _GrievanceChartState();
}

class _GrievanceChartState extends State<GrievanceChart> {
  final SupabaseClient supabase = Supabase.instance.client;

  // ✅ Filters
  DateTime? selectedDate;
  String? selectedCategory;
  String? selectedDepartment;

  List<String> dates = [];
  List<String> categories = [];
  List<String> departments = [];

  Map<String, int> grievanceCounts = {
    "Pending": 0,
    "In Progress": 0,
    "Resolved": 0,
    "Closed": 0,
  };

  @override
  void initState() {
    super.initState();
    fetchDropdownValues();
    fetchGrievanceData();
  }

  /// Fetch unique categories & departments manually
  Future<void> fetchDropdownValues() async {
    try {
      // ✅ Fetch all date
      final List<dynamic> createdAt =
          await supabase.from('grievance').select('created_at');

      // ✅ Fetch all categories
      final List<dynamic> categoryResponse =
          await supabase.from('grievance').select('category');

      // ✅ Fetch all departments
      final List<dynamic> departmentResponse =
          await supabase.from('grievance').select('my_depart');

      // ✅ Convert to Set to remove duplicates
      final List<String> fetchedCategories = categoryResponse
          .map((e) => e['category'].toString())
          .toSet()
          .toList(); // Convert Set back to List

      // ✅ Convert to Set to remove duplicates
      final List<String> fetchDate = createdAt
          .map((e) {
            DateTime date = DateTime.parse(e['created_at']).toLocal();
            return DateFormat('yyyy-MM')
                .format(date); // Formats to "2025-02-10"
          })
          .toSet() // Remove duplicates
          .toList(); // Convert Set back to List


      final List<String> fetchedDepartments = departmentResponse
          .map((e) => e['my_depart'].toString())
          .toSet()
          .toList(); // Convert Set back to List

      setState(() {
        dates = fetchDate;
        categories = fetchedCategories;
        departments = fetchedDepartments;
        print(dates);
      });

      print("✅ Categories: $categories");
      print("✅ Departments: $departments");
    } catch (e) {
      print("❌ Error fetching dropdown values: $e");
    }
  }

  Future<void> fetchGrievanceData() async {
    try {
      // Fetch all grievances
      final response = await supabase
          .from('grievance')
          .select('status, created_at, category, my_depart');

      print("🔥 Full Response: $response");

      // If no date is selected, use the latest available month
      if (selectedDate == null && dates.isNotEmpty) {
        selectedDate = DateFormat('yyyy-MM').parse('${dates.last}-01');
      }

      // Format selected date
      String selectedMonth = selectedDate != null
          ? DateFormat('yyyy-MM').format(selectedDate!)
          : '';

      // Filter data if filters are selected
      final filteredData = response.where((e) {
        DateTime date = DateTime.parse(e['created_at']).toLocal();
        String formattedDate = DateFormat('yyyy-MM').format(date);

        bool dateMatches =
            selectedDate == null || formattedDate == selectedMonth;
        bool categoryMatches =
            selectedCategory == null || e['category'] == selectedCategory;
        bool departmentMatches =
            selectedDepartment == null || e['my_depart'] == selectedDepartment;

        return dateMatches && categoryMatches && departmentMatches;
      }).toList();

      print("🔥 Filtered Response: $filteredData");

      // Initialize status counts
      Map<String, int> newCounts = {
        "Pending": 0,
        "In Progress": 0,
        "Resolved": 0,
        "Closed": 0,
      };

      // Count the filtered statuses
      for (var item in filteredData) {
        String status = item['status'] ?? "Unknown";
        if (newCounts.containsKey(status)) {
          newCounts[status] = (newCounts[status] ?? 0) + 1;
        }
      }

      // Update UI state
      setState(() {
        grievanceCounts = newCounts;
      });
    } catch (e) {
      print("❌ Error fetching grievance data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        //button to download report
        TextButton(onPressed: (){
          print("grievanceCounts");
          print(grievanceCounts);
          generateAndDownloadReport(grievanceCounts);
        }, child: Text("Download Report")),
        // ✅ Month Filter
        DropdownButton<DateTime>(
          hint: Text("All Months"),
          value: selectedDate,
          items: List.generate(12, (index) {
            DateTime date = DateTime(DateTime.now().year, index + 1, 1);
            return DropdownMenuItem(
              value: date,
              child:
                  Text("${date.year}-${date.month.toString().padLeft(2, '0')}"),
            );
          }),
          onChanged: (DateTime? newDate) {
            setState(() {
              selectedDate = newDate;
              fetchGrievanceData();
            });
          },
        ),

        // ✅ Category Filter (Fetched from Supabase)
        DropdownButton<String>(
          hint: Text("All Categories"),
          value: selectedCategory,
          items: categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (String? newCategory) {
            setState(() {
              selectedCategory = newCategory;
              fetchGrievanceData();
            });
          },
        ),

        // ✅ Department Filter (Fetched from Supabase)
        DropdownButton<String>(
          hint: Text("All Departments"),
          value: selectedDepartment,
          items: departments.map((dept) {
            return DropdownMenuItem(
              value: dept,
              child: Text(dept),
            );
          }).toList(),
          onChanged: (String? newDept) {
            setState(() {
              selectedDepartment = newDept;
              fetchGrievanceData();
            });
          },
        ),

        // ✅ Bar Chart
        Expanded(
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: false), // Hide grid lines
              borderData: FlBorderData(
                show: true,
                border: Border.symmetric(
                  horizontal: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                // Removed right indexing
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      int index = value.toInt();
                      if (index >= 0 && index < grievanceCounts.length) {
                        return Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            grievanceCounts.keys.elementAt(index),
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                ),
              ),
              barGroups: grievanceCounts.entries.map((entry) {
                return BarChartGroupData(
                  x: grievanceCounts.keys.toList().indexOf(entry.key),
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.toDouble(), // Ensuring whole numbers
                      color: _getColor(entry.key),
                      width: 30, // Adjusted bar width
                      borderRadius: BorderRadius.circular(6), // Rounded edges
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }


  Future<void> generateAndDownloadReport(Map<String, int> grievanceCounts) async {
    final pdf = pw.Document();

    // Creating PDF Content
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Grievance Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ["Status", "Count"],
                data: grievanceCounts.entries
                    .map((entry) => [entry.key, entry.value.toString()])
                    .toList(),
              ),
            ],
          );
        },
      ),
    );

    // Save PDF and trigger download
    final Uint8List pdfBytes = await pdf.save();
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "Grievance_Report.pdf")
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  Color _getColor(String status) {
    switch (status) {
      case "Pending":
        return Colors.red;
      case "In Progress":
        return Colors.orange;
      case "Resolved":
        return Colors.green;
      case "Closed":
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }
}
