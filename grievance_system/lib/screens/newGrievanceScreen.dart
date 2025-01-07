import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart'; // For picking files on Android/iOS
import 'package:shared_preferences/shared_preferences.dart';

class NewGrievanceScreen extends StatefulWidget {
  @override
  _NewGrievanceScreenState createState() => _NewGrievanceScreenState();
}

class _NewGrievanceScreenState extends State<NewGrievanceScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String userEmail = "";
  File? selectedFile; // For Android/iOS
  Uint8List? webSelectedFile; // For Web
  String? fileName;

  @override
  void initState() {
    _loadUserEmail();
    super.initState();
  }

  // Load the user email from SharedPreferences
  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail') ?? '';
    });
  }

  // Pick file for Web
  Future<void> _pickFileWeb() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        webSelectedFile = result.files.first.bytes;
        fileName = result.files.first.name;
      });
    }
  }

  // Pick file for Android/iOS
  Future<void> _pickFileMobile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final pickedFile = File(file.path);
      if (pickedFile.lengthSync() <= 10 * 1024 * 1024) { // Check file size
        setState(() {
          selectedFile = pickedFile;
          fileName = file.name;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File size must be under 10 MB')),
        );
      }
    }
  }

  // Cross-platform file picker
  Future<void> _pickFile() async {
    if (kIsWeb) {
      await _pickFileWeb();
    } else {
      await _pickFileMobile();
    }
  }

  Future<void> _submitGrievance() async {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Title and description are required')),
      );
      return;
    }

    if (kIsWeb && webSelectedFile != null && webSelectedFile!.length > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File size must be under 10 MB')),
      );
      return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://gms.alihamza.me/gms/submit_grievance.php"),
      );

      request.fields['title'] = _titleController.text.trim();
      request.fields['description'] = _descriptionController.text.trim();
      request.fields['status'] = 'Pending';
      request.fields['submittedBy'] = userEmail;
      request.fields['assignedTo'] = "Not Assigned";

      // Print request fields for debugging
      print("Request Fields: ${request.fields}");

      if (kIsWeb && webSelectedFile != null) {
        // Web file handling
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          webSelectedFile!,
          filename: fileName,
        ));
      } else if (selectedFile != null) {
        // Mobile file handling
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          selectedFile!.path,
        ));
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = json.decode(await response.stream.bytesToString());
        if (responseData['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Grievance submitted successfully')),
          );
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${responseData['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
            ElevatedButton.icon(
              icon: Icon(Icons.attach_file),
              label: Text(fileName == null
                  ? 'Attach File'
                  : 'File Selected: $fileName'),
              onPressed: _pickFile,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitGrievance,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
