import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mood_meter/screens/comment.dart';
import 'package:mood_meter/screens/submissionConfirmation.dart';
import 'package:mood_meter/screens/userLogin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'departmentSelection.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({Key? key}) : super(key: key);

  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  // Color theme
  final Color primaryColor = const Color(0xFF2596BE);
  final Color backgroundColor = const Color(0xFF2596BE);

  // Maximum width constraint for the content
  final double maxContentWidth = 800.0;

  bool _isLoading = true;
  bool _hasSubmittedMorning = false;
  bool _hasSubmittedAfternoon = false;
  String _userName = '';
  String? _userDepartment;
  String? _errorMessage;
  bool _isMorningSubmissionWindow = false;
  bool _isAfternoonSubmissionWindow = false;

  // List of mood options
  final List<Map<String, dynamic>> _moods = [
    {
      'id': 'very_happy',
      'name': 'Very Happy',
      'emoji': '😁',
      'color': const Color(0xFF4CAF50),
      'description': 'Excellent day!'
    },
    {
      'id': 'happy',
      'name': 'Happy',
      'emoji': '🙂',
      'color': const Color(0xFF8BC34A),
      'description': 'Good day'
    },
    {
      'id': 'neutral',
      'name': 'Neutral',
      'emoji': '😐',
      'color': const Color(0xFFFFC107),
      'description': 'Okay day'
    },
    {
      'id': 'sad',
      'name': 'Sad',
      'emoji': '😔',
      'color': const Color(0xFFFF9800),
      'description': 'Not great'
    },
    {
      'id': 'angry',
      'name': 'Angry',
      'emoji': '😠',
      'color': const Color(0xFFF44336),
      'description': 'Bad day'
    },
  ];

  @override
  void initState() {
    super.initState();
    // Fetch user data and check submission status
    _loadUserData();
    // Check submission time windows
    _checkTimeRestriction();
  }

  void _checkTimeRestriction() {
    final now = DateTime.now();
    setState(() {
      _isMorningSubmissionWindow = now.hour >= 9 && now.hour < 13;
      _isAfternoonSubmissionWindow = now.hour >= 14 && now.hour < 17;
    });
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }

      final userData = await Supabase.instance.client
          .from('users')
          .select('email, department_id, name')
          .eq('id', user.id)
          .single();

      String? departmentId = userData['department_id'];
      if (departmentId != null) {
        final departmentExists = await Supabase.instance.client
            .from('departments')
            .select('id')
            .eq('id', departmentId)
            .maybeSingle();
        if (departmentExists == null) {
          departmentId = null;
        }
      }

      final submissionStatus = await _checkMoodSubmissionsToday(user.id);

      if (!mounted) return;
      setState(() {
        _userName = userData['name'] ?? user.email?.split('@')[0] ?? 'User';
        _userDepartment = departmentId;
        _hasSubmittedMorning = submissionStatus['morning']!;
        _hasSubmittedAfternoon = submissionStatus['afternoon']!;
        _isLoading = false;
      });

      if (_userDepartment == null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DepartmentSelectionScreen()),
        );
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<Map<String, bool>> _checkMoodSubmissionsToday(String userId) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final submissions = await Supabase.instance.client
          .from('mood_submissions')
          .select('created_at')
          .eq('user_id', userId)
          .gte('created_at', '$today 00:00:00')
          .lt('created_at', '$today 23:59:59');

      bool hasMorningSubmission = false;
      bool hasAfternoonSubmission = false;

      for (var submission in submissions) {
        final createdAt = DateTime.parse(submission['created_at']);
        if (createdAt.hour >= 9 && createdAt.hour < 13) {
          hasMorningSubmission = true;
        } else if (createdAt.hour >= 14 && createdAt.hour < 17) {
          hasAfternoonSubmission = true;
        }
      }

      return {
        'morning': hasMorningSubmission,
        'afternoon': hasAfternoonSubmission,
      };
    } catch (e) {
      print('Error checking mood submissions: $e');
      return {'morning': false, 'afternoon': false};
    }
  }

  Future<void> _submitMood(String moodId) async {
    if (!_isMorningSubmissionWindow && !_isAfternoonSubmissionWindow) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mood submissions are only available from 9 AM to 1 PM or 2 PM to 5 PM'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isMorningSubmissionWindow && _hasSubmittedMorning) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already submitted your morning mood'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isAfternoonSubmissionWindow && _hasSubmittedAfternoon) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already submitted your afternoon mood'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_userDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a department before submitting your mood'),
          backgroundColor: Colors.red,
        ),
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DepartmentSelectionScreen()),
        );
      }
      return;
    }

    final mood = _moods.firstWhere(
          (m) => m['id'] == moodId,
      orElse: () => {'name': 'Unknown'},
    );
    final moodName = mood['name'] as String;

    String? comment;
    if (moodId == 'angry') {
      if (!mounted) return;
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CommentScreen(moodId: moodId),
        ),
      );

      if (result == null) {
        return;
      }
      comment = result.isNotEmpty ? result : null;
    } else {
      comment = 'Feeling $moodName today!';
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      await Supabase.instance.client.from('mood_submissions').insert({
        'user_id': user.id,
        'mood': moodName,
        'department_id': _userDepartment,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubmissionConfirmationScreen(moodType: moodId),
        ),
      );
      setState(() {
        _isLoading = false;
        if (_isMorningSubmissionWindow) {
          _hasSubmittedMorning = true;
        } else if (_isAfternoonSubmissionWindow) {
          _hasSubmittedAfternoon = true;
        }
      });
    } catch (e) {
      print('Error submitting mood: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to submit mood: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
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
    final now = DateTime.now();
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');
    final formattedDate = dateFormatter.format(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Meter'),
        centerTitle: true,
        backgroundColor: primaryColor,
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
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            color: backgroundColor.withOpacity(0.1),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxContentWidth,
                  ),
                  child: ScrollConfiguration(
                    behavior: const ScrollBehavior().copyWith(scrollbars: false),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await _loadUserData();
                        _checkTimeRestriction();
                      },
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $_userName!',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Department: ${_userDepartment != null ? _userDepartment!.toUpperCase() : 'NOT SET'}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (!_isMorningSubmissionWindow && !_isAfternoonSubmissionWindow)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.orange,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Time Restricted',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Mood submissions are available from 9 AM to 1 PM and 2 PM to 5 PM.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_isMorningSubmissionWindow && _hasSubmittedMorning)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Morning Submission Done',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'You have submitted your morning mood.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_isAfternoonSubmissionWindow && _hasSubmittedAfternoon)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Afternoon Submission Done',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'You have submitted your afternoon mood.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                          Text(
                            (_hasSubmittedMorning && _isMorningSubmissionWindow) ||
                                (_hasSubmittedAfternoon && _isAfternoonSubmissionWindow)
                                ? 'Your submission for this time slot:'
                                : 'How are you feeling today?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          for (int i = 0; i < _moods.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: ((_isMorningSubmissionWindow && _hasSubmittedMorning) ||
                                      (_isAfternoonSubmissionWindow && _hasSubmittedAfternoon) ||
                                      (!_isMorningSubmissionWindow && !_isAfternoonSubmissionWindow))
                                      ? null
                                      : () => _submitMood(_moods[i]['id']),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16.0,
                                      horizontal: 20.0,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _moods[i]['color'].withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: _moods[i]['color'].withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              _moods[i]['emoji'],
                                              style: const TextStyle(fontSize: 32),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _moods[i]['name'],
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: ((_isMorningSubmissionWindow && _hasSubmittedMorning) ||
                                                      (_isAfternoonSubmissionWindow && _hasSubmittedAfternoon) ||
                                                      (!_isMorningSubmissionWindow && !_isAfternoonSubmissionWindow))
                                                      ? Colors.grey
                                                      : Colors.grey[800],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _moods[i]['description'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: ((_isMorningSubmissionWindow && _hasSubmittedMorning) ||
                                                      (_isAfternoonSubmissionWindow && _hasSubmittedAfternoon) ||
                                                      (!_isMorningSubmissionWindow && !_isAfternoonSubmissionWindow))
                                                      ? Colors.grey
                                                      : Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!_hasSubmittedMorning && _isMorningSubmissionWindow ||
                                            !_hasSubmittedAfternoon && _isAfternoonSubmissionWindow)
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: _moods[i]['color'],
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          if (!_hasSubmittedMorning && _isMorningSubmissionWindow ||
                              !_hasSubmittedAfternoon && _isAfternoonSubmissionWindow)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'Your feedback helps us improve workplace environment. Tap on a mood to submit.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          if (!_isMorningSubmissionWindow && !_isAfternoonSubmissionWindow)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'Mood submission is available from 9 AM to 1 PM and 2 PM to 5 PM. Pull down to refresh and check again later.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}