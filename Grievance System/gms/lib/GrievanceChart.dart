import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gms/theme/themeData.dart';
import 'SupabaseService.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'dart:html' as html; // Web-specific import
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class GrievanceChart extends StatefulWidget {
  @override
  _GrievanceChartState createState() => _GrievanceChartState();
}

class _GrievanceChartState extends State<GrievanceChart> {
  final SupabaseService _supabaseService = SupabaseService();
  Map<String, int> grievanceCounts = {"pending": 0, "in progress": 0, "resolved": 0, "closed": 0};
  String selectedMonth = "All";

  Future<void> generateAndDownloadReport(Map<String, int> grievanceCounts) async {
    final pdf = pw.Document();

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
                data: grievanceCounts.entries.map((entry) => [entry.key, entry.value.toString()]).toList(),
              ),
            ],
          );
        },
      ),
    );

    final Uint8List pdfBytes = await pdf.save();

    if (kIsWeb) {
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "Grievance_Report.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/Grievance_Report.pdf';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      print("PDF saved at: $filePath");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchGrievanceData();
  }

  Future<void> fetchGrievanceData({int? month}) async {
    var data = await _supabaseService.getGrievanceCounts(month: month);
    setState(() {
      grievanceCounts = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
          border: Border.all(width: 1, color: AppColors.primaryColor),
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                dropdownColor: AppColors.primaryColor,
                value: selectedMonth,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedMonth = newValue;
                      fetchGrievanceData(month: newValue == "All" ? null : int.tryParse(newValue));
                    });
                  }
                },
                items: ["All", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]
                    .map((String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value == "All" ? "All Months" : "Month $value"),
                ))
                    .toList(),
              ),
              TextButton(
                onPressed: () => generateAndDownloadReport(grievanceCounts),
                child: Text("Download Report",style: TextStyle(color: Colors.white),),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxCount().toDouble() + 4,
                  barGroups: _getBarGroups(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(value.toInt().toString(), style: TextStyle(fontSize: 12));
                        },
                        reservedSize: 40,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  int _getMaxCount() {
    return grievanceCounts.values.isNotEmpty
        ? grievanceCounts.values.reduce((a, b) => a > b ? a : b)
        : 1;
  }

  List<BarChartGroupData> _getBarGroups() {
    List<String> statuses = ["pending", "in progress", "resolved", "closed"];
    return List.generate(statuses.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: grievanceCounts[statuses[index]]?.toDouble() ?? 0,
            color: _getColor(statuses[index]),
            width: 30,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  Color _getColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.red;
      case "in progress":
        return Colors.orange;
      case "resolved":
        return Colors.green;
      case "closed":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
