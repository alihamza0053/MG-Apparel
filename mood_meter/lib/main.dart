// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
// Add these imports to the top of your file:
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:share_plus/share_plus.dart';

// Models
class MoodEntry {
  final DateTime date;
  final String mood;
  final String? department;
  final String? userId;
  final String? comment;

  MoodEntry({
    required this.date,
    required this.mood,
    this.department,
    this.userId,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'mood': mood,
      'department': department,
      'userId': userId,
      'comment': comment,
    };
  }

  static MoodEntry fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      date: DateTime.parse(json['date']),
      mood: json['mood'],
      department: json['department'],
      userId: json['userId'],
      comment: json['comment'],
    );
  }
}

// State Management
class MoodDataProvider with ChangeNotifier {
  List<MoodEntry> _moodEntries = [];

  List<MoodEntry> get moodEntries => _moodEntries;

  void addMoodEntry(MoodEntry entry) {
    _moodEntries.add(entry);
    notifyListeners();
    // In a real app, save to database or cloud here
  }

  List<MoodEntry> getFilteredEntries({String? department, DateTime? startDate, DateTime? endDate}) {
    return _moodEntries.where((entry) {
      bool departmentMatch = department == null || entry.department == department;
      bool dateMatch = true;

      if (startDate != null) {
        dateMatch = dateMatch && entry.date.isAfter(startDate);
      }

      if (endDate != null) {
        dateMatch = dateMatch && entry.date.isBefore(endDate);
      }

      return departmentMatch && dateMatch;
    }).toList();
  }

  String getTrendingMood() {
    if (_moodEntries.isEmpty) return '😐';

    Map<String, int> moodCounts = {};
    for (var entry in _moodEntries) {
      moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
    }

    String trendingMood = '';
    int maxCount = 0;

    moodCounts.forEach((mood, count) {
      if (count > maxCount) {
        maxCount = count;
        trendingMood = mood;
      }
    });

    return trendingMood;
  }
}

// Notification Service
class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    AndroidInitializationSettings initializationSettingsAndroid =
    const AndroidInitializationSettings('app_icon');

    var initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification:
            (int id, String? title, String? body, String? payload) async {});

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await notificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) async {});
  }

  Future<void> scheduleDailyNotification() async {
    tz.initializeTimeZones();

    // Create a time instance for noon
    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, 12, 0, 0);

    await notificationsPlugin.zonedSchedule(
      0,
      'Mood Check-in',
      'How are you feeling today?',
      _nextInstanceOfTime(scheduledTime),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mood_channel',
          'Mood Reminders',
          channelDescription: 'Daily mood check-in reminders',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(DateTime scheduledTime) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
      scheduledTime.second,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  NotificationService notificationService = NotificationService();
  await notificationService.initNotification();

  runApp(
    ChangeNotifierProvider(
      create: (context) => MoodDataProvider(),
      child: const MoodMeterApp(),
    ),
  );
}

class MoodMeterApp extends StatelessWidget {
  const MoodMeterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Meter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    MoodInputScreen(),
    VibeMeterScreen(),
    SettingsScreen()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.mood),
            label: 'Today\'s Mood',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Vibe Meter',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Mood Input Screen
class MoodInputScreen extends StatelessWidget {
  const MoodInputScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final moodProvider = Provider.of<MoodDataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('How are you feeling today?'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Select your mood:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                _buildMoodButton(context, '😃', 'Happy', moodProvider),
                _buildMoodButton(context, '😊', 'Good', moodProvider),
                _buildMoodButton(context, '😐', 'Neutral', moodProvider),
                _buildMoodButton(context, '😔', 'Sad', moodProvider),
                _buildMoodButton(context, '😠', 'Angry', moodProvider),
              ],
            ),
            const SizedBox(height: 40),
            const Text(
              'Your mood will be logged anonymously',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodButton(BuildContext context, String emoji, String moodName, MoodDataProvider provider) {
    return InkWell(
      onTap: () {
        provider.addMoodEntry(
          MoodEntry(
            date: DateTime.now(),
            mood: emoji,
            department: 'Engineering', // In a real app, get from user profile
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mood logged: $moodName')),
        );
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(35),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 40),
          ),
        ),
      ),
    );
  }
}
// Replace the existing VibeMeterScreen with this improved version
class VibeMeterScreen extends StatefulWidget {
  const VibeMeterScreen({Key? key}) : super(key: key);

