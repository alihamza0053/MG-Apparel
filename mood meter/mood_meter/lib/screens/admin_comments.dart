import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

class AdminCommentsScreen extends StatefulWidget {
  const AdminCommentsScreen({Key? key}) : super(key: key);

  @override
  State<AdminCommentsScreen> createState() => _AdminCommentsScreenState();
}

class _AdminCommentsScreenState extends State<AdminCommentsScreen> {
  final double maxContentWidth = 1200.0;
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  String _selectedTimeFrame = 'All';
  String _selectedDepartment = 'All Departments';
  List<Map<String, dynamic>> _submissions = [];
  List<String> _departments = [];

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
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

      // Fetch all mood submissions
      var query = supabase.from('mood_submissions').select('''
          id,
          mood,
          comment,
          created_at,
          department_id,
          users!inner(email),
          departments!inner(name)
        ''').lte('created_at', nowString);

      if (_selectedTimeFrame != 'All') {
        query = query.gte('created_at', startDateString);
      }

      if (departmentId != null) {
        query = query.eq('department_id', departmentId);
      }

      final submissions = await query;

      // Process submissions
      final processedSubmissions = submissions
          .map((submission) => {
        'mood': submission['mood'] ?? 'Unknown',
        'comment': submission['comment'] ?? 'No comment',
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

      if (mounted) {
        setState(() {
          _submissions = processedSubmissions;
          _departments = ['All Departments', ...departments.map((e) => e['name'] as String)];
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error loading submissions: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load submissions: $error'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'RETRY',
              onPressed: _loadSubmissions,
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
      case 'All':
        return DateTime(2000, 1, 1); // Effectively no lower bound
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
              ...['Today', 'This Week', 'This Month', 'Last 3 Months', 'All'].map((timeFrame) => ListTile(
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
                  _loadSubmissions();
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
                  itemCount: _departments.length,
                  itemBuilder: (context, index) {
                    final department = _departments[index];
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
                  _loadSubmissions();
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
            ],
          ),
          const SizedBox(height: 20),
          for (int i = 0; i < 5; i++)
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
        title: const Text('All Mood Submissions'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2AABE2),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(scrollbars: false),
            child: RefreshIndicator(
              onRefresh: _loadSubmissions,
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
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Submissions List
                    _submissions.isEmpty
                        ? Container(
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
                          'No submissions to display',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                        : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _submissions.length,
                      itemBuilder: (context, index) {
                        final submission = _submissions[index];
                        final date = DateTime.parse(submission['created_at']);
                        final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(date);

                        final moodColors = {
                          'Very Happy': const Color(0xFF2ECC71),
                          'Happy': const Color(0xFF3498DB),
                          'Neutral': const Color(0xFFF39C12),
                          'Sad': const Color(0xFFE74C3C),
                          'Angry': const Color(0xFF7B241C),
                        };
                        final moodColor = moodColors[submission['mood']] ?? Colors.grey;

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
                                    '${submission['mood']} (${submission['time_window']})',
                                    style: TextStyle(
                                      color: moodColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    submission['department'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                submission['comment'],
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    submission['user_email'],
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}