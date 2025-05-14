import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gms/theme/themeData.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;

class desktopGrievanceChart extends StatefulWidget {
  @override
  _desktopGrievanceChartState createState() => _desktopGrievanceChartState();
}

class _desktopGrievanceChartState extends State<desktopGrievanceChart> {
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Filter and Download Buttons Section
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Filter Button
                    ElevatedButton.icon(
                      onPressed: () {
                        _showFilterPopup(context);
                      },
                      icon: Icon(Icons.filter_list, color: Colors.white, size: 20),
                      label: Text(
                        "Filter",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                    SizedBox(height: 12),
                    // Download Button
                    ElevatedButton.icon(
                      onPressed: () {
                        generateAndDownloadReport(grievanceCounts);
                      },
                      icon: Icon(Icons.download, color: Colors.white, size: 20),
                      label: Text(
                        "Download",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 20),
            // Chart Section
            Expanded(
              flex: 4,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chart Title
                    Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        "Grievance Status Overview",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 2,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Bar Chart
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 1,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey.shade200,
                                strokeWidth: 1,
                              );
                            },
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                              left: BorderSide(color: Colors.grey.shade300, width: 1),
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  int index = value.toInt();
                                  if (index >= 0 && index < grievanceCounts.length) {
                                    return Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text(
                                        grievanceCounts.keys.elementAt(index),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                    );
                                  }
                                  return SizedBox.shrink();
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipPadding: EdgeInsets.all(8),
                              tooltipMargin: 8,

                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                String status = grievanceCounts.keys.elementAt(group.x.toInt());
                                return BarTooltipItem(
                                  '$status\n${rod.toY.toInt()}',
                                  TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          barGroups: grievanceCounts.entries.map((entry) {
                            double maxY = grievanceCounts.values.isNotEmpty
                                ? grievanceCounts.values.reduce((a, b) => a > b ? a : b).toDouble() * 1.1
                                : 10.0; // Fallback if empty
                            return BarChartGroupData(
                              x: grievanceCounts.keys.toList().indexOf(entry.key),
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.toDouble(),
                                  gradient: LinearGradient(
                                    colors: [
                                      _getColor(entry.key).withOpacity(0.6),
                                      _getColor(entry.key),
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  width: 24,
                                  borderRadius: BorderRadius.circular(8),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: maxY,
                                    color: Colors.grey.shade100,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                        swapAnimationDuration: Duration(milliseconds: 500),
                        swapAnimationCurve: Curves.easeInOut,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Popup Dialog for Filters
  void _showFilterPopup(BuildContext context) {
    String? tempMonth = selectedDate != null ? DateFormat('MMMM').format(selectedDate!) : null;
    String? tempDepartment = selectedDepartment;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Filters", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Month Filter
                _buildDropdown(
                  hint: "All Months",
                  value: tempMonth,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text("All Months"),
                    ),
                    ...dates.map((dateStr) {
                      DateTime date = DateFormat('yyyy-MM').parse('$dateStr-01');
                      String monthName = DateFormat('MMMM').format(date);
                      return DropdownMenuItem(
                        value: monthName,
                        child: Text(monthName),
                      );
                    }).toList(),
                  ],
                  onChanged: (newMonth) {
                    tempMonth = newMonth;
                  },
                  icon: Icons.calendar_today,
                ),
                SizedBox(height: 16),
                // Department Filter
                _buildDropdown(
                  hint: "All Departments",
                  value: tempDepartment,
                  items: departments.map((dept) {
                    return DropdownMenuItem(
                      value: dept,
                      child: Text(dept),
                    );
                  }).toList(),
                  onChanged: (newDept) {
                    tempDepartment = newDept;
                  },
                  icon: Icons.business,
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close without applying
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                side: BorderSide(color: AppColors.primaryColor, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (tempMonth == null) {
                    selectedDate = null;
                  } else {
                    int monthIndex = List.generate(
                        12,
                            (index) => DateFormat('MMMM')
                            .format(DateTime(DateTime.now().year, index + 1, 1)))
                        .indexOf(tempMonth!) +
                        1;
                    selectedDate = DateTime(DateTime.now().year, monthIndex, 1);
                  }
                  selectedDepartment = tempDepartment;
                  fetchGrievanceData();
                });
                Navigator.of(context).pop(); // Close and apply
              },
              child: Text(
                "Apply",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
            ),
          ],
        );
      },
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