import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grievance Management System',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => FirebaseAuth.instance.currentUser == null ? LoginPage() : DashboardScreen()),
      );
    });

    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: Text('Login')),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegistrationPage())),
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}


class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _departmentController = TextEditingController();
  String _selectedRole = 'Employee'; // Default role

  // This function is for registration
  Future<void> _register() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': _emailController.text.trim(),
        'department': _departmentController.text.trim(),
        'role': _selectedRole, // Save selected role
        'userId': userCredential.user!.uid,
      });

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _departmentController,
              decoration: InputDecoration(labelText: 'Department'),
            ),
            // Role Radio Buttons
            Column(
              children: [
                Row(
                  children: [
                    Radio<String>(
                      value: 'Admin',
                      groupValue: _selectedRole,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                    Text('Admin'),
                    Radio<String>(
                      value: 'HR',
                      groupValue: _selectedRole,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                    Text('HR'),
                    Radio<String>(
                      value: 'Employee',
                      groupValue: _selectedRole,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                    Text('Employee'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _register, child: Text('Register')),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Check if the current user is admin
    bool isAdmin = currentUser?.email == 'alihamza00053@gmail.com';

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NotificationScreen()),
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: isAdmin
          ? AdminGrievanceList() // Admin-specific grievance list
          : UserGrievanceList(currentUser: currentUser), // User-specific grievance list
      floatingActionButton: isAdmin
          ? null
          : FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NewGrievanceScreen()),
        ),
        child: Icon(Icons.add),
      ),
    );
  }
}

