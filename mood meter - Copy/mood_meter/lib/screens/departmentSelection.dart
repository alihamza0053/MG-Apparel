import 'package:flutter/material.dart';
import 'package:mood_meter/screens/userDashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


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
    {'id': 'dsba', 'name': 'DSBA', 'icon': Icons.auto_graph},
    {'id': 'prod', 'name': 'Production', 'icon': Icons.precision_manufacturing},
    {'id': 'supply', 'name': 'Supply Chain', 'icon': Icons.sync_alt},
    {'id': 'qc', 'name': 'Quality Control', 'icon': Icons.check_circle},
    {'id': 'it', 'name': 'IT & ERP', 'icon': Icons.computer},
    {'id': 'audit', 'name': 'Audit', 'icon': Icons.fact_check},
    {'id': 'admin', 'name': 'Admin', 'icon': Icons.admin_panel_settings},
    {'id': 'logistics', 'name': 'Logistics', 'icon': Icons.local_shipping},
    {'id': 'marketing', 'name': 'Marketing', 'icon': Icons.campaign},
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
        centerTitle: true,
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
