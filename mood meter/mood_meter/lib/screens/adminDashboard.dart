import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mood_meter/screens/AdminLogin.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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
  Timer? _refreshTimer;

  // Dashboard data
  Map<String, dynamic> _dashboardData = {
    'totalSubmissions': 0,
    'departments': [],
    'moodDistribution': {
      'Very Happy': 0,
      'Happy': 0,
      'Neutral': 0,
      'Sad': 0,
      'Angry': 0,
    },
    'recentComments': [],
    'dailyTrends': [],
    'highestMood': 'None',
  };

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    // Set up periodic refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    // Cancel the refresh timer to prevent memory leaks
    _refreshTimer?.cancel();
    super.dispose();
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

      // Process submissions
      Map<String, int> moodCountMap = {
        'Very Happy': 0,
        'Happy': 0,
        'Neutral': 0,
        'Sad': 0,
        'Angry': 0,
      };

      for (var submission in submissions) {
        String mood = submission['mood'] as String? ?? 'Unknown';
        moodCountMap[mood] = (moodCountMap[mood] ?? 0) + 1;
      }

      String highestMood = 'None';
      int highestCount = 0;
      moodCountMap.forEach((mood, count) {
        if (count > highestCount) {
          highestMood = mood;
          highestCount = count;
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
            'totalSubmissions': submissions.length,
            'departments': ['All Departments', ...departments.map((e) => e['name'])],
            'moodDistribution': moodCountMap,
            'recentComments': recentComments,
            'dailyTrends': dailyTrends ?? [],
            'highestMood': highestMood,
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
              ...['Today', 'This Week', 'This Month', 'Last 3 Months'].map((timeFrame) => ListTile(
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

                // Navigator.of(context).pushNamed('/admin-export', arguments: {
                //   'format': 'excel',
                //   'timeFrame': _selectedTimeFrame,
                //   'department': _selectedDepartment,
                // });
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Coming Soon")));
                // Navigator.of(context).pushNamed('/admin-export', arguments: {
                //   'format': 'pdf',
                //   'timeFrame': _selectedTimeFrame,
                //   'department': _selectedDepartment,
                // });
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
          Row(
            children: [
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 18,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 18,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 18,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 18,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < 2; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
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
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(scrollbars: false),
                child: RefreshIndicator(
                        onRefresh: _loadDashboardData,
                        color: const Color(0xFF2AABE2),
                        child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter Bar
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(_selectedTimeFrame),
                            onPressed: _showDateFilterModal,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2AABE2),
                              side: const BorderSide(color: Color(0xFF2AABE2)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.business, size: 16),
                            label: Text(
                              _selectedDepartment,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: _showDepartmentFilterModal,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2AABE2),
                              side: const BorderSide(color: Color(0xFF2AABE2)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.file_download),
                          onPressed: _showExportOptionsModal,
                          style: IconButton.styleFrom(
                            foregroundColor: const Color(0xFF2AABE2),
                          ),
                          tooltip: 'Export Data',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Summary Cards
                    Row(
                      children: [
                        _buildSummaryCard(
                          'Total Submissions',
                          _dashboardData['totalSubmissions'].toString(),
                          Icons.how_to_vote,
                        ),
                        const SizedBox(width: 10),
                        _buildSummaryCard(
                          'Happiness Score',
                          _calculateHappinessScore().toStringAsFixed(1),
                          Icons.sentiment_satisfied_alt,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildSummaryCard(
                          'Top Mood',
                          _dashboardData['highestMood'] ?? 'None',
                          Icons.star,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(), // Empty container to maintain layout
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Mood Distribution Chart
                    const Text(
                      'Mood Distribution',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 220,
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
                      ),
                      child: _buildMoodDistributionChart(),
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
                      ),
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
                            Navigator.of(context).pushNamed('/admin-comments');
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
          ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodDistributionChart() {
    final data = _dashboardData['moodDistribution'];
    final colors = {
      'Very Happy': const Color(0xFF2ECC71),
      'Happy': const Color(0xFF3498DB),
      'Neutral': const Color(0xFFF39C12),
      'Sad': const Color(0xFFE74C3C),
      'Angry': const Color(0xFF7B241C),
    };

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: data.entries.map<PieChartSectionData>((entry) {
                return PieChartSectionData(
                  color: colors[entry.key] ?? Colors.grey,
                  value: (entry.value ?? 0).toDouble(),
                  title: '',
                  radius: 50,
                );
              }).toList(),
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.entries.map<Widget>((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors[entry.key] ?? Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
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

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
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
              getTitlesWidget: (value, meta) {
                if (value % 1 != 0 || value < 0 || value >= data.length) {
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
                      fontSize: 10,
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
                    fontSize: 10,
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
                  radius: 4,
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
  }

  Widget _buildRecentComments() {
    final comments = _dashboardData['recentComments'];
    if (comments.isEmpty) {
      return Container(
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
        ),
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
                  Text(
                    comment['mood'],
                    style: TextStyle(
                      color: moodColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    comment['department'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                comment['comment'],
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    comment['user_email'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
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

  double _calculateHappinessScore() {
    final distribution = _dashboardData['moodDistribution'];
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
      totalCount += count as int;
      weightedSum += (weights[mood] ?? 3.0) * count;
    });

    if (totalCount == 0) {
      return 0.0;
    }

    return weightedSum / totalCount;
  }
}