import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';

class NewGrievanceScreen extends StatefulWidget {
  @override
  _NewGrievanceScreenState createState() => _NewGrievanceScreenState();
}

class _NewGrievanceScreenState extends State<NewGrievanceScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _othersController = TextEditingController();

  String? selectedCategory;
  String userEmail = "";
  File? selectedFile; // For Android/iOS
  Uint8List? webSelectedFile; // For Web
  String? fileName;
  bool othersField = false;

  @override
  void initState() {
    _loadUserEmail();
    super.initState();
  }

  Future<void> _loadUserEmail() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email!;
      });
    }
  }

  Future<void> _pickFileWeb() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        webSelectedFile = result.files.first.bytes;
        fileName = result.files.first.name;
      });
    }
  }

  Future<void> _pickFileMobile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        selectedFile = File(file.path);
        fileName = file.name;
      });
    }
  }

  Future<void> _pickFile() async {
    if (kIsWeb) {
      await _pickFileWeb();
    } else {
      await _pickFileMobile();
    }
  }

  Future<String?> _uploadFile() async {
    if (fileName == null) return null;

    final filePath = 'grievances/$userEmail/$fileName';
    final storage = Supabase.instance.client.storage;

    if (kIsWeb && webSelectedFile != null) {
      await storage.from('uploads').uploadBinary(filePath, webSelectedFile!);
    } else if (selectedFile != null) {
      await storage.from('uploads').upload(filePath, selectedFile!);
    }

    return storage.from('uploads').getPublicUrl(filePath);
  }

  Future<void> _submitGrievance() async {
    if (_titleController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Title and description are required')),
      );
      return;
    }
    //String? fileUrl = await _uploadFile();


    final grievanceData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'status': 'Pending',
      'submitted_by': userEmail,
      'assigned_to': 'Not Assigned',
      'category': selectedCategory ?? '',
      'file_url': 'fileUrl',

    };

    try{
      final response = await Supabase.instance.client.from('grievances').insert(grievanceData);

      if (response.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grievance submitted successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.error!.message}')),
        );
      }
    }catch(e){
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
              decoration: InputDecoration(labelText: 'Title*'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description*'),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            othersField ?
            TextField(
              controller: _othersController,
              decoration: InputDecoration(labelText: 'Other Category*'),
            ) : SizedBox(),
            SizedBox(height: 20),
            DropdownButton<String>(
              value: selectedCategory,
              hint: Text("Select Category"),
              items: ['Discrimination', 'Pay and Benefits', 'Work Conditions', 'Workplace Harassment', 'Others']
                  .map((status) => DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              )).toList(),
              onChanged: (newCategory) {
                if (newCategory != null) {
                  setState(() {
                    selectedCategory = newCategory;
                    othersField = newCategory == 'Others';
                  });
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.attach_file),
              label: Text(fileName == null ? 'Attach File' : 'File Selected: $fileName'),
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