class AdminGrievanceList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('grievances').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var grievances = snapshot.data!.docs;

        return ListView.builder(
          itemCount: grievances.length,
          itemBuilder: (context, index) {
            var grievance = grievances[index];
            return Card(
              child: ListTile(
                title: Text(grievance['title']),
                subtitle: Text(
                  'Status: ${grievance['status']}\nSubmitted By: ${grievance['submittedBy']}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Instead of dropdown, display the 'Assigned To' field as text
                    Text(
                      'Assigned To: ${grievance['assignedTo'] ?? 'Not Assigned'}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GrievanceDetailsScreen(grievanceId: grievance.id),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class UserGrievanceList extends StatelessWidget {
  final User? currentUser;

  const UserGrievanceList({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('grievances')
          .where('submittedBy', isEqualTo: currentUser?.email)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot1) {
        if (!snapshot1.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var grievancesByUser = snapshot1.data!.docs;

        return StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('grievances')
              .where('assignedTo', isEqualTo: currentUser?.email)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot2) {
            if (!snapshot2.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            var grievancesAssignedToUser = snapshot2.data!.docs;

            var allGrievances = [...grievancesByUser, ...grievancesAssignedToUser];

            return ListView.builder(
              itemCount: allGrievances.length,
              itemBuilder: (context, index) {
                var grievance = allGrievances[index];
                return Card(
                  child: ListTile(
                    title: Text(grievance['title']),
                    subtitle: Text('Status: ${grievance['status']}'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GrievanceDetailsScreen(grievanceId: grievance.id),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}



class GrievanceDetailsScreen extends StatefulWidget {
  final String grievanceId;

  GrievanceDetailsScreen({required this.grievanceId});

  @override
  _GrievanceDetailsScreenState createState() => _GrievanceDetailsScreenState();
}

class _GrievanceDetailsScreenState extends State<GrievanceDetailsScreen> {
  DocumentSnapshot? grievanceData;
  String? selectedStatus;
  String? selectedAssignee; // Added for 'Assigned To'
  bool isAdmin = false; // To check if the user is admin
  bool isAssigned = false; // To check if the current user is assigned
  List<String> usersList = []; // List to store users for dropdown

  @override
  void initState() {
    super.initState();
    _fetchGrievance();
    _fetchUsers(); // Fetch users list
  }

  // Fetch grievance data
  Future<void> _fetchGrievance() async {
    try {
      var grievanceDoc = await FirebaseFirestore.instance
          .collection('grievances')
          .doc(widget.grievanceId)
          .get();

      if (grievanceDoc.exists) {
        setState(() {
          grievanceData = grievanceDoc;
          selectedStatus = grievanceData!['status'];
          selectedAssignee = grievanceData!['assignedTo'] ?? null; // Set default assignee value from Firestore
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grievance not found.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading grievance details: $e')));
  }
  }

  // Fetch users for the 'Assigned To' dropdown
  Future<void> _fetchUsers() async {
    try {
      var usersSnapshot = await FirebaseFirestore.instance
          .collection('users') // Assuming you have a 'users' collection
          .get();

      setState(() {
        usersList = usersSnapshot.docs.map((doc) => doc['email'] as String).toList();
        // Set the selected assignee to the first user in the list if it is empty
        if (selectedAssignee == null && usersList.isNotEmpty) {
          selectedAssignee = usersList[0]; // Default to the first user if no assignee
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')));
  }
    _checkUserRole();
  }

  // Check if the current user is admin or assigned to the grievance
  Future<void> _checkUserRole() async {
    final currentUser = await FirebaseAuth.instance.currentUser;
    setState(() {
      isAdmin = currentUser?.email == 'alihamza00053@gmail.com';
      isAssigned = grievanceData?['assignedTo']?.trim() == currentUser?.email?.trim(); // Compare after trimming
    });
  }

  // Update status in Firestore
  Future<void> _updateStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('grievances').doc(widget.grievanceId).update({
        'status': newStatus,
        if (newStatus == 'Resolved' || newStatus == 'Closed')
          'resolvedDate': Timestamp.now(),
        'lastUpdatedDate': Timestamp.now(),
      });
      setState(() {
        selectedStatus = newStatus; // Update status locally after successful update
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    }
  }

  // Update assigned person in Firestore
  Future<void> _updateAssignedTo(String? newAssignee) async {
    try {
      if (newAssignee != null) {
        await FirebaseFirestore.instance.collection('grievances').doc(widget.grievanceId).update({
          'assignedTo': newAssignee,
          'lastUpdatedDate': Timestamp.now(),
        });
        setState(() {
          selectedAssignee = newAssignee; // Update assignee locally after successful update
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating assigned person: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Grievance Details')),
      body: grievanceData == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title: ${grievanceData!['title']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Description: ${grievanceData!['description']}'),
            SizedBox(height: 10),
            Text('Status: ${grievanceData!['status']}'),
            SizedBox(height: 10),
            Text('Submission Date: ${grievanceData!['submissionDate'].toDate()}'),
            SizedBox(height: 10),
            Text('Assigned To: ${grievanceData!['assignedTo'] ?? 'Not assigned yet'}'),
            SizedBox(height: 10),
            Text('Last Updated: ${grievanceData!['lastUpdatedDate'].toDate()}'),
            SizedBox(height: 20),
            // Add the Status dropdown
            if (isAdmin || isAssigned)
              Row(
                children: [
                  Text(
                    'Status: ',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(width: 10),
                  // Status dropdown
                  DropdownButton<String>(
                    value: selectedStatus,
                    items: ['Pending', 'In Progress', 'Resolved', 'Closed']
                        .map((status) => DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    ))
                        .toList(),
                    onChanged: (newStatus) {
                      if (newStatus != null) {
                        _updateStatus(newStatus);
                      }
                    },
                  ),
                ],
              ),
            SizedBox(height: 20),
            // Show the 'Assigned To' dropdown only if the current user is admin or not assigned yet
            if (isAdmin)
              Row(
                children: [
                  Text(
                    'Assign To: ',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(width: 10),
                  // Assigned To dropdown
                  DropdownButton<String>(
                    value: selectedAssignee,
                    items: usersList
                        .map((email) => DropdownMenuItem<String>(
                      value: email,
                      child: Text(email),
                    ))
                        .toList(),
                    onChanged: (newAssignee) {
                      if (newAssignee != null) {
                        _updateAssignedTo(newAssignee);
                      }
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: currentUser?.uid)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notification = notifications[index];
              return ListTile(
                title: Text(notification['message']),
                subtitle: Text(notification['timestamp'].toDate().toString()),
              );
            },
          );
        },
      ),
    );
  }
}

class NewGrievanceScreen extends StatefulWidget {
  @override
  _NewGrievanceScreenState createState() => _NewGrievanceScreenState();
}

class _NewGrievanceScreenState extends State<NewGrievanceScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Future<void> _submitGrievance() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance.collection('grievances').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': 'Pending',
        'submissionDate': Timestamp.now(),
        'userId': currentUser.uid,
        'submittedBy': currentUser.email, // Add this field
        'assignedTo': null, // Initially, no one is assigned to the grievance
        'lastUpdatedDate': Timestamp.now(), // Add Last Updated field
      });


      await FirebaseFirestore.instance.collection('notifications').add({
        'message': 'New grievance submitted: ${_titleController.text.trim()}',
        'timestamp': Timestamp.now(),
        'userId': currentUser.uid,
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Grievance')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _submitGrievance, child: Text('Submit')),
          ],
        ),
      ),
    );
  }
}
