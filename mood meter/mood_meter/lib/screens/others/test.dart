// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
    SettingsScreen(),
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

// Vibe Meter Screen
class VibeMeterScreen extends StatefulWidget {
  const VibeMeterScreen({Key? key}) : super(key: key);

  @override
  State<VibeMeterScreen> createState() => _VibeMeterScreenState();
}

class _VibeMeterScreenState extends State<VibeMeterScreen> {
  String? selectedDepartment;
  DateTime? startDate;
  DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    final moodProvider = Provider.of<MoodDataProvider>(context);
    final filteredEntries = moodProvider.getFilteredEntries(
      department: selectedDepartment,
      startDate: startDate,
      endDate: endDate,
    );

    final trendingMood = moodProvider.getTrendingMood();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vibe Meter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              // PDF export functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting PDF...')),
              );
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
                              // Date picker functionality
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
                          Text('${startDate!.day}/${startDate!.month} - ${endDate!.day}/${endDate!.month}',
                              style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Chart placeholder (in a real app, use fl_chart or charts_flutter)
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
                        child: Center(
                          child: filteredEntries.isEmpty
                              ? const Text('No mood data available for selected filters')
                              : const Text('Chart will appear here in the complete implementation'),
                        ),
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
}

// Settings Screen
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