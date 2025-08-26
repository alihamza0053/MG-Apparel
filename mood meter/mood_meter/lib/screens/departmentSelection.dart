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

  // Department data - updated with all departments from the provided list
  final List<Map<String, dynamic>> departments = [
    {'id': 'hr', 'name': 'Human Resource', 'icon': Icons.people},
    {'id': 'pdsw', 'name': 'PD Sampling and Washing', 'icon': Icons.wash},
    {'id': 'mm', 'name': 'Marketing and Merchandizing', 'icon': Icons.campaign},
    {'id': 'rnd', 'name': 'R and D', 'icon': Icons.science},
    {'id': 'ba', 'name': 'Business Affairs', 'icon': Icons.business_center},
    {'id': 'raiment61', 'name': 'Raiment-61', 'icon': Icons.store},
    {'id': 'accounts', 'name': 'Accounts', 'icon': Icons.account_balance},
    {'id': 'stores', 'name': 'Stores', 'icon': Icons.inventory},
    {'id': 'mmc', 'name': 'MMC', 'icon': Icons.factory},
    {'id': 'fs', 'name': 'Fabric Sourcing', 'icon': Icons.newspaper},
    {'id': 'sc', 'name': 'Supply Chain', 'icon': Icons.sync_alt},
    {'id': 'admin', 'name': 'Admin', 'icon': Icons.admin_panel_settings},
    {'id': 'cutting', 'name': 'Cutting/GGT CAD', 'icon': Icons.cut},
    {'id': 'stitching', 'name': 'Stitching', 'icon': Icons.handyman},
    {'id': 'eu', 'name': 'Engineering and Utilities', 'icon': Icons.engineering},
    {'id': 'iepi', 'name': 'IE and Process Improvement', 'icon': Icons.trending_up},
    {'id': 'finishing', 'name': 'Finishing', 'icon': Icons.brush},
    {'id': 'maintenance', 'name': 'Maintenance', 'icon': Icons.build},
    {'id': 'dsba', 'name': 'DSBA', 'icon': Icons.auto_graph},
    {'id': 'audit', 'name': 'Audit', 'icon': Icons.fact_check},
    {'id': 'itns', 'name': 'IT and Network Support', 'icon': Icons.computer},
    {'id': 'wip', 'name': 'WIP', 'icon': Icons.work},
    {'id': 'qc', 'name': 'Quality Control', 'icon': Icons.check_circle},
    {'id': 'qa', 'name': 'Quality Assurance', 'icon': Icons.assured_workload},
    {'id': 'ppc', 'name': 'PPC', 'icon': Icons.schedule},
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
        title: const Text(
          'Select Your Department',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive design based on screen width
          final isSmallScreen = constraints.maxWidth < 600;
          final isMediumScreen = constraints.maxWidth < 900 && constraints.maxWidth >= 600;
          final isLargeScreen = constraints.maxWidth >= 1200;

          // Calculate the number of columns based on screen width
          int crossAxisCount;
          if (isSmallScreen) {
            crossAxisCount = 2; // Mobile: 2 columns
          } else if (isMediumScreen) {
            crossAxisCount = 3; // Tablet: 3 columns
          } else if (isLargeScreen) {
            crossAxisCount = 6; // Large desktop: 6 columns
          } else {
            crossAxisCount = 4; // Regular desktop: 4 columns
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withOpacity(0.05),
                  Colors.grey[50]!,
                  Colors.white,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16.0 : 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header section
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      margin: const EdgeInsets.only(bottom: 24.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.domain,
                            size: 48,
                            color: primaryColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Welcome!',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 22 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please select your department to continue',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Departments grid
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.9, // Better aspect ratio for more height
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
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? primaryColor.withOpacity(0.3)
                                        : Colors.grey.withOpacity(0.15),
                                    spreadRadius: isSelected ? 3 : 1,
                                    blurRadius: isSelected ? 15 : 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor.withOpacity(0.8)
                                      : Colors.grey.withOpacity(0.1),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Icon container
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.2)
                                            : primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        department['icon'],
                                        size: isSmallScreen ? 32 : 36,
                                        color: isSelected ? Colors.white : primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Department name
                                    Flexible(
                                      child: Text(
                                        department['name'],
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 13 : 14,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? Colors.white : Colors.grey[800],
                                          height: 1.2,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    // Selected indicator
                                    if (isSelected)
                                      Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Selected',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Error message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red[600],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Continue button
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveDepartmentAndProceed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          disabledBackgroundColor: Colors.grey[400],
                        ),
                        child: _isLoading
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              'Please wait...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              size: 20,
                            ),
                          ],
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