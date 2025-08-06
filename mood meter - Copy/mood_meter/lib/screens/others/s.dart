/*import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:email_validator/email_validator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://tylrzxvbiklnnrqwixnv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5bHJ6eHZiaWtsbm5ycXdpeG52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ3MDA5NzYsImV4cCI6MjA2MDI3Njk3Nn0.OYo0M8NGTrXxMdnEeTm7U3DWnOXXcAYR3DFQnzbTudI',
  );
  runApp(App());
}


class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Meter',
      theme: ThemeData(primaryColor: Color(0xFF2AABE2)),
      home: LoginScreen(),
    );
  }
}




class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  // Color theme
  final Color primaryColor = const Color(0xFF2AABE2);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Domain validation function
  bool _isDomainValid(String email) {
    return email.endsWith('@mgapparel.com');
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validate company email
    if (!_isDomainValid(email)) {
      setState(() {
        _errorMessage = 'Only @mgapparel.com email addresses are allowed';
        _isLoading = false;
      });
      return;
    }

    try {
      // Try to sign in
      final signInResponse = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);

      // If sign-in succeeds, move forward
      await _handlePostAuth(email);
    } on AuthException catch (e) {
      // If sign-in fails (user not found or wrong password), try to sign up
      try {
        final signUpResponse = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );

        if (signUpResponse.user == null) {
          throw AuthException('Sign-up failed. Try again.');
        }

        // After sign-up, proceed
        await _handlePostAuth(email);
      } on AuthException catch (e) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    }
    catch (e) {
      print('Error during sign-in: $e');
      setState(() {
        _errorMessage = 'An unexpected error occurred';
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePostAuth(String email) async {
    final userData = await Supabase.instance.client
        .from('users')
        .select('department_id')
        .eq('email', email)
        .maybeSingle();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (userData == null || userData['department_id'] == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DepartmentSelectionScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => UserDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive design based on screen width
          final isSmallScreen = constraints.maxWidth < 600;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withOpacity(0.7),
                  Colors.white,
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Container(
                        width: isSmallScreen ? null : 400,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo and App Name
                              Icon(
                                Icons.mood,
                                size: 80,
                                color: primaryColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Mood Meter',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'your.name@mgapparel.com',
                                  prefixIcon: Icon(Icons.email, color: primaryColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: primaryColor, width: 2),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!EmailValidator.validate(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  if (!_isDomainValid(value)) {
                                    return 'Only @mgapparel.com emails are allowed';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock, color: primaryColor),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: primaryColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: primaryColor, width: 2),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),

                              // Error Message
                              if (_errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                              // Forgot Password Link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // Implement forgot password functionality
                                    // This would typically send a password reset email
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Password reset functionality will be implemented here'),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(color: primaryColor),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _signIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text(
                                    'Log In / Sign Up',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Info Text
                              Text(
                                'Only @mgapparel.com email addresses are allowed',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
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





class DepartmentSelectionScreen extends StatefulWidget {
  const DepartmentSelectionScreen({Key? key}) : super(key: key);

  @override
  _DepartmentSelectionScreenState createState() => _DepartmentSelectionScreenState();
}

class _DepartmentSelectionScreenState extends State<DepartmentSelectionScreen> {
  // Color theme
  final Color primaryColor = const Color(0xFF2AABE2);

  // Department data - in a real app, you might fetch this from Supabase
  final List<Map<String, dynamic>> departments = [
    {'id': 'hr', 'name': 'Human Resources', 'icon': Icons.people},
    {'id': 'prod', 'name': 'Production', 'icon': Icons.precision_manufacturing},
    {'id': 'sales', 'name': 'Sales', 'icon': Icons.attach_money},
    {'id': 'mgmt', 'name': 'Management', 'icon': Icons.business},
    {'id': 'design', 'name': 'Design', 'icon': Icons.brush},
    {'id': 'qc', 'name': 'Quality Control', 'icon': Icons.check_circle},
    {'id': 'it', 'name': 'IT', 'icon': Icons.computer},
    {'id': 'logistics', 'name': 'Logistics', 'icon': Icons.local_shipping},
  ];

  String? _selectedDepartmentId;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _saveDepartmentAndProceed() async {
    if (_selectedDepartmentId == null) {
      setState(() {
        _errorMessage = 'Please select a department to continue';
      });
      return;
    }

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
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      // Save department to user profile in Supabase
      await Supabase.instance.client.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'department_id': _selectedDepartmentId,
        'updated_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _isLoading = false;
      });

      // Navigate to dashboard
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const UserDashboard()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save department: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Department'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive design based on screen width
          final isSmallScreen = constraints.maxWidth < 600;
          final isMediumScreen = constraints.maxWidth < 900 && constraints.maxWidth >= 600;

          // Calculate the number of columns based on screen width
          int crossAxisCount = isSmallScreen ? 2 : (isMediumScreen ? 3 : 4);

          return Container(
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header section
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'Welcome! Please select your department to continue.',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 24,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Departments grid
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: departments.length,
                        itemBuilder: (context, index) {
                          final department = departments[index];
                          final isSelected = department['id'] == _selectedDepartmentId;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDepartmentId = department['id'];
                                _errorMessage = null;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(
                                  color: isSelected ? primaryColor.withOpacity(0.8) : Colors.grey.withOpacity(0.1),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    department['icon'],
                                    size: 48,
                                    color: isSelected ? Colors.white : primaryColor,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    department['name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : Colors.grey[800],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (isSelected)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Error message
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Continue button
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveDepartmentAndProceed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

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
  String _userDepartment = '';
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

      // Check if user has submitted mood today
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final moodSubmission = await Supabase.instance.client
          .from('mood_submissions')
          .select('id')
          .eq('user_id', user.id)
          .gte('created_at', '$today 00:00:00')
          .lt('created_at', '$today 23:59:59')
          .maybeSingle();

      setState(() {
        _userName = userData['name'] ?? user.email?.split('@')[0] ?? 'User';
        _userDepartment = userData['department_id'] ?? 'Unknown';
        _hasSubmittedToday = moodSubmission != null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: ${e.toString()}';
        _isLoading = false;
      });
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

    // Special handling for angry mood - navigate to comment screen
    if (moodId == 'angry') {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CommentScreen(
            moodId: moodId,
            onSubmitComplete: () {
              setState(() {
                _hasSubmittedToday = true;
              });
            },
          ),
        ),
      );
      return;
    }

    // For other moods, submit directly
    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Submit mood to Supabase
      await Supabase.instance.client.from('mood_submissions').insert({
        'user_id': user.id,
        'mood': moodId,
        'department_id': _userDepartment,
        'created_at': DateTime.now().toIso8601String(),
      });

      Navigator.push(context, MaterialPageRoute(builder: (context)=>SubmissionConfirmationScreen(moodType: moodId)));
      setState(() {
        _isLoading = false;
        _hasSubmittedToday = true;
      });

      // Navigate to confirmation screen
      if (!mounted) return;


    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit mood: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
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
                        'Department: $_userDepartment',
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



class CommentScreen extends StatefulWidget {
  final String moodId;
  final Function onSubmitComplete;

  const CommentScreen({
    Key? key,
    required this.moodId,
    required this.onSubmitComplete,
  }) : super(key: key);

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  // Color theme
  final Color primaryColor = const Color(0xFF2AABE2);
  final Color angryColor = const Color(0xFFF44336);

  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String _userDepartment = '';
  final int _maxCommentLength = 500;

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

      setState(() {
        _userDepartment = userData['department_id'] ?? 'Unknown';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load user data: ${e.toString()}';
      });
    }
  }

  Future<void> _submitFeedback() async {
    // Basic validation
    if (_commentController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please provide some feedback before submitting';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Submit mood and comment to Supabase
      await Supabase.instance.client.from('mood_submissions').insert({
        'user_id': user.id,
        'mood': widget.moodId,
        'comment': _commentController.text.trim(),
        'department_id': _userDepartment,
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _isLoading = false;
      });

      // Call the callback to update the parent screen
      widget.onSubmitComplete();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> SubmissionConfirmationScreen(moodType: widget.moodId)));

      // Navigate to confirmation screen
      if (!mounted) return;

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit feedback: ${e.toString()}';
        _isLoading = false;
      });
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
        onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard on tap
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
                  // Header section with emoji and title
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

                  // Comment text field
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
                                  // Force refresh to update character counter color
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Error message
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

                  // Encouragement message
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

                  // Submit button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitFeedback,
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

                  // Cancel button
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
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


class SubmissionConfirmationScreen extends StatelessWidget {
  final String moodType;

  const SubmissionConfirmationScreen({
    Key? key,
    required this.moodType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animation
                SizedBox(
                  height: 180,
                  child: Lottie.asset(
                    'assets/animations/success_check.json',
                    repeat: false,
                  ),
                ),
                const SizedBox(height: 32),

                // Thank you message
                Text(
                  'Thank You!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2AABE2),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirmation message
                Text(
                  'Your ${moodType.toLowerCase()} mood has been recorded successfully.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),

                // Motivational quote
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _getRandomQuote(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Back to dashboard button
                ElevatedButton(
                  onPressed:(){ Navigator.pop(context);},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2AABE2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Back to Dashboard',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRandomQuote() {
    final quotes = [
      "Your feedback helps us create a better workplace for everyone.",
      "Thank you for sharing how you feel today. Your input matters.",
      "Small moments of honesty create big changes over time.",
      "Your voice matters. Together we can create positive change.",
      "Your wellbeing is important to us. Thank you for participating.",
      "Every voice counts in building our company culture.",
      "Thank you for your contribution to making our workplace better.",
    ];

    return quotes[Random().nextInt(quotes.length)];
  }
}""*/