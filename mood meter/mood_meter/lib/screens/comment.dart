import 'package:flutter/material.dart';
import 'package:mood_meter/screens/others/test3%20with%20email.dart';
import 'package:mood_meter/screens/submissionConfirmation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentScreen extends StatefulWidget {
  final String moodId;

  const CommentScreen({
    Key? key,
    required this.moodId,
  }) : super(key: key);

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final Color primaryColor = const Color(0xFF2AABE2);
  final Color angryColor = const Color(0xFFF44336);

  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitted = false;
  String? _errorMessage;
  String? _userDepartment;
  final int _maxCommentLength = 500;
  DateTime? _lastSubmissionTime;

  @override
  void initState() {
    super.initState();
    _getUserDepartment();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _getUserDepartment() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userData = await Supabase.instance.client
          .from('users')
          .select('department_id')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _userDepartment = userData['department_id'];
          if (_userDepartment == null || _userDepartment!.isEmpty) {
            _errorMessage = 'Department not configured for this user';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load user data: ${e.toString()}';
        });
      }
    }
  }

  String _getMoodName() {
    switch (widget.moodId.toLowerCase()) {
      case 'very_happy':
        return 'Very Happy';
      case 'happy':
        return 'Happy';
      case 'neutral':
        return 'Neutral';
      case 'sad':
        return 'Sad';
      case 'angry':
        return 'Angry';
      default:
        return 'Unknown';
    }
  }

  Future<void> _submitFeedback() async {
    // Debounce: prevent submission if too soon or already submitted
    final now = DateTime.now();
    if (_isSubmitted || _isLoading || (_lastSubmissionTime != null && now.difference(_lastSubmissionTime!).inMilliseconds < 1000)) {
      print('Submission blocked: already submitted=$_isSubmitted, loading=$_isLoading, time since last=${_lastSubmissionTime != null ? now.difference(_lastSubmissionTime!).inMilliseconds : 'N/A'}ms');
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please provide some feedback or skip';
      });
      return;
    }

    if (_userDepartment == null || _userDepartment!.isEmpty) {
      setState(() {
        _errorMessage = 'Department not configured';
      });
      return;
    }

    print('Starting submission process');
    setState(() {
      _isLoading = true;
      _isSubmitted = true;
      _lastSubmissionTime = now;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final comment = _commentController.text.trim();
      print('Submitting feedback: mood=${_getMoodName()}, comment=$comment, department=$_userDepartment');

      // Perform Supabase insert
      await Supabase.instance.client.from('mood_submissions').insert({
        'user_id': user.id,
        'mood': _getMoodName(),
        'comment': comment,
        'department_id': _userDepartment,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('Submission successful');

      // Clear comment field immediately
      _commentController.clear();

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        print('Calling onSubmitComplete with comment: $comment');
        print('Popping CommentScreen with result: $comment');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>SubmissionConfirmationScreen(moodType: "Angry")));
      }
    } catch (e) {
      print('Submission error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to submit feedback: ${e.toString()}';
          _isLoading = false;
          _isSubmitted = false; // Allow retry on error
          _lastSubmissionTime = null;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Your Feedback'),
        backgroundColor: angryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                angryColor.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: angryColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '😠',
                              style: TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'We\'re sorry you\'re feeling angry',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Please share what\'s bothering you so we can address it',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                maxLines: null,
                                maxLength: _maxCommentLength,
                                decoration: InputDecoration(
                                  hintText: 'What happened today that made you feel angry? Your feedback helps us improve...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontStyle: FontStyle.italic,
                                  ),
                                  counterStyle: TextStyle(
                                    color: _commentController.text.length > (_maxCommentLength - 50)
                                        ? Colors.red
                                        : Colors.grey[600],
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                ),
                                textCapitalization: TextCapitalization.sentences,
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Your feedback is confidential and will help improve the workplace environment.',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: (_isLoading || _isSubmitted) ? null : () {
                        print('Submit button pressed');
                        _submitFeedback();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'Submit Feedback',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: (_isLoading || _isSubmitted) ? null : () {
                      print('Cancel button pressed');
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
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