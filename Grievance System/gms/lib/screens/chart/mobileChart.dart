import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gms/theme/themeData.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;

class mobileGrievanceChart extends StatefulWidget {
  @override
  _mobileGrievanceChartState createState() => _mobileGrievanceChartState();
}

class _mobileGrievanceChartState extends State<mobileGrievanceChart> {
  final SupabaseClient supabase = Supabase.instance.client;

  // Filters
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
      // Fetch all dates
      final List<dynamic> createdAt =
      await supabase.from('grievance').select('created_at');

      // Fetch all categories
      final List<dynamic> categoryResponse =
      await supabase.from('grievance').select('category');

      // Fetch all departments
      final List<dynamic> departmentResponse =
      await supabase.from('grievance').select('my_depart');

      // Convert to Set to remove duplicates
      final List<String> fetchedCategories = categoryResponse
          .map((e) => e['category'].toString())
          .toSet()
          .toList();

      // Convert to Set to remove duplicates
      final List<String> fetchDate = createdAt
          .map((e) {
        DateTime date = DateTime.parse(e['created_at']).toLocal();
        return DateFormat('yyyy-MM').format(date);
      })
          .toSet()
          .toList();

      final List<String> fetchedDepartments = departmentResponse
          .map((e) => e['my_depart'].toString())
          .toSet()
          .toList();

      setState(() {
        dates = fetchDate;
        categories = fetchedCategories;
        departments = fetchedDepartments;
      });
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Grievance Chart"),
        leading: SizedBox(),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Download Report Button
            ElevatedButton.icon(
              onPressed: () {
                generateAndDownloadReport(grievanceCounts);
              },
              icon: Icon(Icons.download,color: Colors.white,),
              label: Text("Download Report",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            SizedBox(height: 20),

            // Filters Section
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Month Filter
                    _buildDropdown(
                      hint: "All Months",
                      value: selectedDate,
                      items: List.generate(12, (index) {
                        DateTime date = DateTime(DateTime.now().year, index + 1, 1);
                        return DropdownMenuItem(
                          value: date,
                          child: Text(
                              "${date.year}-${date.month.toString().padLeft(2, '0')}"),
                        );
                      }),
                      onChanged: (newDate) {
                        setState(() {
                          selectedDate = newDate;
                          fetchGrievanceData();
                        });
                      },
                      icon: Icons.calendar_today,
                    ),
                    SizedBox(height: 10),

                    // Category Filter
                    _buildDropdown(
                      hint: "All Categories",
                      value: selectedCategory,
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (newCategory) {
                        setState(() {
                          selectedCategory = newCategory;
                          fetchGrievanceData();
                        });
                      },
                      icon: Icons.category,
                    ),
                    SizedBox(height: 10),

                    // Department Filter
                    _buildDropdown(
                      hint: "All Departments",
                      value: selectedDepartment,
                      items: departments.map((dept) {
                        return DropdownMenuItem(
                          value: dept,
                          child: Text(dept),
                        );
                      }).toList(),
                      onChanged: (newDept) {
                        setState(() {
                          selectedDepartment = newDept;
                          fetchGrievanceData();
                        });
                      },
                      icon: Icons.business,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Bar Chart
            Container(
              height: 300,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: false),
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
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
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
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
                          toY: entry.value.toDouble(),
                          color: _getColor(entry.key),
                          width: 20,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required dynamic value,
    required List<DropdownMenuItem<dynamic>> items,
    required Function(dynamic) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField(
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      value: value,
      items: items,
      onChanged: onChanged,
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
              pw.Text("Grievance Report",
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
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