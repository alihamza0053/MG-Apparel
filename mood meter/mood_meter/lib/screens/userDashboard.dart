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

class _UserDashboardState extends State<UserDashboard> with SingleTickerProviderStateMixin {
  // Color theme
  final Color primaryColor = const Color(0xFF2AABE2);

  bool _isLoading = true;
  bool _hasSubmittedToday = false;
  String _userName = '';
  String? _userDepartment;
  String? _errorMessage;

  // Animation controller for mood selection
  late AnimationController _animationController;

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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Fetch user data and check if they've submitted mood today
    _loadUserData();

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        // User is not authenticated, redirect to login
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }

      // Get user data from Supabase
      final userData = await Supabase.instance.client
          .from('users')
          .select('email, department_id, name')
          .eq('id', user.id)
          .single();

      // Validate department_id exists in departments table
      String? departmentId = userData['department_id'];
      if (departmentId != null) {
        final departmentExists = await Supabase.instance.client
            .from('departments')
            .select('id')
            .eq('id', departmentId)
            .maybeSingle();
        if (departmentExists == null) {
          departmentId = null; // Invalid department_id, treat as unset
        }
      }

      // Check if user has submitted a mood today
      final hasSubmittedToday = await _checkMoodSubmissionToday(user.id);

      // Update state synchronously
      if (!mounted) return;
      setState(() {
        _userName = userData['name'] ?? user.email?.split('@')[0] ?? 'User';
        _userDepartment = departmentId;
        _hasSubmittedToday = hasSubmittedToday;
        _isLoading = false;
      });

      // If no valid department, redirect to DepartmentSelectionScreen
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

  Future<bool> _checkMoodSubmissionToday(String userId) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final moodSubmission = await Supabase.instance.client
          .from('mood_submissions')
          .select('id')
          .eq('user_id', userId)
          .gte('created_at', '$today 00:00:00')
          .lt('created_at', '$today 23:59:59')
          .maybeSingle();
      return moodSubmission != null;
    } catch (e) {
      print('Error checking mood submission: $e');
      return false;
    }
  }

  Future<void> _submitMood(String moodId) async {
    // If already submitted today, show message
    if (_hasSubmittedToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already submitted your mood for today'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if department is set
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

    // Find the mood name from _moods list
    final mood = _moods.firstWhere(
          (m) => m['id'] == moodId,
      orElse: () => {'name': 'Unknown'},
    );
    final moodName = mood['name'] as String;

    String? comment;
    // Handle Angry mood: Navigate to CommentScreen
    if (moodId == 'angry') {
      if (!mounted) return;
      final result = await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CommentScreen(
            moodId: moodId
          ),
        ),
      );

      // If user cancelled (e.g., pressed back), exit
      if (result == null) {
        return;
      }
      comment = result.isNotEmpty ? result : null; // Store comment if provided
    } else {
      // Auto-generate comment for other moods
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

      // Submit mood and comment to Supabase
      await Supabase.instance.client.from('mood_submissions').insert({
        'user_id': user.id,
        'mood': moodName, // Use mood name (e.g., "Very Happy")
        'department_id': _userDepartment,
        'comment': comment, // Auto-generated or user-provided comment
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SubmissionConfirmationScreen(moodType: moodId),
        ),
      );
      setState(() {
        _isLoading = false;
        _hasSubmittedToday = true;
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
    // Get current date formatted
    final now = DateTime.now();
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');
    final formattedDate = dateFormatter.format(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Meter'),
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
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadUserData,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Welcome header
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
                        'Department: ${_userDepartment ?? 'Not set'}',
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

                // Mood submission status
                if (_hasSubmittedToday)
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
                                'Thank You!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You have already submitted your mood for today.',
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

                // Mood selection prompt
                Text(
                  _hasSubmittedToday
                      ? 'Your submission for today:'
                      : 'How are you feeling today?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Error message if any
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

                // Mood selection cards
                for (int i = 0; i < _moods.length; i++)
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      // Staggered animation delay based on index
                      final delay = i * 0.1;
                      final animationValue = _animationController.value > delay
                          ? (_animationController.value - delay) / (1 - delay)
                          : 0.0;

                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - animationValue)),
                        child: Opacity(
                          opacity: animationValue,
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: _hasSubmittedToday
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
                                // Emoji
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
                                // Mood name and description
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _moods[i]['name'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _hasSubmittedToday
                                              ? Colors.grey
                                              : Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _moods[i]['description'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _hasSubmittedToday
                                              ? Colors.grey
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Arrow icon if not submitted
                                if (!_hasSubmittedToday)
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
                  ),

                const SizedBox(height: 16),

                // Helper text
                if (!_hasSubmittedToday)
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

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}