  @override
  State<VibeMeterScreen> createState() => _VibeMeterScreenState();
}

class _VibeMeterScreenState extends State<VibeMeterScreen> {
  String? selectedDepartment;
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = false;

  // Mood score mapping for charting
  Map<String, double> moodScores = {
    '😃': 5.0, // Happy
    '😊': 4.0, // Good
    '😐': 3.0, // Neutral
    '😔': 2.0, // Sad
    '😠': 1.0, // Angry
  };

  @override
  Widget build(BuildContext context) {
    final moodProvider = Provider.of<MoodDataProvider>(context);
    final filteredEntries = moodProvider.getFilteredEntries(
      department: selectedDepartment,
      startDate: startDate,
      endDate: endDate,
    );

    // Sort entries by date for proper timeline display
    filteredEntries.sort((a, b) => a.date.compareTo(b.date));

    final trendingMood = moodProvider.getTrendingMood();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vibe Meter'),
        actions: [
          IconButton(
            icon: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.file_download),
            onPressed: isLoading
                ? null
                : () async {
              setState(() {
                isLoading = true;
              });
              await _exportToPdf(filteredEntries);
              setState(() {
                isLoading = false;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Department',
                            ),
                            value: selectedDepartment,
                            onChanged: (value) {
                              setState(() {
                                selectedDepartment = value;
                              });
                            },
                            items: const [
                              DropdownMenuItem(value: null, child: Text('All')),
                              DropdownMenuItem(value: 'Engineering', child: Text('Engineering')),
                              DropdownMenuItem(value: 'Marketing', child: Text('Marketing')),
                              DropdownMenuItem(value: 'HR', child: Text('HR')),
                              DropdownMenuItem(value: 'Sales', child: Text('Sales')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.date_range),
                            label: const Text('Date Range'),
                            onPressed: () async {
                              final DateTimeRange? picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  startDate = picked.start;
                                  endDate = picked.end;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Trending Mood
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Top Trending Mood',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(trendingMood, style: const TextStyle(fontSize: 40)),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${filteredEntries.length} entries',
                            style: const TextStyle(fontSize: 16)),
                        if (startDate != null && endDate != null)
                          Text('${DateFormat('MMM d').format(startDate!)} - ${DateFormat('MMM d').format(endDate!)}',
                              style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Enhanced chart with fl_chart
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mood Trends',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filteredEntries.isEmpty
                            ? const Center(child: Text('No mood data available for selected filters'))
                            : _buildMoodChart(filteredEntries),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodChart(List<MoodEntry> entries) {
    // Generate dummy data if we don't have real entries for demonstration
    List<MoodEntry> chartEntries = entries;
    if (entries.isEmpty || entries.length < 7) {
      // Generate some sample data for demonstration
      chartEntries = _generateSampleData();
    }

    // Get all spot data points from entries
    final spots = chartEntries.asMap().entries.map((entry) {
      final idx = entry.key.toDouble();
      final moodEntry = entry.value;
      // Convert mood emoji to numerical value for chart
      final moodValue = moodScores[moodEntry.mood] ?? 3.0;
      return FlSpot(idx, moodValue);
    }).toList();

    // Create gradient for the chart
    final gradientColors = [
      const Color(0xff23b6e6),
      const Color(0xff02d39a),
    ];

    return Padding(
      padding: const EdgeInsets.only(right: 16.0, left: 8.0, top: 24.0, bottom: 12.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: const Color(0xffe7e8ec),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: const Color(0xffe7e8ec),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: max(1, (chartEntries.length / 5).floorToDouble()),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < chartEntries.length) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        DateFormat('MMM d').format(chartEntries[index].date),
                        style: const TextStyle(
                          color: Color(0xff68737d),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  String text = '';
                  switch (value.toInt()) {
                    case 1:
                      text = '😠';
                      break;
                    case 2:
                      text = '😔';
                      break;
                    case 3:
                      text = '😐';
                      break;
                    case 4:
                      text = '😊';
                      break;
                    case 5:
                      text = '😃';
                      break;
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(text, style: const TextStyle(fontSize: 16)),
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          minX: 0,
          maxX: chartEntries.length.toDouble() - 1,
          minY: 0,
          maxY: 6,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: LinearGradient(
                colors: gradientColors,
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: gradientColors[0],
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: gradientColors
                      .map((color) => color.withOpacity(0.3))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<MoodEntry> _generateSampleData() {
    final random = Random();
    final today = DateTime.now();
    final sampleEntries = <MoodEntry>[];

    final moods = ['😃', '😊', '😐', '😔', '😠'];

    // Generate 14 days of sample data
    for (int i = 0; i < 14; i++) {
      final date = today.subtract(Duration(days: 13 - i));
      final mood = moods[random.nextInt(moods.length)];

      sampleEntries.add(MoodEntry(
        date: date,
        mood: mood,
        department: 'Sample',
      ));
    }

    return sampleEntries;
  }

  Future<void> _exportToPdf(List<MoodEntry> entries) async {
    // Create a PDF document
    final pdf = pw.Document();

    // Use the flutter_emoji package or simple conversion for emoji to text
    String moodToText(String emoji) {
      switch (emoji) {
        case '😃': return 'Happy';
        case '😊': return 'Good';
        case '😐': return 'Neutral';
        case '😔': return 'Sad';
        case '😠': return 'Angry';
        default: return 'Unknown';
      }
    }

    // Add pages to the PDF document
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Mood Meter Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Paragraph(text: 'Generated on ${DateFormat('MMMM d, yyyy').format(DateTime.now())}'),
            pw.SizedBox(height: 20),

            // Filters applied
            pw.Header(level: 1, text: 'Filters Applied'),
            pw.Paragraph(text: 'Department: ${selectedDepartment ?? 'All'}'),
            if (startDate != null && endDate != null)
              pw.Paragraph(text: 'Date Range: ${DateFormat('MMM d, yyyy').format(startDate!)} - ${DateFormat('MMM d, yyyy').format(endDate!)}'),
            pw.SizedBox(height: 10),

            // Summary
            pw.Header(level: 1, text: 'Summary'),
            pw.Paragraph(text: 'Total Entries: ${entries.length}'),

            // Table with mood data
            pw.Header(level: 1, text: 'Mood Entries'),
            pw.Table.fromTextArray(
              headers: ['Date', 'Mood', 'Department'],
              data: entries.map((entry) => [
                DateFormat('MMM d, yyyy').format(entry.date),
                moodToText(entry.mood),
                entry.department ?? 'N/A',
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerLeft,
              },
            ),

            // Basic statistics
            pw.SizedBox(height: 20),
            pw.Header(level: 1, text: 'Statistics'),

            // Count entries by mood
            ...entries.fold<Map<String, int>>({}, (map, entry) {
              map[entry.mood] = (map[entry.mood] ?? 0) + 1;
              return map;
            }).entries.map((e) => pw.Paragraph(
                text: '${moodToText(e.key)}: ${e.value} entries (${(e.value / entries.length * 100).toStringAsFixed(1)}%)'
            )).toList(),
          ];
        },
      ),
    );

    // Save the PDF file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'mood_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF saved to ${file.path}'),
        action: SnackBarAction(
          label: 'Share',
          onPressed: () {
            Share.shareFiles([file.path], text: 'Mood Meter Report');
          },
        ),
      ),
    );
  }
}

//Settings Screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  String _department = 'Engineering';

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Enable Daily Reminders'),
            subtitle: const Text('Get a notification to check in your mood'),
            trailing: Switch(
              value: _notifications,
              onChanged: (value) {
                setState(() {
                  _notifications = value;
                });
                if (value) {
                  notificationService.scheduleDailyNotification();
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Your Department'),
            subtitle: Text(_department),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Show department picker dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Select Department'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      'Engineering',
                      'Marketing',
                      'HR',
                      'Sales',
                      'Finance',
                    ].map((dept) => ListTile(
                      title: Text(dept),
                      onTap: () {
                        setState(() {
                          _department = dept;
                        });
                        Navigator.pop(context);
                      },
                    )).toList(),
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}