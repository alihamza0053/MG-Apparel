import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> sendEmail(String email, String subject, String message) async {
  final url = Uri.parse("https://gms.mgapparel.com/send_email.php");

  try {
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode({
        "email": email,
        "subject": subject,
        "message": message,
      }),
    );


    if (response.statusCode == 200) {
      print("✅ Email sent successfully: ${response.body}");
    } else {
      print("❌ Failed: ${response.statusCode} - ${response.body}");
    }
  } catch (e) {
    print("❌ Error: $e");
  }
}
