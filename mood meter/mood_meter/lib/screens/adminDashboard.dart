import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mood_meter/screens/AdminLogin.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'admin_comments.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final double maxContentWidth = 1200.0;

  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  String _selectedTimeFrame = 'This Week';
  String _selectedDepartment = 'All Departments';
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  // Dashboard data
  Map<String, dynamic> _dashboardData = {
    'morningSubmissions': 0,
    'afternoonSubmissions': 0,
    'departments': [],
    'morningMoodDistribution': {
      'Very Happy': 0,
      'Happy': 0,
      'Neutral': 0,
      'Sad': 0,
      'Angry': 0,
    },
    'afternoonMoodDistribution': {
      'Very Happy': 0,
      'Happy': 0,
      'Neutral': 0,
      'Sad': 0,
      'Angry': 0,
    },
    'recentComments': [],
    'dailyTrends': [],
    'morningHighestMood': 'None',
    'afternoonHighestMood': 'None',
  };

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    _subscription = supabase
        .from('mood_submissions')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
      _loadDashboardData();
    }, onError: (error) {
      print('Realtime subscription error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Realtime update error: $error'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'RETRY',
              onPressed: () {
                _subscription?.cancel();
                _setupRealtimeSubscription();
              },
              textColor: Colors.white,
            ),
          ),
        );
      }
    });
  }

  Future<void> _loadDashboardData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final now = DateTime.now();
      final startDate = _getStartDate();
      final nowString = now.toIso8601String();
      final startDateString = startDate.toIso8601String();

      // Fetch departments
      final departmentsResponse = await supabase
          .from('departments')
          .select('id, name')
          .order('name');

      final List<Map<String, dynamic>> departments = departmentsResponse
          .map<Map<String, dynamic>>((dept) => {
        'id': dept['id'],
        'name': dept['name'],
      })
          .toList();

      // Determine department filter
      String? departmentId;
      if (_selectedDepartment != 'All Departments') {
        final selectedDept = departments.firstWhere(
              (dept) => dept['name'] == _selectedDepartment,
          orElse: () => {},
        );
        if (selectedDept.isEmpty || selectedDept['id'] == null) {
          throw Exception('Department ID not found for $_selectedDepartment');
        }
        departmentId = selectedDept['id'];
      }

      // Fetch mood submissions with joins
      var query = supabase.from('mood_submissions').select('''
          id,
          mood,
          comment,
          created_at,
          department_id,
          users!inner(email),
          departments!inner(name)
        ''').lte('created_at', nowString).gte('created_at', startDateString);

      if (departmentId != null) {
        query = query.eq('department_id', departmentId);
      }

      final submissions = await query;

      // Process submissions by time window
      Map<String, int> morningMoodCountMap = {
        'Very Happy': 0,
        'Happy': 0,
        'Neutral': 0,
        'Sad': 0,
        'Angry': 0,
      };
      Map<String, int> afternoonMoodCountMap = {
        'Very Happy': 0,
        'Happy': 0,
        'Neutral': 0,
        'Sad': 0,
        'Angry': 0,
      };
      int morningSubmissions = 0;
      int afternoonSubmissions = 0;

      for (var submission in submissions) {
        String mood = submission['mood'] as String? ?? 'Unknown';
        final createdAt = DateTime.parse(submission['created_at']);
        if (createdAt.hour >= 9 && createdAt.hour < 13) {
          morningMoodCountMap[mood] = (morningMoodCountMap[mood] ?? 0) + 1;
          morningSubmissions++;
        } else if (createdAt.hour >= 14 && createdAt.hour < 17) {
          afternoonMoodCountMap[mood] = (afternoonMoodCountMap[mood] ?? 0) + 1;
          afternoonSubmissions++;
        }
      }

      // Determine highest moods
      String morningHighestMood = 'None';
      int morningHighestCount = 0;
      morningMoodCountMap.forEach((mood, count) {
        if (count > morningHighestCount) {
          morningHighestMood = mood;
          morningHighestCount = count;
        }
      });

      String afternoonHighestMood = 'None';
      int afternoonHighestCount = 0;
      afternoonMoodCountMap.forEach((mood, count) {
        if (count > afternoonHighestCount) {
          afternoonHighestMood = mood;
          afternoonHighestCount = count;
        }
      });

      // Get recent comments
      final commentsWithText = submissions
          .where((submission) => submission['comment'] != null)
          .map((submission) => {
        'mood': submission['mood'] ?? 'Unknown',
        'comment': submission['comment'],
        'created_at': submission['created_at'],
        'department': submission['departments']['name'] ?? 'Unknown',
        'user_email': submission['users']['email'] ?? 'Anonymous',
        'time_window': DateTime.parse(submission['created_at']).hour >= 9 &&
            DateTime.parse(submission['created_at']).hour < 13
            ? 'Morning'
            : 'Afternoon',
      })
          .toList()
        ..sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
      final recentComments = commentsWithText.take(5).toList();

      // Fetch daily trends
      final dailyTrends = await supabase.rpc(
        'get_daily_mood_averages',
        params: {
          'start_date': startDateString,
          'end_date': nowString,
          'dept_filter': departmentId,
        },
      );

      if (mounted) {
        setState(() {
          _dashboardData = {
            'morningSubmissions': morningSubmissions,
            'afternoonSubmissions': afternoonSubmissions,
            'departments': ['All Departments', ...departments.map((e) => e['name'])],
            'morningMoodDistribution': morningMoodCountMap,
            'afternoonMoodDistribution': afternoonMoodCountMap,
            'recentComments': recentComments,
            'dailyTrends': dailyTrends ?? [],
            'morningHighestMood': morningHighestMood,
            'afternoonHighestMood': afternoonHighestMood,
          };
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error loading dashboard data: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: $error'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'RETRY',
              onPressed: _loadDashboardData,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_selectedTimeFrame) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'This Week':
        return now.subtract(Duration(days: 7));
      case 'This Month':
        return DateTime(now.year, now.month, 1);
      case 'Last 3 Months':
        return DateTime(now.year, now.month - 3, now.day);
      case 'All Time':
        return DateTime(now.year - 10, now.month, now.day);
      default:
        return now.subtract(Duration(days: 7));
    }
  }

  void _showDateFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Time Frame',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF2AABE2),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...['Today', 'This Week', 'This Month', 'Last 3 Months', 'All Time'].map((timeFrame) => ListTile(
                title: Text(timeFrame),
                leading: Radio<String>(
                  value: timeFrame,
                  groupValue: _selectedTimeFrame,
                  activeColor: const Color(0xFF2AABE2),
                  onChanged: (value) {
                    setModalState(() {
                      _selectedTimeFrame = value!;
                    });
                  },
                ),
                onTap: () {
                  setModalState(() {
                    _selectedTimeFrame = timeFrame;
                  });
                },
              )),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadDashboardData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2AABE2),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDepartmentFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Department',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF2AABE2),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _dashboardData['departments'].length,
                  itemBuilder: (context, index) {
                    final department = _dashboardData['departments'][index];
                    return ListTile(
                      title: Text(department),
                      leading: Radio<String>(
                        value: department,
                        groupValue: _selectedDepartment,
                        activeColor: const Color(0xFF2AABE2),
                        onChanged: (value) {
                          setModalState(() {
                            _selectedDepartment = value!;
                          });
                        },
                      ),
                      onTap: () {
                        setModalState(() {
                          _selectedDepartment = department;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadDashboardData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2AABE2),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportOptionsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Export Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF2AABE2),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as Excel'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Coming Soon")));
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Coming Soon")));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Bar Shimmer
          _buildShimmerFilterBar(),
          const SizedBox(height: 20),
          // Morning Section Shimmer
          _buildShimmerSection(),
          const SizedBox(height: 20),
          // Afternoon Section Shimmer
          _buildShimmerSection(),
          const SizedBox(height: 20),
          // Daily Trend Shimmer
          _buildShimmerContainer(height: 220),
          const SizedBox(height: 20),
          // Comments Shimmer
          for (int i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildShimmerContainer(height: 120),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerFilterBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile layout - stack vertically
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildShimmerContainer(height: 48)),
                  const SizedBox(width: 10),
                  _buildShimmerContainer(width: 48, height: 48),
                ],
              ),
              const SizedBox(height: 10),
              _buildShimmerContainer(height: 48),
            ],
          );
        } else {
          // Desktop layout - horizontal
          return Row(
            children: [
              Expanded(child: _buildShimmerContainer(height: 48)),
              const SizedBox(width: 10),
              Expanded(child: _buildShimmerContainer(height: 48)),
              const SizedBox(width: 10),
              _buildShimmerContainer(width: 48, height: 48),
            ],
          );
        }
      },
    );
  }

  Widget _buildShimmerSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          // Mobile layout - stack vertically
          return Column(
            children: [
              _buildShimmerContainer(height: 18, width: 150),
              const SizedBox(height: 10),
              _buildShimmerContainer(height: 250),
              const SizedBox(height: 10),
              _buildShimmerStatsCards(),
            ],
          );
        } else {
          // Desktop layout - horizontal
          return Column(
            children: [
              _buildShimmerContainer(height: 18, width: 150),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(flex: 2, child: _buildShimmerStatsCards()),
                  const SizedBox(width: 10),
                  Expanded(flex: 3, child: _buildShimmerContainer(height: 220)),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildShimmerStatsCards() {
    return Column(
      children: [
        _buildShimmerContainer(height: 80),
        const SizedBox(height: 10),
        _buildShimmerContainer(height: 80),
        const SizedBox(height: 10),
        _buildShimmerContainer(height: 80),
      ],
    );
  }

  Widget _buildShimmerContainer({double? width, double? height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2AABE2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminLoginScreen()));
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxContentWidth,
          ),
          child: RefreshIndicator(
            onRefresh: _loadDashboardData,
            color: const Color(0xFF2AABE2),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Responsive Filter Bar
                  _buildResponsiveFilterBar(),
                  const SizedBox(height: 20),

                  // Morning Section
                  _buildResponsiveMoodSection(
                    'Morning Mood Distribution (9 AM - 1 PM)',
                    _dashboardData['morningMoodDistribution'],
                    'Morning',
                    _dashboardData['morningSubmissions'],
                    _dashboardData['morningHighestMood'],
                    isReversed: false,
                  ),
                  const SizedBox(height: 20),

                  // Afternoon Section
                  _buildResponsiveMoodSection(
                    'Afternoon Mood Distribution (2 PM - 5 PM)',
                    _dashboardData['afternoonMoodDistribution'],
                    'Afternoon',
                    _dashboardData['afternoonSubmissions'],
                    _dashboardData['afternoonHighestMood'],
                    isReversed: true,
                  ),
                  const SizedBox(height: 20),

                  // Daily Trend Chart
                  const Text(
                    'Daily Mood Trend',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: _buildDailyTrendChart(),
                  ),
                  const SizedBox(height: 20),

                  // Recent Comments
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Comments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => AdminCommentsScreen()));
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildRecentComments(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveFilterBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile layout - stack department filter below
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildFilterButton(
                      icon: Icons.calendar_today,
                      label: _selectedTimeFrame,
                      onPressed: _showDateFilterModal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildExportButton(),
                ],
              ),
              const SizedBox(height: 10),
              _buildFilterButton(
                icon: Icons.business,
                label: _selectedDepartment,
                onPressed: _showDepartmentFilterModal,
                expanded: true,
              ),
            ],
          );
        } else {
          // Desktop layout - horizontal
          return Row(
            children: [
              Expanded(
                child: _buildFilterButton(
                  icon: Icons.calendar_today,
                  label: _selectedTimeFrame,
                  onPressed: _showDateFilterModal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFilterButton(
                  icon: Icons.business,
                  label: _selectedDepartment,
                  onPressed: _showDepartmentFilterModal,
                ),
              ),
              const SizedBox(width: 10),
              _buildExportButton(),
            ],
          );
        }
      },
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool expanded = false,
  }) {
    final button = OutlinedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2AABE2),
        side: const BorderSide(color: Color(0xFF2AABE2)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        minimumSize: const Size(0, 48),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildExportButton() {
    return IconButton(
      icon: const Icon(Icons.file_download),
      onPressed: _showExportOptionsModal,
      style: IconButton.styleFrom(
        foregroundColor: const Color(0xFF2AABE2),
        minimumSize: const Size(48, 48),
      ),
      tooltip: 'Export Data',
    );
  }

  Widget _buildResponsiveMoodSection(
      String title,
      Map<String, int> moodDistribution,
      String timeWindow,
      int submissions,
      String highestMood, {
        required bool isReversed,
      }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            if (constraints.maxWidth < 800)
            // Mobile layout - stack vertically
              Column(
                children: [
                  Container(
                    height: 250,
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: _buildMoodDistributionChart(moodDistribution, timeWindow),
                  ),
                  const SizedBox(height: 10),
                  _buildStatsCards(submissions, moodDistribution, highestMood, timeWindow),
                ],
              )
            else
            // Desktop layout - horizontal
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: isReversed
                    ? [
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 220,
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(),
                      child: _buildMoodDistributionChart(moodDistribution, timeWindow),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _buildStatsCards(submissions, moodDistribution, highestMood, timeWindow),
                  ),
                ]
                    : [
                  Expanded(
                    flex: 2,
                    child: _buildStatsCards(submissions, moodDistribution, highestMood, timeWindow),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 220,
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(),
                      child: _buildMoodDistributionChart(moodDistribution, timeWindow),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatsCards(int submissions, Map<String, int> moodDistribution, String highestMood, String timeWindow) {
    return Column(
      children: [
        _buildSummaryCard(
          '$timeWindow Submissions',
          submissions.toString(),
          Icons.how_to_vote,
        ),
        const SizedBox(height: 10),
        _buildSummaryCard(
          '$timeWindow Happiness',
          _calculateHappinessScore(moodDistribution).toStringAsFixed(1),
          Icons.sentiment_satisfied_alt,
        ),
        const SizedBox(height: 10),
        _buildSummaryCard(
          '$timeWindow Top Mood',
          highestMood,
          Icons.star,
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                icon,
                color: const Color(0xFF2AABE2),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodDistributionChart(Map<String, int> data, String timeWindow) {
    final colors = {
      'Very Happy': const Color(0xFF2ECC71),
      'Happy': const Color(0xFF3498DB),
      'Neutral': const Color(0xFFF39C12),
      'Sad': const Color(0xFFE74C3C),
      'Angry': const Color(0xFF7B241C),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 400) {
          // Very small screens - vertical layout
          return Column(
            children: [
              Expanded(
                flex: 3,
                child: PieChart(
                  PieChartData(
                    sections: data.entries.map<PieChartSectionData>((entry) {
                      return PieChartSectionData(
                        color: colors[entry.key] ?? Colors.grey,
                        value: (entry.value).toDouble(),
                        title: '',
                        radius: 40,
                      );
                    }).toList(),
                    centerSpaceRadius: 30,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                flex: 2,
                child: _buildLegend(data, colors),
              ),
            ],
          );
        } else {
          // Larger screens - horizontal layout
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: PieChart(
                  PieChartData(
                    sections: data.entries.map<PieChartSectionData>((entry) {
                      return PieChartSectionData(
                        color: colors[entry.key] ?? Colors.grey,
                        value: (entry.value).toDouble(),
                        title: '',
                        radius: constraints.maxWidth < 600 ? 40 : 50,
                      );
                    }).toList(),
                    centerSpaceRadius: constraints.maxWidth < 600 ? 30 : 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _buildLegend(data, colors),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildLegend(Map<String, int> data, Map<String, Color> colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map<Widget>((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 8,
                decoration: BoxDecoration(
                  color: colors[entry.key] ?? Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${entry.value}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDailyTrendChart() {
    final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(_dashboardData['dailyTrends']);

    if (data.isEmpty) {
      return const Center(child: Text('No trend data available'));
    }

    // Format dates for x-axis
    final dateFormat = DateFormat('MM/dd');
    final spots = List<FlSpot>.generate(data.length, (index) {
      final item = data[index];
      final date = DateTime.parse(item['date']);
      final mood = (item['average_mood'] ?? 0).toDouble();
      return FlSpot(index.toDouble(), mood);
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 1,
              verticalInterval: isSmallScreen ? 2 : 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[300]!,
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.grey[300]!,
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: isSmallScreen ? 2 : 1,
                  getTitlesWidget: (value, meta) {
                    if (value % (isSmallScreen ? 2 : 1) != 0 || value < 0 || value >= data.length) {
                      return const SizedBox();
                    }
                    final date = DateTime.parse(data[value.toInt()]['date']);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        dateFormat.format(date),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 8 : 10,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    if (value % 1 != 0) {
                      return const SizedBox();
                    }
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 8 : 10,
                      ),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey[300]!),
            ),
            minX: 0,
            maxX: (data.length - 1).toDouble(),
            minY: 1,
            maxY: 5,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: const Color(0xFF2AABE2),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: isSmallScreen ? 3 : 4,
                      color: const Color(0xFF2AABE2),
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF2AABE2).withOpacity(0.1),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentComments() {
    final comments = _dashboardData['recentComments'];
    if (comments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Center(
          child: Text(
            'No comments to display',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        final date = DateTime.parse(comment['created_at']);
        final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(date);

        final moodColors = {
          'Very Happy': const Color(0xFF2ECC71),
          'Happy': const Color(0xFF3498DB),
          'Neutral': const Color(0xFFF39C12),
          'Sad': const Color(0xFFE74C3C),
          'Angry': const Color(0xFF7B241C),
        };
        final moodColor = moodColors[comment['mood']] ?? Colors.grey;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: moodColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 400) {
                    // Stack mood and department info vertically on very small screens
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: moodColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${comment['mood']} (${comment['time_window']})',
                                style: TextStyle(
                                  color: moodColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          comment['department'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Horizontal layout for larger screens
                    return Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: moodColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${comment['mood']} (${comment['time_window']})',
                            style: TextStyle(
                              color: moodColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          comment['department'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                comment['comment'],
                style: const TextStyle(
                  fontSize: 13,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "", // user_email - keeping empty as in original
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  double _calculateHappinessScore(Map<String, int> distribution) {
    final weights = {
      'Very Happy': 5.0,
      'Happy': 4.0,
      'Neutral': 3.0,
      'Sad': 2.0,
      'Angry': 1.0,
    };

    int totalCount = 0;
    double weightedSum = 0;

    distribution.forEach((mood, count) {
      totalCount += count;
      weightedSum += (weights[mood] ?? 3.0) * count;
    });

    if (totalCount == 0) {
      return 0.0;
    }

    return weightedSum / totalCount;
  }
}