import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mood_meter/screens/userDashboard.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'userLogin.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final bool forScreen;
  const AnalyticsDashboardScreen({Key? key,required this.forScreen}) : super(key: key);

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final double maxContentWidth = 1400.0;
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  String _selectedTimeFrame = 'This Week';
  String _selectedDepartment = 'All Departments';
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  Map<String, dynamic> _analyticsData = {
    'overallMoodDistribution': {
      'Very Happy': 0,
      'Happy': 0,
      'Neutral': 0,
      'Sad': 0,
      'Angry': 0,
    },
    'departmentTrends': [],
    'morningMoodDistribution': {
      'Very Happy': 0,
      'Happy': 0,
      'Neutral': 0,
      'Sad': 0,
      'Angry': 0,
    },
    'eveningMoodDistribution': {
      'Very Happy': 0,
      'Happy': 0,
      'Neutral': 0,
      'Sad': 0,
      'Angry': 0,
    },
    'departments': [],
  };

  final moodColors = {
    'Very Happy': const Color(0xFF2ECC71),
    'Happy': const Color(0xFF3498DB),
    'Neutral': const Color(0xFFF39C12),
    'Sad': const Color(0xFFE74C3C),
    'Angry': const Color(0xFF7B241C),
  };

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRealtimeSubscription();
    });
  }

  @override
  void dispose() {
    try {
      _subscription?.cancel();
    } catch (e) {
      print('Error cancelling subscription: $e');
    }
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    if (supabase.auth.currentUser == null) {
      print('DEBUG: No authenticated user. Skipping real-time subscription.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please log in to view real-time updates')),
        );
      }
      return;
    }

    _subscription = supabase
        .from('mood_submissions')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
      print('DEBUG: Realtime data received: ${data.take(3).toList()}');
      _loadAnalyticsData();
    }, onError: (error) {
      print('Realtime subscription error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Realtime subscription failed: $error')),
        );
      }
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) _setupRealtimeSubscription();
      });
    });
  }

  Future<void> _loadAnalyticsData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final startDate = _getStartDate();
      final nowString = now.toIso8601String();
      final startDateString = startDate.toIso8601String();

      print('DEBUG: Loading analytics for $startDateString to $nowString');
      print('DEBUG: Selected department: $_selectedDepartment, timeframe: $_selectedTimeFrame');

      final departmentsResponse = await supabase
          .from('departments')
          .select('id, name')
          .order('name');
      final List<Map<String, dynamic>> departments = departmentsResponse
          .map<Map<String, dynamic>>((dept) => {'id': dept['id'], 'name': dept['name']})
          .toList();
      print('DEBUG: Processed departments: $departments');

      String? departmentId;
      if (_selectedDepartment != 'All Departments') {
        final selectedDept = departments.firstWhere(
              (dept) => dept['name'] == _selectedDepartment,
          orElse: () => {'id': null, 'name': 'Unknown'},
        );
        departmentId = selectedDept['id'];
        if (departmentId == null) {
          print('DEBUG: Invalid department: $_selectedDepartment');
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid department selected')),
            );
          }
          return;
        }
      }

      var query = supabase.from('mood_submissions').select('''
          id, mood, created_at, department_id, departments!inner(name)
        ''').lte('created_at', nowString).gte('created_at', startDateString);

      if (departmentId != null) {
        query = query.eq('department_id', departmentId);
      }

      print('DEBUG: Executing query: $query');
      final submissions = await query;
      print('DEBUG: Submissions count: ${submissions.length}');
      print('DEBUG: First few submissions: ${submissions.take(3).toList()}');

      if (submissions.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No mood submissions found for the selected filters')),
        );
      }

      Map<String, int> overallMoodCountMap = {
        'Very Happy': 0,
        'Happy': 0,
        'Neutral': 0,
        'Sad': 0,
        'Angry': 0,
      };
      Map<String, int> morningMoodCountMap = {
        'Very Happy': 0,
        'Happy': 0,
        'Neutral': 0,
        'Sad': 0,
        'Angry': 0,
      };
      Map<String, int> eveningMoodCountMap = {
        'Very Happy': 0,
        'Happy': 0,
        'Neutral': 0,
        'Sad': 0,
        'Angry': 0,
      };

      Map<String, Map<String, int>> departmentMoods = {};

      for (var submission in submissions) {
        String mood = submission['mood'] as String? ?? 'Unknown';
        String deptName = submission['departments']['name'] as String? ?? 'Unknown';
        final createdAt = DateTime.parse(submission['created_at']);
        final hour = createdAt.hour;

        if (overallMoodCountMap.containsKey(mood)) {
          overallMoodCountMap[mood] = overallMoodCountMap[mood]! + 1;
        }

        if (!departmentMoods.containsKey(deptName)) {
          departmentMoods[deptName] = {
            'Very Happy': 0,
            'Happy': 0,
            'Neutral': 0,
            'Sad': 0,
            'Angry': 0,
          };
        }
        if (departmentMoods[deptName]!.containsKey(mood)) {
          departmentMoods[deptName]![mood] = departmentMoods[deptName]![mood]! + 1;
        }

        if (hour >= 9 && hour < 13) {
          if (morningMoodCountMap.containsKey(mood)) {
            morningMoodCountMap[mood] = morningMoodCountMap[mood]! + 1;
          }
        }
        else if (hour >= 14 && hour < 18) {
          if (eveningMoodCountMap.containsKey(mood)) {
            eveningMoodCountMap[mood] = eveningMoodCountMap[mood]! + 1;
          }
        }
      }

      List<Map<String, dynamic>> departmentTrends = [];
      departmentMoods.forEach((deptName, moods) {
        int total = moods.values.fold(0, (sum, count) => sum + count);
        if (total > 0) {
          Map<String, double> percentages = {};
          moods.forEach((mood, count) {
            percentages[mood] = (count / total) * 100;
          });
          departmentTrends.add({
            'department': deptName,
            'total': total,
            'percentages': percentages,
          });
        }
      });

      if (!mounted) return;
      setState(() {
        _analyticsData = {
          'overallMoodDistribution': overallMoodCountMap,
          'departmentTrends': departmentTrends,
          'morningMoodDistribution': morningMoodCountMap,
          'eveningMoodDistribution': eveningMoodCountMap,
          'departments': ['All Departments', ...departments.map((e) => e['name']).toSet().toList()],
        };
        _isLoading = false;
      });
    } catch (error) {
      print('Error loading analytics data: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load analytics data: $error')),
      );
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
                  _loadAnalyticsData();
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
                  itemCount: _analyticsData['departments'].length,
                  itemBuilder: (context, index) {
                    final department = _analyticsData['departments'][index];
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
                  _loadAnalyticsData();
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

  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(
              _selectedTimeFrame,
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: _showDateFilterModal,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2AABE2),
              side: const BorderSide(color: Color(0xFF2AABE2)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              minimumSize: const Size(0, 48),
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
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              minimumSize: const Size(0, 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(Map<String, int> data, String title) {
    int total = data.values.fold(0, (sum, count) => sum + count);

    if (total == 0) {
      return Container(
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'No data available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sections: data.entries.map<PieChartSectionData>((entry) {
                        double percentage = (entry.value / total) * 100;
                        return PieChartSectionData(
                          color: moodColors[entry.key] ?? Colors.grey,
                          value: entry.value.toDouble(),
                          title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          radius: 45,
                        );
                      }).toList(),
                      centerSpaceRadius: 25,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: data.entries.map<Widget>((entry) {
                      double percentage = (entry.value / total) * 100;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: moodColors[entry.key] ?? Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 10,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentTrendsChart() {
    final trends = _analyticsData['departmentTrends'] as List<Map<String, dynamic>>;

    if (trends.isEmpty) {
      return Container(
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Column(
          children: [
            Text(
              'Department Mood Trends',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: Center(
                child: Text(
                  'No department data available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Text(
            'Department Mood Trends',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final mood = ['Very Happy', 'Happy', 'Neutral', 'Sad', 'Angry'][rodIndex];
                      return BarTooltipItem(
                        '$mood\n${rod.toY.toStringAsFixed(1)}%',
                        const TextStyle(color: Colors.white, fontSize: 10),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < trends.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              trends[value.toInt()]['department'],
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: trends.asMap().entries.map((entry) {
                  final index = entry.key;
                  final trend = entry.value;
                  final percentages = trend['percentages'] as Map<String, double>;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: percentages['Very Happy'] ?? 0,
                        color: moodColors['Very Happy'],
                        width: 8,
                      ),
                      BarChartRodData(
                        toY: percentages['Happy'] ?? 0,
                        color: moodColors['Happy'],
                        width: 8,
                      ),
                      BarChartRodData(
                        toY: percentages['Neutral'] ?? 0,
                        color: moodColors['Neutral'],
                        width: 8,
                      ),
                      BarChartRodData(
                        toY: percentages['Sad'] ?? 0,
                        color: moodColors['Sad'],
                        width: 8,
                      ),
                      BarChartRodData(
                        toY: percentages['Angry'] ?? 0,
                        color: moodColors['Angry'],
                        width: 8,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: [
        _buildShimmerContainer(height: 48),
        const SizedBox(height: 20),
        SizedBox(
          height: 300,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildShimmerContainer(height: double.infinity),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 7,
                child: _buildShimmerContainer(height: double.infinity),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: Row(
            children: [
              Expanded(
                child: _buildShimmerContainer(height: double.infinity),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildShimmerContainer(height: double.infinity),
              ),
            ],
          ),
        ),
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

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2596BE).withOpacity(0.1),
      appBar: AppBar(
        title: const Text('Mood Meter'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2596BE),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _signOut,
            tooltip: 'Sign Out',
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
            onRefresh: _loadAnalyticsData,
            color: const Color(0xFF2AABE2),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildFilterBar()),
                      const SizedBox(width: 10),
                      widget.forScreen ? SizedBox() : ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserDashboard(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2AABE2),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(120, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Submit Mood'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildPieChart(
                            _analyticsData['overallMoodDistribution'],
                            'Overall Mood Distribution',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 7,
                          child: _buildDepartmentTrendsChart(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildPieChart(
                            _analyticsData['morningMoodDistribution'],
                            'Morning Mood Distribution\n(9 AM - 1 PM)',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPieChart(
                            _analyticsData['eveningMoodDistribution'],
                            'Evening Mood Distribution\n(2 PM - 6 PM)',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}