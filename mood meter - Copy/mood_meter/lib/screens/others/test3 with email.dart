// Flutter + Supabase Mood Meter App with Admin Panel
// Primary Color: #2AABE2 (Sky Blue)

// Dependencies (pubspec.yaml):
// flutter, supabase_flutter, fl_chart, excel, intl

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://tylrzxvbiklnnrqwixnv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5bHJ6eHZiaWtsbm5ycXdpeG52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ3MDA5NzYsImV4cCI6MjA2MDI3Njk3Nn0.OYo0M8NGTrXxMdnEeTm7U3DWnOXXcAYR3DFQnzbTudI',
  );
  runApp(MoodMeterApp());
}

class MoodMeterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Meter',
      theme: ThemeData(primaryColor: Color(0xFF2AABE2)),
      home: AuthGate(),
    );
  }
}


class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return AdminPanel();
    } else {
      return LoginPage();
    }
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();

  void _login() async {
    final email = emailController.text;
    if (!email.endsWith('@mgapparel.com')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Only @mgapparel.com emails allowed')));
      return;
    }
    await Supabase.instance.client.auth.signInWithOtp(email: email);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Check your email for login link')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
              SizedBox(height: 16),
              ElevatedButton(onPressed: _login, child: Text('Login')),
            ],
          ),
        ),
      ),
    );
  }
}

class DepartmentSelectionPage extends StatelessWidget {
  final List<String> departments = ['HR', 'Tech', 'Sales', 'Support'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Department')),
      body: ListView.builder(
        itemCount: departments.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(departments[index]),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => MoodDashboard(department: departments[index])));
            },
          );
        },
      ),
    );
  }
}

class MoodDashboard extends StatefulWidget {
  final String department;
  MoodDashboard({required this.department});

  @override
  _MoodDashboardState createState() => _MoodDashboardState();
}

class _MoodDashboardState extends State<MoodDashboard> {
  final moods = ['Happy', 'Neutral', 'Sad', 'Angry'];
  String? selectedMood;
  final commentController = TextEditingController();
  bool hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    checkIfAlreadySubmitted();
  }

  void checkIfAlreadySubmitted() async {
    final email = Supabase.instance.client.auth.currentUser!.email;
    final today = DateTime.now();
    final response = await Supabase.instance.client
        .from('moods')
        .select()
        .eq('email', email as Object)
        .gte('created_at', DateTime(today.year, today.month, today.day).toIso8601String())
        .maybeSingle();

    if (response != null) {
      setState(() => hasSubmitted = true);
    }
  }

  void submitMood() async {
    final user = Supabase.instance.client.auth.currentUser!;
    await Supabase.instance.client.from('moods').insert({
      'email': user.email,
      'department': widget.department,
      'mood': selectedMood,
      'comment': selectedMood == 'Angry' ? commentController.text : null,
    });
    setState(() => hasSubmitted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (hasSubmitted) {
      return Scaffold(
        appBar: AppBar(title: Text('Mood Dashboard')),
        body: Center(child: Text('You have already submitted your mood today.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Mood Dashboard')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('How do you feel today?', style: TextStyle(fontSize: 20)),
            ...moods.map((m) => RadioListTile(
              title: Text(m),
              value: m,
              groupValue: selectedMood,
              onChanged: (val) => setState(() => selectedMood = val as String),
            )),
            if (selectedMood == 'Angry')
              TextField(
                controller: commentController,
                decoration: InputDecoration(labelText: 'Please describe your issue'),
                maxLines: 3,
              ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: selectedMood != null ? submitMood : null, child: Text('Submit')),
          ],
        ),
      ),
    );
  }
}

class AdminPanel extends StatelessWidget {
  final departments = ['All', 'HR', 'Tech', 'Sales', 'Support'];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Admin Panel'),
          bottom: TabBar(tabs: [Tab(text: 'Dashboard'), Tab(text: 'Angry Feedback')]),
        ),
        body: TabBarView(
          children: [
            AdminDashboard(departments: departments),
            AngryFeedback(),
          ],
        ),
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  final List<String> departments;
  AdminDashboard({required this.departments});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String selectedDepartment = 'All';
  DateTime selectedDate = DateTime.now();
  Map<String, int> moodCounts = {};

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final from = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    var query = Supabase.instance.client.from('moods').select().gte('created_at', from.toIso8601String());
    if (selectedDepartment != 'All') query = query.eq('department', selectedDepartment);
    final data = await query;

    Map<String, int> counts = {};
    for (var item in data) {
      final mood = item['mood'];
      counts[mood] = (counts[mood] ?? 0) + 1;
    }
    setState(() => moodCounts = counts);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              DropdownButton<String>(
                value: selectedDepartment,
                items: widget.departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (val) => setState(() {
                  selectedDepartment = val!;
                  fetchData();
                }),
              ),
              Spacer(),
              ElevatedButton(
                onPressed: fetchData,
                child: Text('Refresh'),
              ),
            ],
          ),
        ),
        Expanded(
          child: BarChart(
            BarChartData(
              barGroups: moodCounts.entries.map((e) => BarChartGroupData(
                x: moods.indexOf(e.key),
                barRods: [BarChartRodData(toY: e.value.toDouble(), color: Colors.blue)],
              )).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, meta) {
                      return Text(moods[value.toInt()]);
                    },
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}

class AngryFeedback extends StatelessWidget {
  Future<List<Map<String, dynamic>>> fetchComments() async {
    final data = await Supabase.instance.client
        .from('moods')
        .select()
        .eq('mood', 'Angry')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchComments(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];
            return ListTile(
              title: Text(item['comment'] ?? 'No comment'),
              subtitle: Text('${item['email']} — ${item['created_at']}'),
            );
          },
        );
      },
    );
  }
}

const moods = ['Happy', 'Neutral', 'Sad', 'Angry'];
