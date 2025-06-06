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
import 'package:supabase_flutter/supabase_flutter.dart';

// Add these imports at the top of your file
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// Initialize Supabase in main()
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://tylrzxvbiklnnrqwixnv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5bHJ6eHZiaWtsbm5ycXdpeG52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ3MDA5NzYsImV4cCI6MjA2MDI3Njk3Nn0.OYo0M8NGTrXxMdnEeTm7U3DWnOXXcAYR3DFQnzbTudI',
  );

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



// SupabaseService for database operations
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  // Get the current user ID or generate anonymous ID
  String get userId {
    if (_client.auth.currentUser != null) {
      return _client.auth.currentUser!.id;
    }
    // For anonymous users, create or retrieve a UUID from shared preferences
    // This is a simplified example - in a real app, store this in secure storage
    return _uuid.v4();
  }

  // Fetch all mood entries (with optional filters)
  Future<List<MoodEntry>> fetchMoodEntries({
    String? department,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Start with base query
      var query = _client.from('mood_entries').select();

      // Apply filters if provided
      if (department != null) {
        query = query.eq('department', department);
      }

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }

      // Execute query
      final data = await query.order('date', ascending: true);

      // Convert to MoodEntry objects
      return data.map<MoodEntry>((json) => MoodEntry.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching mood entries: $e');
      return [];
    }
  }

  // Add a new mood entry
  Future<bool> addMoodEntry(MoodEntry entry) async {
    try {
      // Convert to JSON for storage
      final json = entry.toJson();

      // Insert into Supabase
      await _client.from('mood_entries').insert(json);
      return true;
    } catch (e) {
      print('Error adding mood entry: $e');
      return false;
    }
  }

  // Delete a mood entry
  Future<bool> deleteMoodEntry(String id) async {
    try {
      await _client.from('mood_entries').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting mood entry: $e');
      return false;
    }
  }

  // Get department statistics
  Future<Map<String, int>> getDepartmentStats() async {
    try {
      // Use a raw SQL query instead of the group method
      final response = await _client
          .rpc('get_department_stats', params: {});

      // Process the response
      final List<dynamic> data = response as List<dynamic>;
      Map<String, int> stats = {};

      for (var item in data) {
        stats[item['department']] = item['count'];
      }

      return stats;
    } catch (e) {
      print('Error getting department stats: $e');

      // Alternative approach - fetch all entries and count them in Dart
      try {
        final data = await _client.from('mood_entries').select('department');

        // Count occurrences of each department
        Map<String, int> stats = {};
        for (var item in data) {
          final dept = item['department'] as String?;
          if (dept != null) {
            stats[dept] = (stats[dept] ?? 0) + 1;
          }
        }

        return stats;
      } catch (e) {
        print('Error with alternative approach: $e');
        return {};
      }
    }
  }

}

// Updated MoodEntry class with ID for Supabase
class MoodEntry {
  final String id;
  final DateTime date;
  final String mood;
  final String? department;
  final String userId;
  final String? comment;

  MoodEntry({
    String? id,
    required this.date,
    required this.mood,
    this.department,
    String? userId,
    this.comment,
  }) : id = id ?? const Uuid().v4(),
        userId = userId ?? Supabase.instance.client.auth.currentUser?.id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood,
      'department': department,
      'user_id': userId,
      'comment': comment,
    };
  }

  static MoodEntry fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      mood: json['mood'],
      department: json['department'],
      userId: json['user_id'],
      comment: json['comment'],
    );
  }
}

// Updated MoodDataProvider to use Supabase
class MoodDataProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<MoodEntry> _moodEntries = [];
  bool _isLoading = false;

  List<MoodEntry> get moodEntries => _moodEntries;
  bool get isLoading => _isLoading;

  // Load all entries on initialization
  MoodDataProvider() {
    fetchEntries();
  }

  // Fetch entries from Supabase
  Future<void> fetchEntries({
    String? department,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    _moodEntries = await _supabaseService.fetchMoodEntries(
      department: department,
      startDate: startDate,
      endDate: endDate,
    );

    _isLoading = false;
    notifyListeners();
  }

  // Add a new mood entry
  Future<bool> addMoodEntry(MoodEntry entry) async {
    _isLoading = true;
    notifyListeners();

    final success = await _supabaseService.addMoodEntry(entry);

    if (success) {
      _moodEntries.add(entry);
    }

    _isLoading = false;
    notifyListeners();

    return success;
  }

  // Get filtered entries (using local cache)
  List<MoodEntry> getFilteredEntries({
    String? department,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _moodEntries.where((entry) {
      bool departmentMatch = department == null || entry.department == department;
      bool dateMatch = true;

      if (startDate != null) {
        dateMatch = dateMatch && entry.date.isAfter(startDate);
      }

      if (endDate != null) {
        dateMatch = dateMatch && entry.date.isBefore(endDate.add(const Duration(days: 1)));
      }

      return departmentMatch && dateMatch;
    }).toList();
  }

  // Get trending mood
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

// Modified MoodInputScreen to use Supabase
class MoodInputScreen extends StatefulWidget {
  const MoodInputScreen({Key? key}) : super(key: key);

  @override
  State<MoodInputScreen> createState() => _MoodInputScreenState();
}

class _MoodInputScreenState extends State<MoodInputScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moodProvider = Provider.of<MoodDataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('How are you feeling today?'),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                const SizedBox(height: 30),
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    labelText: 'Add a comment (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Your mood will be logged anonymously',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodButton(BuildContext context, String emoji, String moodName, MoodDataProvider provider) {
    // Get user settings from preferences (in a real app)
    final userDepartment = 'Engineering'; // Replace with actual user department from preferences

    return InkWell(
      onTap: () async {
        setState(() {
          _isSubmitting = true;
        });

        final success = await provider.addMoodEntry(
          MoodEntry(
            date: DateTime.now(),
            mood: emoji,
            department: userDepartment,
            comment: _commentController.text.isEmpty ? null : _commentController.text,
          ),
        );

        setState(() {
          _isSubmitting = false;
          _commentController.clear();
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mood logged: $moodName')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to log mood. Please try again.')),
          );
        }
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
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

// Updated VibeMeterScreen with Supabase integration
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

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final moodProvider = Provider.of<MoodDataProvider>(context, listen: false);
    await moodProvider.fetchEntries(
      department: selectedDepartment,
      startDate: startDate,
      endDate: endDate,
    );
  }

// Rest of the VibeMeterScreen implementation remains the same as before
// Just make sure to call _refreshData() when filters change
// ...

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