import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';


Future<String?> uploadFile(File file) async {
  try {
    var uri = Uri.parse("https://groundup.pk/gms//upload_image.php"); // Replace with your actual API URL
    var request = http.MultipartRequest("POST", uri);

    // Get MIME type (e.g., image/png, application/pdf)
    String? mimeType = lookupMimeType(file.path);
    var multipartFile = await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: mimeType != null ? MediaType.parse(mimeType) : null,
    );

    request.files.add(multipartFile);
    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData); // Now jsonDecode will work

      if (jsonResponse['success']) {
        return jsonResponse['file_path']; // Return uploaded file path
      } else {
        print("Upload failed: ${jsonResponse['message']}");
        return null;
      }
    } else {
      print("Server error: ${response.reasonPhrase}");
      return null;
    }
  } catch (e) {
    print("Error uploading file: $e");
    return null;
  }
}

Future<void> pickAndUploadFile() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    File file = File(pickedFile.path);
    String? filePath = await uploadFile(file);

    if (filePath != null) {
      print("File uploaded successfully: $filePath");
    } else {
      print("File upload failed.");
    }
  } else {
    print("No file selected.");
  }
}
